-- T09: one-time household invitations, two-member limit, and access revocation.
create table public.invitations (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  token_hash bytea not null unique,
  expires_at timestamptz not null,
  used_at timestamptz,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

alter table public.invitations enable row level security;
revoke all on public.invitations from anon, authenticated;

create or replace function public.create_invitation(
  p_household_id uuid,
  p_ttl interval default interval '7 days'
)
returns text
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_token text := encode(extensions.gen_random_bytes(24), 'hex');
  v_hash bytea := extensions.digest(convert_to(v_token, 'UTF8'), 'sha256');
  v_count integer;
begin
  if v_actor is null or not public.is_active_household_member(p_household_id, v_actor) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if p_ttl <= interval '0 days' or p_ttl > interval '30 days' then
    raise exception using errcode = '22023', message = 'invitation_ttl_invalid';
  end if;
  perform 1 from public.households where id = p_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  select count(*) into v_count from public.household_members
  where household_id = p_household_id and left_at is null;
  if v_count >= 2 then
    raise exception using errcode = 'P0001', message = 'household_full';
  end if;
  insert into public.invitations (household_id, token_hash, expires_at, created_by)
  values (p_household_id, v_hash, now() + p_ttl, v_actor);
  return v_token;
end;
$$;

create or replace function public.accept_invitation(p_token text)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_inv public.invitations%rowtype;
  v_count integer;
begin
  if v_actor is null or p_token is null or length(p_token) <> 48 then
    raise exception using errcode = '22023', message = 'invitation_invalid';
  end if;
  select * into v_inv from public.invitations
  where token_hash = extensions.digest(convert_to(p_token, 'UTF8'), 'sha256')
  for update;
  if not found or v_inv.used_at is not null or v_inv.expires_at <= now() then
    raise exception using errcode = 'P0001', message = 'invitation_expired_or_used';
  end if;
  perform 1 from public.households where id = v_inv.household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = 'P0001', message = 'household_unavailable';
  end if;
  if exists (select 1 from public.household_members where household_id = v_inv.household_id and user_id = v_actor and left_at is null) then
    raise exception using errcode = 'P0001', message = 'already_member';
  end if;
  select count(*) into v_count from public.household_members
  where household_id = v_inv.household_id and left_at is null;
  if v_count >= 2 then
    raise exception using errcode = 'P0001', message = 'household_full';
  end if;
  insert into public.household_members (household_id, user_id, role) values (v_inv.household_id, v_actor, 'member');
  update public.invitations set used_at = now() where id = v_inv.id;
  return v_inv.household_id;
end;
$$;

create or replace function public.leave_household(p_household_id uuid)
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_actor uuid := auth.uid();
  v_member_id uuid;
  v_remaining integer;
begin
  if v_actor is null then
    raise exception using errcode = '42501', message = 'authentication_required';
  end if;
  perform 1 from public.households where id = p_household_id and status = 'active' for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  select id into v_member_id from public.household_members
  where household_id = p_household_id and user_id = v_actor and left_at is null for update;
  if not found then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  update public.household_members set left_at = now() where id = v_member_id;
  select count(*) into v_remaining from public.household_members
  where household_id = p_household_id and left_at is null;
  if v_remaining = 0 then
    update public.households set status = 'archived' where id = p_household_id;
  end if;
end;
$$;

revoke all on function public.create_invitation(uuid, interval) from public;
revoke all on function public.accept_invitation(text) from public;
revoke all on function public.leave_household(uuid) from public;
grant execute on function public.create_invitation(uuid, interval) to authenticated;
grant execute on function public.accept_invitation(text) to authenticated;
grant execute on function public.leave_household(uuid) to authenticated;
