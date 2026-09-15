-- Every household starts with one shared cash payment method. Existing
-- households are backfilled without touching any user-created methods.
insert into public.payment_methods (household_id, kind, name)
select h.id, 'cash', '현금'
from public.households h
where not exists (
  select 1
  from public.payment_methods pm
  where pm.household_id = h.id
    and pm.kind = 'cash'
    and pm.name = '현금'
);

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
    set display_name = excluded.display_name, updated_at = now();

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

revoke all on function public.create_household(text, text) from public;
grant execute on function public.create_household(text, text) to authenticated;
