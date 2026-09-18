create table public.receipt_analysis_usage (
  user_id uuid not null references auth.users(id) on delete cascade,
  household_id uuid not null references public.households(id) on delete cascade,
  usage_date date not null default current_date,
  request_count integer not null default 1 check (request_count between 1 and 20),
  primary key (user_id, household_id, usage_date)
);

alter table public.receipt_analysis_usage enable row level security;

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
begin
  if v_user_id is null
     or not public.is_active_household_member(p_household_id, v_user_id) then
    return false;
  end if;

  insert into public.receipt_analysis_usage (
    user_id, household_id, usage_date, request_count
  ) values (
    v_user_id, p_household_id, current_date, 1
  )
  on conflict (user_id, household_id, usage_date) do update
  set request_count = public.receipt_analysis_usage.request_count + 1
  where public.receipt_analysis_usage.request_count < 20
  returning true into v_allowed;

  return coalesce(v_allowed, false);
end;
$$;

revoke all on table public.receipt_analysis_usage from anon, authenticated;
revoke all on function public.consume_receipt_analysis_quota(uuid) from public;
grant execute on function public.consume_receipt_analysis_quota(uuid) to authenticated;
