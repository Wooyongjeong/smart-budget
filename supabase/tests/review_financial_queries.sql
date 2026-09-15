begin;
select plan(4);
insert into auth.users(id) values ('90000000-0000-0000-0000-000000000001');
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000001',true);
set local role authenticated;
select public.create_household('review') as household_id \gset
select public.add_card_payment_method(:'household_id','credit_card','review card') as card_id \gset
select public.add_payment_method(:'household_id','voucher','review voucher') as voucher_id \gset
select public.set_card_target(:'household_id',:'card_id','2026-09-01',300000);
select is((public.card_performance(:'household_id','2026-09-01')->0->>'target_amount_won')::bigint,300000::bigint,'real RPC returns card target');
select public.record_voucher_event(:'household_id','voucher_topup',:'voucher_id',93000,100000,'2026-09-15','review topup',:'card_id');
select public.record_voucher_event(:'household_id','voucher_use',:'voucher_id',20000,20000,'2026-09-15','review use');
select is((public.query_transactions(:'household_id','2026-09-01','2026-10-01')->>'total_expense')::bigint,93000::bigint,'discounted topup expense counted once');
select is((public.card_performance(:'household_id','2026-09-01')->0->>'actual_amount_won')::bigint,93000::bigint,'card topup counts actual payment');
select is((select sum(delta_won)::bigint from public.voucher_movements where voucher_id=:'voucher_id'),80000::bigint,'use leaves face balance 80000');
select * from finish();
rollback;
