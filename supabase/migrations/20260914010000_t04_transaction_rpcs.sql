-- T04: transactional writes with idempotency and optimistic concurrency.

create table public.transactions (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  kind text not null check (kind in ('income', 'expense')),
  occurred_on date not null,
  amount_won bigint not null check (amount_won > 0),
  merchant text not null check (char_length(btrim(merchant)) between 1 and 200),
  category text check (category is null or char_length(btrim(category)) <= 100),
  payment_method_id uuid,
  member_id uuid,
  memo text check (memo is null or char_length(memo) <= 500),
  created_by uuid not null references auth.users(id),
  updated_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  version integer not null default 1 check (version > 0),
  voided_at timestamptz,
  unique (id, household_id),
  foreign key (payment_method_id, household_id)
    references public.payment_methods (id, household_id),
  foreign key (member_id, household_id)
    references public.household_members (id, household_id)
);

create index transactions_household_date
  on public.transactions (household_id, occurred_on desc, created_at desc, id desc);

create table public.write_requests (
  household_id uuid not null references public.households(id) on delete cascade,
  actor_id uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  operation text not null check (operation in ('save_transactions', 'edit_transaction', 'void_transaction')),
  payload_hash bytea not null,
  result_transaction_ids uuid[] not null default '{}',
  created_at timestamptz not null default now(),
  primary key (household_id, actor_id, request_id)
);

alter table public.transactions enable row level security;
alter table public.write_requests enable row level security;

create policy transactions_select_member on public.transactions
  for select to authenticated
  using (public.is_active_household_member(household_id) and voided_at is null);

revoke all on public.transactions, public.write_requests from anon, authenticated;
grant select on public.transactions to authenticated;

create or replace function public._transaction_payload_hash(
  p_operation text,
  p_payload jsonb
)
returns bytea
language sql
immutable
set search_path = public
as $$
  select digest(convert_to(p_operation || ':' || p_payload::text, 'UTF8'), 'sha256');
$$;

create or replace function public._validate_transaction_input(
  p_kind text,
  p_occurred_on text,
  p_amount text,
  p_merchant text,
  p_category text,
  p_memo text
)
returns void
language plpgsql
immutable
set search_path = public
as $$
declare
  v_date date;
  v_amount bigint;
begin
  if p_kind not in ('income', 'expense') then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'kind';
  end if;
  if p_occurred_on is null or p_occurred_on !~ '^\d{4}-\d{2}-\d{2}$' then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'occurred_on';
  end if;
  begin
    v_date := p_occurred_on::date;
  exception when others then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'occurred_on';
  end;
  if extract(year from v_date) not between 2000 and 2100 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'occurred_on';
  end if;
  if p_amount is null or p_amount !~ '^[0-9]+$' then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'amount_won';
  end if;
  begin
    v_amount := p_amount::bigint;
  exception when others then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'amount_won';
  end;
  if v_amount <= 0 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'amount_won';
  end if;
  if p_merchant is null or char_length(btrim(p_merchant)) not between 1 and 200 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'merchant';
  end if;
  if p_category is not null and char_length(btrim(p_category)) > 100 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'category';
  end if;
  if p_memo is not null and char_length(p_memo) > 500 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'memo';
  end if;
end;
$$;

create or replace function public._validate_transaction_refs(
  p_household_id uuid,
  p_kind text,
  p_payment_method_id uuid,
  p_member_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_payment_kind text;
begin
  if p_member_id is not null and not exists (
    select 1 from public.household_members
    where id = p_member_id and household_id = p_household_id and left_at is null
  ) then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'member_id';
  end if;
  if p_payment_method_id is not null then
    select kind into v_payment_kind
    from public.payment_methods
    where id = p_payment_method_id
      and household_id = p_household_id
      and archived_at is null;
    if not found or v_payment_kind = 'voucher' then
      raise exception using errcode = '22023', message = 'validation_failed', detail = 'payment_method_id';
    end if;
    if p_kind = 'income' and v_payment_kind not in ('cash', 'bank') then
      raise exception using errcode = '22023', message = 'validation_failed', detail = 'payment_method_id';
    end if;
  end if;
end;
$$;

create or replace function public.save_transactions(
  p_household_id uuid,
  p_request_id uuid,
  p_entries jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_hash bytea;
  v_existing public.write_requests%rowtype;
  v_ids uuid[] := '{}';
  v_entry jsonb;
  v_kind text;
  v_payment_method uuid;
  v_member uuid;
  v_id uuid;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  perform 1 from public.households where id = p_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if p_request_id is null or p_entries is null or jsonb_typeof(p_entries) <> 'array'
     or jsonb_array_length(p_entries) not between 1 and 50 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'entries';
  end if;

  v_hash := public._transaction_payload_hash('save_transactions', p_entries);
  insert into public.write_requests (household_id, actor_id, request_id, operation, payload_hash)
  values (p_household_id, v_actor, p_request_id, 'save_transactions', v_hash)
  on conflict (household_id, actor_id, request_id) do nothing;
  select * into v_existing from public.write_requests
  where household_id = p_household_id and actor_id = v_actor and request_id = p_request_id
  for update;
  if v_existing.payload_hash <> v_hash then
    raise exception using errcode = 'P0001', message = 'idempotency_conflict';
  end if;
  if cardinality(v_existing.result_transaction_ids) > 0 then
    return jsonb_build_object('transaction_ids', to_jsonb(v_existing.result_transaction_ids));
  end if;

  for v_entry in select value from jsonb_array_elements(p_entries)
  loop
    v_kind := v_entry->>'kind';
    perform public._validate_transaction_input(
      v_kind, v_entry->>'occurred_on', v_entry->>'amount_won',
      v_entry->>'merchant', v_entry->>'category', v_entry->>'memo'
    );
    if (v_entry ? 'payment_method_id')
       and nullif(v_entry->>'payment_method_id', '') is not null
       and (v_entry->>'payment_method_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
      raise exception using errcode = '22023', message = 'validation_failed', detail = 'payment_method_id';
    end if;
    if (v_entry ? 'member_id')
       and nullif(v_entry->>'member_id', '') is not null
       and (v_entry->>'member_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
      raise exception using errcode = '22023', message = 'validation_failed', detail = 'member_id';
    end if;
    v_payment_method := nullif(v_entry->>'payment_method_id', '')::uuid;
    v_member := nullif(v_entry->>'member_id', '')::uuid;
    perform public._validate_transaction_refs(p_household_id, v_kind, v_payment_method, v_member);
    insert into public.transactions (
      household_id, kind, occurred_on, amount_won, merchant, category,
      payment_method_id, member_id, memo, created_by, updated_by
    ) values (
      p_household_id, v_kind, (v_entry->>'occurred_on')::date,
      (v_entry->>'amount_won')::bigint, btrim(v_entry->>'merchant'),
      nullif(btrim(v_entry->>'category'), ''), v_payment_method, v_member,
      v_entry->>'memo', v_actor, v_actor
    ) returning id into v_id;
    v_ids := array_append(v_ids, v_id);
  end loop;

  update public.write_requests
  set result_transaction_ids = v_ids
  where household_id = p_household_id and actor_id = v_actor and request_id = p_request_id;
  return jsonb_build_object('transaction_ids', to_jsonb(v_ids));
end;
$$;

create or replace function public.edit_transaction(
  p_id uuid,
  p_expected_version integer,
  p_request_id uuid,
  p_values jsonb
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.transactions%rowtype;
  v_hash bytea;
  v_existing public.write_requests%rowtype;
  v_kind text;
  v_date text;
  v_amount text;
  v_merchant text;
  v_category text;
  v_memo text;
  v_payment uuid;
  v_member uuid;
  v_household_id uuid;
begin
  if p_request_id is null or p_values is null or jsonb_typeof(p_values) <> 'object' then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'request';
  end if;
  select household_id into v_household_id from public.transactions where id = p_id;
  if not found or v_actor is null or not public.is_active_household_member(v_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  perform 1 from public.households where id = v_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  select * into v_row from public.transactions where id = p_id for update;
  v_hash := public._transaction_payload_hash(
    'edit_transaction', jsonb_build_object('id', p_id, 'version', p_expected_version, 'values', p_values)
  );
  insert into public.write_requests (household_id, actor_id, request_id, operation, payload_hash)
  values (v_row.household_id, v_actor, p_request_id, 'edit_transaction', v_hash)
  on conflict (household_id, actor_id, request_id) do nothing;
  select * into v_existing from public.write_requests
  where household_id = v_row.household_id and actor_id = v_actor and request_id = p_request_id for update;
  if v_existing.payload_hash <> v_hash then
    raise exception using errcode = 'P0001', message = 'idempotency_conflict';
  end if;
  if cardinality(v_existing.result_transaction_ids) > 0 then
    return v_existing.result_transaction_ids[1];
  end if;
  if v_row.voided_at is not null or v_row.version <> p_expected_version then
    raise exception using errcode = 'P0001', message = 'version_conflict';
  end if;

  v_kind := coalesce(p_values->>'kind', v_row.kind);
  v_date := coalesce(p_values->>'occurred_on', v_row.occurred_on::text);
  v_amount := coalesce(p_values->>'amount_won', v_row.amount_won::text);
  v_merchant := coalesce(p_values->>'merchant', v_row.merchant);
  v_category := case when p_values ? 'category' then p_values->>'category' else v_row.category end;
  v_memo := case when p_values ? 'memo' then p_values->>'memo' else v_row.memo end;
  if (p_values ? 'payment_method_id')
     and nullif(p_values->>'payment_method_id', '') is not null
     and (p_values->>'payment_method_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'payment_method_id';
  end if;
  if (p_values ? 'member_id')
     and nullif(p_values->>'member_id', '') is not null
     and (p_values->>'member_id') !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$' then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'member_id';
  end if;
  v_payment := case when p_values ? 'payment_method_id' then nullif(p_values->>'payment_method_id', '')::uuid else v_row.payment_method_id end;
  v_member := case when p_values ? 'member_id' then nullif(p_values->>'member_id', '')::uuid else v_row.member_id end;
  perform public._validate_transaction_input(v_kind, v_date, v_amount, v_merchant, v_category, v_memo);
  perform public._validate_transaction_refs(v_row.household_id, v_kind, v_payment, v_member);
  update public.transactions set
    kind = v_kind, occurred_on = v_date::date, amount_won = v_amount::bigint,
    merchant = btrim(v_merchant), category = nullif(btrim(v_category), ''),
    payment_method_id = v_payment, member_id = v_member, memo = v_memo,
    updated_by = v_actor, updated_at = now(), version = version + 1
  where id = p_id;
  update public.write_requests set result_transaction_ids = array[p_id]
  where household_id = v_row.household_id and actor_id = v_actor and request_id = p_request_id;
  return p_id;
end;
$$;

create or replace function public.void_transaction(
  p_id uuid,
  p_expected_version integer,
  p_request_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.transactions%rowtype;
  v_hash bytea;
  v_existing public.write_requests%rowtype;
  v_household_id uuid;
begin
  if p_request_id is null then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'request_id';
  end if;
  select household_id into v_household_id from public.transactions where id = p_id;
  if not found or v_actor is null or not public.is_active_household_member(v_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  perform 1 from public.households where id = v_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  select * into v_row from public.transactions where id = p_id for update;
  v_hash := public._transaction_payload_hash(
    'void_transaction', jsonb_build_object('id', p_id, 'version', p_expected_version)
  );
  insert into public.write_requests (household_id, actor_id, request_id, operation, payload_hash)
  values (v_row.household_id, v_actor, p_request_id, 'void_transaction', v_hash)
  on conflict (household_id, actor_id, request_id) do nothing;
  select * into v_existing from public.write_requests
  where household_id = v_row.household_id and actor_id = v_actor and request_id = p_request_id for update;
  if v_existing.payload_hash <> v_hash then
    raise exception using errcode = 'P0001', message = 'idempotency_conflict';
  end if;
  if cardinality(v_existing.result_transaction_ids) > 0 then
    return v_existing.result_transaction_ids[1];
  end if;
  if v_row.voided_at is not null or v_row.version <> p_expected_version then
    raise exception using errcode = 'P0001', message = 'version_conflict';
  end if;
  update public.transactions
  set voided_at = now(), updated_by = v_actor, updated_at = now(), version = version + 1
  where id = p_id;
  update public.write_requests set result_transaction_ids = array[p_id]
  where household_id = v_row.household_id and actor_id = v_actor and request_id = p_request_id;
  return p_id;
end;
$$;

revoke all on function public._transaction_payload_hash(text, jsonb) from public;
revoke all on function public._validate_transaction_input(text, text, text, text, text, text) from public;
revoke all on function public._validate_transaction_refs(uuid, text, uuid, uuid) from public;
revoke all on function public.save_transactions(uuid, uuid, jsonb) from public;
revoke all on function public.edit_transaction(uuid, integer, uuid, jsonb) from public;
revoke all on function public.void_transaction(uuid, integer, uuid) from public;
grant execute on function public.save_transactions(uuid, uuid, jsonb) to authenticated;
grant execute on function public.edit_transaction(uuid, integer, uuid, jsonb) to authenticated;
grant execute on function public.void_transaction(uuid, integer, uuid) to authenticated;
