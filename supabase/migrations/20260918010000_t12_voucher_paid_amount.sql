create or replace function public.record_voucher_event(
  p_household_id uuid, p_kind text, p_voucher_id uuid, p_paid_amount_won bigint,
  p_voucher_amount_won bigint, p_occurred_on date, p_merchant text,
  p_payment_method_id uuid default null, p_related_transaction_id uuid default null
) returns uuid language plpgsql security definer set search_path = public, auth as $$
declare v_actor uuid := auth.uid(); v_id uuid; v_balance bigint; v_delta bigint;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id) then raise exception using errcode='42501', message='forbidden'; end if;
  if p_kind not in ('voucher_topup','voucher_use','refund') or p_paid_amount_won <= 0 or p_voucher_amount_won <= 0 then raise exception using errcode='22023', message='validation_failed'; end if;
  perform 1 from public.payment_methods where id=p_voucher_id and household_id=p_household_id and kind='voucher' and archived_at is null for update;
  if not found then raise exception using errcode='22023', message='voucher_invalid'; end if;
  select coalesce(sum(delta_won),0) into v_balance from public.voucher_movements where household_id=p_household_id and voucher_id=p_voucher_id;
  v_delta := case when p_kind='voucher_topup' or (p_kind='refund' and p_related_transaction_id is not null) then p_voucher_amount_won else -p_voucher_amount_won end;
  if v_balance + v_delta < 0 then raise exception using errcode='22023', message='insufficient_balance'; end if;
  insert into public.transactions(household_id,kind,occurred_on,amount_won,merchant,payment_method_id,created_by,updated_by,voucher_id,voucher_amount_won,related_transaction_id)
  values(p_household_id,p_kind,p_occurred_on,p_paid_amount_won,btrim(coalesce(p_merchant,'상품권')),p_payment_method_id,v_actor,v_actor,p_voucher_id,p_voucher_amount_won,p_related_transaction_id) returning id into v_id;
  insert into public.voucher_movements(household_id,voucher_id,transaction_id,delta_won) values(p_household_id,p_voucher_id,v_id,v_delta);
  return v_id;
end; $$;
revoke all on function public.record_voucher_event(uuid,text,uuid,bigint,bigint,date,text,uuid,uuid) from public;
grant execute on function public.record_voucher_event(uuid,text,uuid,bigint,bigint,date,text,uuid,uuid) to authenticated;
