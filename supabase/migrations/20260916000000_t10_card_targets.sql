-- T10: card registration, monthly targets, and performance inclusion.
alter table public.transactions
  add column performance_included boolean not null default true;

create table public.card_targets (
  household_id uuid not null references public.households(id) on delete cascade,
  payment_method_id uuid not null,
  target_month date not null,
  target_amount_won bigint not null check (target_amount_won > 0),
  created_by uuid not null references auth.users(id),
  updated_at timestamptz not null default now(),
  primary key (household_id, payment_method_id, target_month),
  foreign key (payment_method_id, household_id)
    references public.payment_methods (id, household_id)
);

alter table public.card_targets enable row level security;
revoke all on public.card_targets from anon, authenticated;
grant select on public.card_targets to authenticated;
create policy card_targets_select_member on public.card_targets
  for select to authenticated using (public.is_active_household_member(household_id));

create or replace function public.add_card_payment_method(
  p_household_id uuid,
  p_kind text,
  p_name text,
  p_owner_member_id uuid default null
)
returns uuid
language plpgsql security definer set search_path = public, auth
as $$
begin
  if p_kind not in ('debit_card', 'credit_card') then
    raise exception using errcode = '22023', message = 'card_kind_invalid';
  end if;
  return public.add_payment_method(p_household_id, p_kind, p_name, p_owner_member_id);
end;
$$;

create or replace function public.set_card_target(
  p_household_id uuid,
  p_payment_method_id uuid,
  p_target_month date,
  p_target_amount_won bigint
)
returns void
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_kind text;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if p_target_month is null or extract(day from p_target_month) <> 1 or p_target_amount_won <= 0 then
    raise exception using errcode = '22023', message = 'target_invalid';
  end if;
  select kind into v_kind from public.payment_methods
  where id = p_payment_method_id and household_id = p_household_id and archived_at is null;
  if v_kind not in ('debit_card', 'credit_card') then
    raise exception using errcode = '22023', message = 'card_invalid';
  end if;
  insert into public.card_targets (household_id, payment_method_id, target_month, target_amount_won, created_by)
  values (p_household_id, p_payment_method_id, p_target_month, p_target_amount_won, v_actor)
  on conflict (household_id, payment_method_id, target_month) do update
    set target_amount_won = excluded.target_amount_won, updated_at = now();
end;
$$;

create or replace function public.set_transaction_performance(
  p_transaction_id uuid,
  p_expected_version integer,
  p_included boolean
)
returns void
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_row public.transactions%rowtype;
  v_actor uuid := auth.uid();
begin
  select * into v_row from public.transactions where id = p_transaction_id for update;
  if not found or v_actor is null or not public.is_active_household_member(v_row.household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if v_row.version <> p_expected_version or v_row.voided_at is not null then
    raise exception using errcode = 'P0001', message = 'version_conflict';
  end if;
  update public.transactions set performance_included = p_included, updated_by = v_actor,
    updated_at = now(), version = version + 1 where id = p_transaction_id;
end;
$$;

create or replace function public.card_performance(
  p_household_id uuid,
  p_target_month date
)
returns jsonb
language plpgsql security definer set search_path = public, auth
as $$
declare
  v_result jsonb;
begin
  if not public.is_active_household_member(p_household_id) or p_target_month is null
     or extract(day from p_target_month) <> 1 then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'payment_method_id', c.id, 'name', c.name, 'kind', c.kind,
    'target_amount_won', coalesce(t.target_amount_won, 0),
    'actual_amount_won', coalesce(sum(case when x.performance_included then x.amount_won else 0 end), 0)
  ) order by c.created_at), '[]'::jsonb) into v_result
  from public.payment_methods c
  left join public.card_targets t on t.household_id = c.household_id
    and t.payment_method_id = c.id and t.target_month = p_target_month
  left join public.transactions x on x.household_id = c.household_id
    and x.payment_method_id = c.id and x.kind = 'expense' and x.voided_at is null
    and x.occurred_on >= p_target_month and x.occurred_on < (p_target_month + interval '1 month')::date
  where c.household_id = p_household_id and c.kind in ('debit_card', 'credit_card') and c.archived_at is null
  group by c.id, c.name, c.kind, c.created_at, t.target_amount_won;
  return v_result;
end;
$$;

revoke all on function public.add_card_payment_method(uuid, text, text, uuid) from public;
revoke all on function public.set_card_target(uuid, uuid, date, bigint) from public;
revoke all on function public.set_transaction_performance(uuid, integer, boolean) from public;
revoke all on function public.card_performance(uuid, date) from public;
grant execute on function public.add_card_payment_method(uuid, text, text, uuid) to authenticated;
grant execute on function public.set_card_target(uuid, uuid, date, bigint) to authenticated;
grant execute on function public.set_transaction_performance(uuid, integer, boolean) to authenticated;
grant execute on function public.card_performance(uuid, date) to authenticated;
