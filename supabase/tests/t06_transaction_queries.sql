begin;
select plan(4);
select has_function('public', 'query_transactions', array['uuid','date','date','uuid','uuid','text','date','timestamp with time zone','uuid','integer'], 'period query RPC exists');
select ok(not has_function_privilege('anon', 'public.query_transactions(uuid,date,date,uuid,uuid,text,date,timestamptz,uuid,integer)', 'EXECUTE'), 'anon cannot execute query RPC');
select ok(has_function_privilege('authenticated', 'public.query_transactions(uuid,date,date,uuid,uuid,text,date,timestamptz,uuid,integer)', 'EXECUTE'), 'authenticated can execute query RPC');
select ok(exists (select 1 from pg_indexes where indexname = 'transactions_household_date'), 'transaction period index exists');
select * from finish();
rollback;
