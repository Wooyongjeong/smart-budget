
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
  if p_target_month is null or extract(day from p_target_month) <> 1 or p_target_amount_won is null or p_target_amount_won <= 0 then
    raise exception using errcode = '22023', message = 'target_invalid';
  end if;
  select kind into v_kind from public.payment_methods
  where id = p_payment_method_id and household_id = p_household_id and archived_at is null;
  if not found or v_kind not in ('debit_card', 'credit_card') then
    raise exception using errcode = '22023', message = 'card_invalid';
  end if;
  insert into public.card_targets (household_id, payment_method_id, target_month, target_amount_won, created_by)
  values (p_household_id, p_payment_method_id, p_target_month, p_target_amount_won, v_actor)
  on conflict (household_id, payment_method_id, target_month) do update
    set target_amount_won = excluded.target_amount_won, updated_at = now();
end;
$$;

create or replace function public.voucher_balance(p_household_id uuid, p_voucher_id uuid)
returns bigint language plpgsql security definer set search_path = public, auth
as $$
begin
  if not public.is_active_household_member(p_household_id) then
    raise exception using errcode='42501', message='forbidden';
  end if;
  if not exists (select 1 from public.payment_methods where id=p_voucher_id and household_id=p_household_id and kind='voucher') then
    raise exception using errcode='22023', message='voucher_invalid';
  end if;
  return (select coalesce(sum(m.delta_won),0)::bigint from public.voucher_movements m
    join public.transactions t on t.id=m.transaction_id and t.household_id=m.household_id
    where m.household_id=p_household_id and m.voucher_id=p_voucher_id and t.voided_at is null);
end;
$$;
revoke all on function public.voucher_balance(uuid,uuid) from public, anon;
grant execute on function public.voucher_balance(uuid,uuid) to authenticated;
create or replace function public.record_voucher_event(
  p_household_id uuid, p_kind text, p_voucher_id uuid, p_paid_amount_won bigint,
  p_voucher_amount_won bigint, p_occurred_on date, p_merchant text,
  p_payment_method_id uuid default null, p_related_transaction_id uuid default null
) returns uuid language plpgsql security definer set search_path = public, auth as $$
declare v_actor uuid := auth.uid(); v_id uuid; v_balance bigint; v_delta bigint; v_original public.transactions%rowtype; v_refunded bigint;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id) then raise exception using errcode='42501', message='forbidden'; end if;
  perform 1 from public.households where id=p_household_id and status='active' for update;
  if not found or not public.is_active_household_member(p_household_id) then
    raise exception using errcode='42501', message='forbidden';
  end if;
  if p_kind is null or p_paid_amount_won is null or p_voucher_amount_won is null
    or p_occurred_on is null or p_occurred_on not between date '2000-01-01' and date '2100-12-31'
    or p_paid_amount_won > 999999999 or p_voucher_amount_won > 999999999
    or p_merchant is null or char_length(btrim(p_merchant)) not between 1 and 100 then
    raise exception using errcode='22023', message='validation_failed';
  end if;
  if p_kind not in ('voucher_topup','voucher_use','refund') or p_paid_amount_won <= 0 or p_voucher_amount_won <= 0 then raise exception using errcode='22023', message='validation_failed'; end if;
  perform 1 from public.payment_methods where id=p_voucher_id and household_id=p_household_id and kind='voucher' and archived_at is null for update;
  if not found then raise exception using errcode='22023', message='voucher_invalid'; end if;
  if p_kind='refund' then
    select * into v_original from public.transactions
      where id=p_related_transaction_id and household_id=p_household_id
        and voucher_id=p_voucher_id and kind='voucher_use' and voided_at is null for update;
    if not found or p_occurred_on < v_original.occurred_on then
      raise exception using errcode='22023', message='refund_original_invalid';
    end if;
    select coalesce(sum(voucher_amount_won),0) into v_refunded from public.transactions
      where related_transaction_id=v_original.id and household_id=p_household_id and kind='refund' and voided_at is null;
    if v_refunded+p_voucher_amount_won > v_original.voucher_amount_won then
      raise exception using errcode='22023', message='refund_limit_exceeded';
    end if;
  elsif p_related_transaction_id is not null then
    raise exception using errcode='22023', message='validation_failed';
  end if;
  if p_kind in ('voucher_use','refund') and p_paid_amount_won <> p_voucher_amount_won then
    raise exception using errcode='22023', message='validation_failed';
  end if;
  if p_payment_method_id is not null and not exists (
    select 1 from public.payment_methods where id=p_payment_method_id and household_id=p_household_id
      and kind in ('cash','bank','debit_card','credit_card') and archived_at is null
  ) then raise exception using errcode='22023', message='payment_method_invalid'; end if;
  v_balance := public.voucher_balance(p_household_id,p_voucher_id);
  v_delta := case when p_kind='voucher_topup' or (p_kind='refund' and p_related_transaction_id is not null) then p_voucher_amount_won else -p_voucher_amount_won end;
  if v_balance + v_delta < 0 then raise exception using errcode='22023', message='insufficient_balance'; end if;
  insert into public.transactions(household_id,kind,occurred_on,amount_won,merchant,payment_method_id,created_by,updated_by,voucher_id,voucher_amount_won,related_transaction_id)
  values(p_household_id,p_kind,p_occurred_on,p_paid_amount_won,btrim(coalesce(p_merchant,'상품권')),p_payment_method_id,v_actor,v_actor,p_voucher_id,p_voucher_amount_won,p_related_transaction_id) returning id into v_id;
  insert into public.voucher_movements(household_id,voucher_id,transaction_id,delta_won) values(p_household_id,p_voucher_id,v_id,v_delta);
  if exists (
    select 1 from (
      select sum(sum(m.delta_won)) over(order by t.occurred_on) as balance
      from public.voucher_movements m join public.transactions t on t.id=m.transaction_id
      where m.household_id=p_household_id and m.voucher_id=p_voucher_id and t.voided_at is null
      group by t.occurred_on
    ) history where balance < 0
  ) then raise exception using errcode='22023', message='insufficient_balance'; end if;
  return v_id;
end; $$;
revoke all on function public.record_voucher_event(uuid,text,uuid,bigint,bigint,date,text,uuid,uuid) from public, anon;
grant execute on function public.record_voucher_event(uuid,text,uuid,bigint,bigint,date,text,uuid,uuid) to authenticated;

-- Keep the legacy signature without permitting validation bypasses.
create or replace function public.record_voucher_event(
  p_household_id uuid, p_kind text, p_voucher_id uuid, p_amount_won bigint,
  p_occurred_on date, p_merchant text, p_payment_method_id uuid default null,
  p_related_transaction_id uuid default null
) returns uuid language sql security invoker set search_path = public, auth as $$
  select public.record_voucher_event(p_household_id,p_kind,p_voucher_id,
    p_amount_won,p_amount_won,p_occurred_on,p_merchant,p_payment_method_id,p_related_transaction_id);
$$;
revoke all on function public.record_voucher_event(uuid,text,uuid,bigint,date,text,uuid,uuid) from public, anon;
grant execute on function public.record_voucher_event(uuid,text,uuid,bigint,date,text,uuid,uuid) to authenticated;
