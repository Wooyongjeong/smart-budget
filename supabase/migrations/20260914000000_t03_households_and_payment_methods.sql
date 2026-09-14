-- T03: household ownership, membership, and payment method boundaries.
-- All writes from the client go through the security-definer functions below.

create extension if not exists pgcrypto;

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '' check (char_length(display_name) <= 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(btrim(name)) between 1 and 100),
  status text not null default 'active' check (status in ('active', 'archived')),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  unique (id, household_id),
  check (left_at is null or left_at >= joined_at)
);

create unique index household_members_active_user
  on public.household_members (household_id, user_id)
  where left_at is null;

create table public.payment_methods (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  kind text not null check (kind in ('cash', 'bank', 'debit_card', 'credit_card', 'voucher')),
  name text not null check (char_length(btrim(name)) between 1 and 100),
  owner_member_id uuid,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  unique (id, household_id),
  foreign key (owner_member_id, household_id)
    references public.household_members (id, household_id)
);

create index household_members_user_active
  on public.household_members (user_id)
  where left_at is null;
create index payment_methods_household
  on public.payment_methods (household_id, id);

create or replace function public.is_active_household_member(
  p_household_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, auth
as $$
  select exists (
    select 1
    from public.household_members m
    where m.household_id = p_household_id
      and m.user_id = p_user_id
      and m.left_at is null
  );
$$;

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
  return v_household_id;
end;
$$;

create or replace function public.add_payment_method(
  p_household_id uuid,
  p_kind text,
  p_name text,
  p_owner_member_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_id uuid;
begin
  if not public.is_active_household_member(p_household_id) then
    raise exception using errcode = '42501', message = 'forbidden';
  end if;
  if p_kind not in ('cash', 'bank', 'debit_card', 'credit_card', 'voucher')
     or p_name is null or char_length(btrim(p_name)) not between 1 and 100 then
    raise exception using errcode = '22023', message = 'payment_method_invalid';
  end if;
  if p_owner_member_id is not null and not exists (
    select 1 from public.household_members
    where id = p_owner_member_id and household_id = p_household_id and left_at is null
  ) then
    raise exception using errcode = '22023', message = 'owner_member_invalid';
  end if;

  insert into public.payment_methods (household_id, kind, name, owner_member_id)
  values (p_household_id, p_kind, btrim(p_name), p_owner_member_id)
  returning id into v_id;
  return v_id;
end;
$$;

alter table public.profiles enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.payment_methods enable row level security;

create policy profiles_select_same_household on public.profiles
  for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.household_members me
      join public.household_members them
        on them.household_id = me.household_id and them.user_id = profiles.user_id
      where me.user_id = auth.uid() and me.left_at is null and them.left_at is null
    )
  );

create policy households_select_member on public.households
  for select to authenticated
  using (public.is_active_household_member(id));

create policy members_select_member on public.household_members
  for select to authenticated
  using (public.is_active_household_member(household_id));

create policy payment_methods_select_member on public.payment_methods
  for select to authenticated
  using (public.is_active_household_member(household_id));

revoke all on public.profiles, public.households,
  public.household_members, public.payment_methods from anon, authenticated;
grant select on public.profiles, public.households,
  public.household_members, public.payment_methods to authenticated;
revoke all on function public.is_active_household_member(uuid, uuid) from public;
revoke all on function public.create_household(text, text) from public;
revoke all on function public.add_payment_method(uuid, text, text, uuid) from public;
grant execute on function public.is_active_household_member(uuid, uuid) to authenticated;
grant execute on function public.create_household(text, text) to authenticated;
grant execute on function public.add_payment_method(uuid, text, text, uuid) to authenticated;
