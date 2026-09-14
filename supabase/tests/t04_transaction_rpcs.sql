begin;
select plan(10);

select has_table('public', 'transactions', 'transactions table exists');
select has_table('public', 'write_requests', 'write request table exists');
select has_function('public', 'save_transactions', array['uuid', 'uuid', 'jsonb'], 'batch save RPC exists');
select has_function('public', 'edit_transaction', array['uuid', 'integer', 'uuid', 'jsonb'], 'edit RPC exists');
select has_function('public', 'void_transaction', array['uuid', 'integer', 'uuid'], 'void RPC exists');
select ok(
  has_table_privilege('authenticated', 'public.transactions', 'SELECT')
    and not has_table_privilege('authenticated', 'public.transactions', 'INSERT'),
  'authenticated can read but cannot directly insert transactions'
);
select ok(
  not has_table_privilege('authenticated', 'public.transactions', 'UPDATE')
    and not has_table_privilege('authenticated', 'public.transactions', 'DELETE'),
  'authenticated cannot directly update or delete transactions'
);
select col_is_pk('public', 'write_requests', array['household_id', 'actor_id', 'request_id'], 'request key is unique');
select ok(
  exists (
    select 1 from pg_constraint
    where conrelid = 'public.transactions'::regclass
      and conname like '%amount_won%'
  ),
  'positive amount constraint exists'
);
select ok(
  exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'transactions'
      and policyname = 'transactions_select_member'
      and 'authenticated' = any(roles)
  ),
  'transaction policy is authenticated-only'
);

select * from finish();
rollback;
