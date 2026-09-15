begin;
select plan(7);
insert into auth.users(id) values ('90000000-0000-0000-0000-000000000002');
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);
set local role authenticated;
select public.create_household('wallet review') as household_id \gset
select public.add_payment_method(:'household_id','voucher','voucher') as voucher_id \gset
select public.record_voucher_event(:'household_id','voucher_topup',:'voucher_id',93000,100000,'2026-09-15','topup');
select public.record_voucher_event(:'household_id','voucher_use',:'voucher_id',20000,20000,'2026-09-16','use') as use_id \gset
select is(public.voucher_balance(:'household_id',:'voucher_id'),80000::bigint,'server returns face balance');
select throws_ok(format('select public.record_voucher_event(%L,%L,%L,1,1,%L,%L)',:'household_id','refund',:'voucher_id','2026-09-16','bad'),'22023','refund_original_invalid','refund requires original use');
select throws_ok(format('select public.record_voucher_event(%L,%L,%L,1,%L,%L)',:'household_id','refund',:'voucher_id','2026-09-16','bad'),'22023','refund_original_invalid','legacy signature cannot bypass validation');
select public.record_voucher_event(:'household_id','refund',:'voucher_id',10000,10000,'2026-09-16','refund',null,:'use_id');
select is(public.voucher_balance(:'household_id',:'voucher_id'),90000::bigint,'partial refund restores balance');
select throws_ok(format('select public.record_voucher_event(%L,%L,%L,10001,10001,%L,%L,null,%L)',:'household_id','refund',:'voucher_id','2026-09-16','bad',:'use_id'),'22023','refund_limit_exceeded','cumulative refund cannot exceed original');
select throws_ok(format('select public.record_voucher_event(%L,%L,%L,1,1,%L,%L)',:'household_id','voucher_use',:'voucher_id','2026-09-14','bad'),'22023','insufficient_balance','backdated use cannot precede funding');
select throws_ok(format('select public.set_card_target(%L,%L,%L,100000)',:'household_id','90000000-0000-0000-0000-000000000099','2026-09-01'),'22023','card_invalid','missing card target rejected');
select * from finish();
rollback;
