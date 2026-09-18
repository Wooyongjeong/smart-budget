begin;
select plan(3);

select has_table(
  'public',
  'receipt_analysis_usage',
  'receipt analysis usage table exists'
);
select has_function(
  'public',
  'consume_receipt_analysis_quota',
  array['uuid'],
  'atomic receipt analysis quota RPC exists'
);
select ok(not has_table_privilege(
  'authenticated',
  'public.receipt_analysis_usage',
  'select'
), 'clients cannot read receipt analysis usage');

select * from finish();
rollback;
