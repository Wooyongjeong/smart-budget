-- TIME01: use the MVP business calendar rather than the Postgres session zone.
-- Keeping the offset in one expression makes a future household timezone policy
-- an explicit server-side decision instead of relying on database defaults.
alter table public.receipt_analysis_usage
  alter column usage_date set default (timezone('Asia/Seoul', now())::date);

create or replace function public.consume_receipt_analysis_quota(
  p_household_id uuid
)
returns boolean
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_allowed boolean := false;
  v_usage_date date := timezone('Asia/Seoul', now())::date;
begin
  if v_user_id is null
     or not public.is_active_household_member(p_household_id, v_user_id) then
    return false;
  end if;

  insert into public.receipt_analysis_usage (
    user_id, household_id, usage_date, request_count
  ) values (
    v_user_id, p_household_id, v_usage_date, 1
  )
  on conflict (user_id, household_id, usage_date) do update
  set request_count = public.receipt_analysis_usage.request_count + 1
  where public.receipt_analysis_usage.request_count < 20
  returning true into v_allowed;

  return coalesce(v_allowed, false);
end;
$$;

-- Preserve the current voucher onboarding function's validation, locking,
-- request-idempotency and permissions while changing only its business date.
do $$
declare
  v_definition text;
begin
  select pg_get_functiondef(
    'public.add_voucher_with_initial_topup(uuid,text,uuid,bigint,bigint,uuid,text,uuid,uuid)'::regprocedure
  ) into v_definition;
  v_definition := regexp_replace(
    v_definition,
    '\mcurrent_date\M',
    'timezone(''Asia/Seoul'', now())::date',
    'gi'
  );
  execute v_definition;
end;
$$;
