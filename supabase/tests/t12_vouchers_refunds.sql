begin;
select plan(5);
select has_table('public','voucher_movements','voucher movements table exists');
select has_function('public','record_voucher_event',array['uuid','text','uuid','bigint','date','text','uuid','uuid'],'voucher event RPC exists');
select ok(has_table_privilege('authenticated','public.voucher_movements','SELECT'),'authenticated can read voucher movements');
select ok(not has_table_privilege('authenticated','public.voucher_movements','INSERT'),'voucher movements cannot be directly inserted');
select has_function('public','add_voucher_with_initial_topup',array['uuid','text','uuid','bigint','bigint','uuid'],'voucher onboarding RPC exists');
select * from finish();
rollback;
