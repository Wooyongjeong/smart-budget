-- T06: one filtered query contract for period lists and totals.
create or replace function public.query_transactions(
  p_household_id uuid,
  p_start_date date,
  p_end_date date,
  p_member_id uuid default null,
  p_payment_method_id uuid default null,
  p_category text default null,
  p_cursor_date date default null,
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null,
  p_limit integer default 50
)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_items jsonb;
  v_income bigint;
  v_expense bigint;
begin
  if p_start_date is null or p_end_date is null or p_start_date >= p_end_date
     or p_limit not between 1 and 100 then
    raise exception using errcode = '22023', message = 'validation_failed', detail = 'period';
  end if;
  if not public.is_active_household_member(p_household_id) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  select coalesce(sum(case when kind = 'income' then amount_won else 0 end), 0),
         coalesce(sum(case when kind in ('expense', 'voucher_topup') then amount_won else 0 end), 0)
    into v_income, v_expense
  from public.transactions
  where household_id = p_household_id and voided_at is null
    and occurred_on >= p_start_date and occurred_on < p_end_date
    and (p_member_id is null or member_id = p_member_id)
    and (p_payment_method_id is null or payment_method_id = p_payment_method_id)
    and (p_category is null or category = p_category);
  select coalesce(jsonb_agg(to_jsonb(t) order by t.occurred_on desc, t.created_at desc, t.id desc), '[]'::jsonb)
    into v_items
  from (
    select id, household_id, kind, occurred_on, amount_won, merchant, category,
           payment_method_id, member_id, memo, created_by, updated_by,
           created_at, updated_at, version
    from public.transactions
    where household_id = p_household_id and voided_at is null
      and occurred_on >= p_start_date and occurred_on < p_end_date
      and (p_member_id is null or member_id = p_member_id)
      and (p_payment_method_id is null or payment_method_id = p_payment_method_id)
      and (p_category is null or category = p_category)
      and (p_cursor_id is null or (occurred_on, created_at, id) <
           (p_cursor_date, p_cursor_created_at, p_cursor_id))
    order by occurred_on desc, created_at desc, id desc
    limit p_limit
  ) t;
  return jsonb_build_object('items', v_items, 'total_income', v_income, 'total_expense', v_expense);
end;
$$;

revoke all on function public.query_transactions(uuid, date, date, uuid, uuid, text, date, timestamptz, uuid, integer) from public;
revoke execute on function public.query_transactions(uuid, date, date, uuid, uuid, text, date, timestamptz, uuid, integer) from anon;
grant execute on function public.query_transactions(uuid, date, date, uuid, uuid, text, date, timestamptz, uuid, integer) to authenticated;


create or replace function public.card_performance(p_household_id uuid, p_target_month date)
returns jsonb language plpgsql security definer set search_path = public, auth
as $$
declare v_result jsonb;
begin
  if not public.is_active_household_member(p_household_id) then
    raise exception using errcode='42501', message='forbidden';
  end if;
  if p_target_month is null or extract(day from p_target_month) <> 1 then
    raise exception using errcode='22023', message='validation_failed';
  end if;
  select coalesce(jsonb_agg(to_jsonb(summary) - 'created_at' order by summary.created_at, summary.payment_method_id), '[]'::jsonb)
  into v_result
  from (
    select c.id as payment_method_id, c.name, c.kind, c.created_at,
      coalesce(t.target_amount_won, 0) as target_amount_won,
      coalesce(sum(x.amount_won) filter (where x.performance_included), 0) as actual_amount_won
    from public.payment_methods c
    left join public.card_targets t on t.household_id=c.household_id
      and t.payment_method_id=c.id and t.target_month=p_target_month
    left join public.transactions x on x.household_id=c.household_id
      and x.payment_method_id=c.id and x.kind in ('expense','voucher_topup')
      and x.voided_at is null and x.occurred_on >= p_target_month
      and x.occurred_on < (p_target_month + interval '1 month')::date
    where c.household_id=p_household_id and c.kind in ('debit_card','credit_card')
      and c.archived_at is null
    group by c.id, c.name, c.kind, c.created_at, t.target_amount_won
  ) summary;
  return v_result;
end;
$$;
revoke all on function public.card_performance(uuid,date) from public, anon;
grant execute on function public.card_performance(uuid,date) to authenticated;

