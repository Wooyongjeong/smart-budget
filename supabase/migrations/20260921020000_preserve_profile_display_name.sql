-- Preserve an onboarding display name when the first household is created,
-- and expose the current user's display name without requiring membership.
create or replace function public.create_household(
  p_name text,
  p_display_name text default ''
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_household_id uuid;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if p_name is null or char_length(btrim(p_name)) not between 1 and 100 then
    raise exception using errcode = '22023', message = 'household_name_invalid';
  end if;

  insert into public.profiles (user_id, display_name)
  values (v_user_id, coalesce(btrim(p_display_name), ''))
  on conflict (user_id) do update
    set display_name = excluded.display_name, updated_at = now()
    where excluded.display_name <> '';

  insert into public.households (name, created_by)
  values (btrim(p_name), v_user_id)
  returning id into v_household_id;

  insert into public.household_members (household_id, user_id, role)
  values (v_household_id, v_user_id, 'owner');

  insert into public.payment_methods (household_id, kind, name)
  values (v_household_id, 'cash', '현금');
  return v_household_id;
end;
$$;

create or replace function public.current_profile_display_name()
returns text
language plpgsql
stable
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text;
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  select nullif(btrim(display_name), '') into v_name
  from public.profiles
  where user_id = v_user_id;
  return coalesce(v_name, '나');
end;
$$;

revoke all on function public.create_household(text, text) from public;
revoke all on function public.current_profile_display_name() from public;
grant execute on function public.create_household(text, text) to authenticated;
grant execute on function public.current_profile_display_name() to authenticated;
