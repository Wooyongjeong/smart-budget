create or replace function public.archive_payment_method(
  p_household_id uuid,
  p_payment_method_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_active_household_member(p_household_id) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;

  update public.payment_methods
  set archived_at = coalesce(archived_at, now())
  where id = p_payment_method_id
    and household_id = p_household_id;

  if not found then
    raise exception using errcode = '22023', message = 'payment_method_not_found';
  end if;
end;
$$;

revoke all on function public.archive_payment_method(uuid, uuid) from public;
grant execute on function public.archive_payment_method(uuid, uuid) to authenticated;
