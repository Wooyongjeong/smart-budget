-- T09: let each authenticated user set the name shown in their household.
create or replace function public.update_profile_display_name(p_display_name text)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_user_id uuid := auth.uid();
  v_name text := btrim(coalesce(p_display_name, ''));
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  if char_length(v_name) not between 1 and 100 then
    raise exception using errcode = '22023', message = 'display_name_invalid';
  end if;

  insert into public.profiles (user_id, display_name)
  values (v_user_id, v_name)
  on conflict (user_id) do update
    set display_name = excluded.display_name, updated_at = now();
  return v_name;
end;
$$;

revoke all on function public.update_profile_display_name(text) from public;
grant execute on function public.update_profile_display_name(text) to authenticated;
