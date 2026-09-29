begin;
select plan(11);

insert into auth.users(id) values
  ('90000000-0000-0000-0000-000000000081'),
  ('90000000-0000-0000-0000-000000000082');
insert into public.profiles(user_id, display_name)
values ('90000000-0000-0000-0000-000000000081', '삭제할 사람');
insert into public.households(id, name, created_by) values
  ('80000000-0000-0000-0000-000000000081', '공동', '90000000-0000-0000-0000-000000000081'),
  ('80000000-0000-0000-0000-000000000082', '혼자', '90000000-0000-0000-0000-000000000081');
insert into public.household_members(id, household_id, user_id, role) values
  ('70000000-0000-0000-0000-000000000081', '80000000-0000-0000-0000-000000000081', '90000000-0000-0000-0000-000000000081', 'owner'),
  ('70000000-0000-0000-0000-000000000082', '80000000-0000-0000-0000-000000000081', '90000000-0000-0000-0000-000000000082', 'member'),
  ('70000000-0000-0000-0000-000000000083', '80000000-0000-0000-0000-000000000082', '90000000-0000-0000-0000-000000000081', 'owner');
insert into public.transactions(household_id, kind, occurred_on, amount_won, merchant, member_id, created_by, updated_by)
values
  ('80000000-0000-0000-0000-000000000081', 'expense', '2026-09-28', 100, '공동 거래', '70000000-0000-0000-0000-000000000081', '90000000-0000-0000-0000-000000000081', '90000000-0000-0000-0000-000000000081'),
  ('80000000-0000-0000-0000-000000000082', 'expense', '2026-09-28', 200, '개인 거래', '70000000-0000-0000-0000-000000000083', '90000000-0000-0000-0000-000000000081', '90000000-0000-0000-0000-000000000081');
insert into public.invitations(household_id, token_hash, expires_at, created_by)
values ('80000000-0000-0000-0000-000000000081', decode(repeat('aa', 32), 'hex'), now() + interval '1 day', '90000000-0000-0000-0000-000000000081');

delete from auth.users where id = '90000000-0000-0000-0000-000000000081';

select ok(exists(select 1 from public.households where id = '80000000-0000-0000-0000-000000000081'), 'shared household remains');
select ok(not exists(select 1 from public.households where id = '80000000-0000-0000-0000-000000000082'), 'solo household is deleted');
select ok(exists(select 1 from public.transactions where merchant = '공동 거래'), 'shared transaction remains');
select ok(not exists(select 1 from public.transactions where merchant = '개인 거래'), 'solo transaction is deleted');
select ok(exists(select 1 from public.transactions where merchant = '공동 거래' and created_by is null and updated_by is null), 'shared transaction audit identity is cleared');
select ok(exists(select 1 from public.household_members where id = '70000000-0000-0000-0000-000000000081' and user_id is null and left_at is not null), 'former member is anonymous and inactive');
select ok(exists(select 1 from public.household_members where id = '70000000-0000-0000-0000-000000000082' and role = 'owner'), 'remaining member becomes owner');
select ok(not exists(select 1 from public.profiles where user_id = '90000000-0000-0000-0000-000000000081'), 'profile is deleted');
select ok(not exists(select 1 from public.invitations where created_by = '90000000-0000-0000-0000-000000000081'), 'issued invitations are removed');
select ok(exists(select 1 from auth.users where id = '90000000-0000-0000-0000-000000000082'), 'remaining auth user is retained');
select ok(exists(select 1 from public.transactions where merchant = '공동 거래' and member_id = '70000000-0000-0000-0000-000000000081'), 'historical member reference remains');

select * from finish();
rollback;
