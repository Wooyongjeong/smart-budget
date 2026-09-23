-- WAL01: voucher creation and its initial balance are one transaction.
create or replace function public.add_voucher_with_initial_topup(
  p_household_id uuid,
  p_name text,
  p_owner_member_id uuid,
  p_paid_amount_won bigint,
  p_voucher_amount_won bigint,
  p_payment_method_id uuid default null
) returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_voucher_id uuid;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  perform 1 from public.households where id = p_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 1 and 100
     or p_paid_amount_won is null or p_paid_amount_won <= 0
     or p_voucher_amount_won is null or p_voucher_amount_won <= 0 then
    raise exception using errcode = '22023', message = 'validation_failed';
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

  insert into public.payment_methods (household_id, kind, name, owner_member_id)
  values (p_household_id, 'voucher', btrim(p_name), p_owner_member_id)
  returning id into v_voucher_id;

  perform public.record_voucher_event(
    p_household_id, 'voucher_topup', v_voucher_id,
    p_paid_amount_won, p_voucher_amount_won, current_date,
    '상품권 초기 잔액', p_payment_method_id, null
  );
  return v_voucher_id;
end;
$$;

revoke all on function public.add_voucher_with_initial_topup(uuid, text, uuid, bigint, bigint, uuid)
  from public, anon;
grant execute on function public.add_voucher_with_initial_topup(uuid, text, uuid, bigint, bigint, uuid)
  to authenticated;
