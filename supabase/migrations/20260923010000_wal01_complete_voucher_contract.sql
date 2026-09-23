-- WAL01: distinguish imported voucher balance from a paid purchase and make
-- voucher onboarding idempotent. Imported balances never count as spending.
alter table public.transactions drop constraint transactions_kind_check;
alter table public.transactions add constraint transactions_kind_check
  check (kind in ('income', 'expense', 'voucher_initial_balance', 'voucher_topup', 'voucher_use', 'refund'));

alter table public.write_requests drop constraint write_requests_operation_check;
alter table public.write_requests add constraint write_requests_operation_check
  check (operation in ('save_transactions', 'edit_transaction', 'void_transaction', 'add_voucher'));

create or replace function public.add_voucher_with_initial_topup(
  p_household_id uuid,
  p_name text,
  p_owner_member_id uuid,
  p_paid_amount_won bigint,
  p_voucher_amount_won bigint,
  p_payment_method_id uuid,
  p_mode text,
  p_actual_member_id uuid,
  p_request_id uuid
) returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_voucher_id uuid;
  v_transaction_id uuid;
  v_payload jsonb;
  v_hash bytea;
  v_existing public.write_requests%rowtype;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  perform 1 from public.households where id = p_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if p_request_id is null or p_mode not in ('initial_balance', 'purchase')
     or p_name is null or char_length(btrim(p_name)) not between 1 and 100
     or p_voucher_amount_won is null or p_voucher_amount_won <= 0
     or p_voucher_amount_won > 999999999 or p_actual_member_id is null
     or (p_mode = 'initial_balance' and (p_paid_amount_won <> 0 or p_payment_method_id is not null))
     or (p_mode = 'purchase' and (p_paid_amount_won is null or p_paid_amount_won <= 0
                                  or p_paid_amount_won > 999999999 or p_payment_method_id is null)) then
    raise exception using errcode = '22023', message = 'validation_failed';
  end if;
  if not exists (
    select 1 from public.household_members
    where id = p_actual_member_id and household_id = p_household_id and left_at is null
  ) then
    raise exception using errcode = '22023', message = 'actual_member_invalid';
  end if;
  if p_owner_member_id is not null and not exists (
    select 1 from public.household_members
    where id = p_owner_member_id and household_id = p_household_id and left_at is null
  ) then
    raise exception using errcode = '22023', message = 'owner_member_invalid';
  end if;
  if p_payment_method_id is not null and not exists (
    select 1 from public.payment_methods
    where id = p_payment_method_id and household_id = p_household_id
      and kind in ('cash', 'bank', 'debit_card', 'credit_card') and archived_at is null
  ) then
    raise exception using errcode = '22023', message = 'payment_method_invalid';
  end if;

  v_payload := jsonb_build_object(
    'name', btrim(p_name), 'owner_member_id', p_owner_member_id,
    'paid_amount_won', p_paid_amount_won, 'voucher_amount_won', p_voucher_amount_won,
    'payment_method_id', p_payment_method_id, 'mode', p_mode,
    'actual_member_id', p_actual_member_id
  );
  v_hash := public._transaction_payload_hash('add_voucher', v_payload);
  insert into public.write_requests (household_id, actor_id, request_id, operation, payload_hash)
  values (p_household_id, v_actor, p_request_id, 'add_voucher', v_hash)
  on conflict (household_id, actor_id, request_id) do nothing;
  select * into v_existing from public.write_requests
  where household_id = p_household_id and actor_id = v_actor and request_id = p_request_id
  for update;
  if v_existing.payload_hash <> v_hash then
    raise exception using errcode = 'P0001', message = 'idempotency_conflict';
  end if;
  if cardinality(v_existing.result_transaction_ids) > 0 then
    return v_existing.result_transaction_ids[1];
  end if;

  insert into public.payment_methods (household_id, kind, name, owner_member_id)
  values (p_household_id, 'voucher', btrim(p_name), p_owner_member_id)
  returning id into v_voucher_id;

  insert into public.transactions (
    household_id, kind, occurred_on, amount_won, merchant, payment_method_id,
    member_id, created_by, updated_by, voucher_id, voucher_amount_won
  ) values (
    p_household_id,
    case when p_mode = 'initial_balance' then 'voucher_initial_balance' else 'voucher_topup' end,
    current_date,
    case when p_mode = 'initial_balance' then p_voucher_amount_won else p_paid_amount_won end,
    case when p_mode = 'initial_balance' then '상품권 초기 잔액' else '상품권 구매' end,
    p_payment_method_id, p_actual_member_id, v_actor, v_actor,
    v_voucher_id, p_voucher_amount_won
  ) returning id into v_transaction_id;
  insert into public.voucher_movements (household_id, voucher_id, transaction_id, delta_won)
  values (p_household_id, v_voucher_id, v_transaction_id, p_voucher_amount_won);

  update public.write_requests set result_transaction_ids = array[v_voucher_id]
  where household_id = p_household_id and actor_id = v_actor and request_id = p_request_id;
  return v_voucher_id;
end;
$$;

revoke all on function public.add_voucher_with_initial_topup(uuid,text,uuid,bigint,bigint,uuid,text,uuid,uuid)
  from public, anon;
grant execute on function public.add_voucher_with_initial_topup(uuid,text,uuid,bigint,bigint,uuid,text,uuid,uuid)
  to authenticated;
