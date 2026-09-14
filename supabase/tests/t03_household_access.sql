-- Run with `supabase db test` after `supabase start`.
begin;
select plan(6);

select has_table('public', 'profiles', 'profiles table exists');
select has_table('public', 'households', 'households table exists');
select has_table('public', 'household_members', 'membership table exists');
select has_table('public', 'payment_methods', 'payment methods table exists');
select ok(
  has_table_privilege('authenticated', 'public.payment_methods', 'SELECT')
    and not has_table_privilege('authenticated', 'public.payment_methods', 'INSERT'),
  'authenticated can read but cannot directly insert payment methods'
);
select ok(
  not has_table_privilege('authenticated', 'public.household_members', 'UPDATE')
    and not has_table_privilege('authenticated', 'public.households', 'DELETE'),
  'authenticated cannot directly mutate memberships or delete households'
);

select * from finish();
rollback;
