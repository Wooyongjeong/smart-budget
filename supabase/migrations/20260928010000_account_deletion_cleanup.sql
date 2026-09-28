-- Keep shared financial records but remove references to a deleted identity.
alter table public.households alter column created_by drop not null;
alter table public.households drop constraint households_created_by_fkey;
alter table public.households add constraint households_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

alter table public.household_members alter column user_id drop not null;
alter table public.household_members drop constraint household_members_user_id_fkey;
alter table public.household_members add constraint household_members_user_id_fkey
  foreign key (user_id) references auth.users(id) on delete set null;

alter table public.transactions alter column created_by drop not null;
alter table public.transactions alter column updated_by drop not null;
alter table public.transactions drop constraint transactions_created_by_fkey;
alter table public.transactions add constraint transactions_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;
alter table public.transactions drop constraint transactions_updated_by_fkey;
alter table public.transactions add constraint transactions_updated_by_fkey
  foreign key (updated_by) references auth.users(id) on delete set null;

alter table public.invitations alter column created_by drop not null;
alter table public.invitations drop constraint invitations_created_by_fkey;
alter table public.invitations add constraint invitations_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

alter table public.card_targets alter column created_by drop not null;
alter table public.card_targets drop constraint card_targets_created_by_fkey;
alter table public.card_targets add constraint card_targets_created_by_fkey
  foreign key (created_by) references auth.users(id) on delete set null;

create function public._cleanup_deleted_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, auth
as $$
declare
  v_household_id uuid;
begin
  for v_household_id in
    select distinct household_id from public.household_members
    where user_id = old.id and left_at is null
    order by household_id
  loop
    perform 1 from public.households where id = v_household_id for update;
    if not found then continue; end if;

    if exists (
      select 1 from public.household_members
      where household_id = v_household_id and user_id is not null
        and user_id <> old.id and left_at is null
    ) then
      update public.household_members set left_at = now()
      where household_id = v_household_id and user_id = old.id and left_at is null;
      if not exists (
        select 1 from public.household_members
        where household_id = v_household_id and role = 'owner' and left_at is null
      ) then
        update public.household_members set role = 'owner'
        where id = (
          select id from public.household_members
          where household_id = v_household_id and left_at is null
          order by joined_at, id limit 1
        );
      end if;
    else
      delete from public.households where id = v_household_id;
    end if;
  end loop;

  -- An outstanding invitation should not outlive the member who issued it.
  delete from public.invitations where created_by = old.id;
  return old;
end;
$$;

revoke all on function public._cleanup_deleted_auth_user() from public, anon, authenticated;
create trigger cleanup_deleted_auth_user
  before delete on auth.users
  for each row execute function public._cleanup_deleted_auth_user();
