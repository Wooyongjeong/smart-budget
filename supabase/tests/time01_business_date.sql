begin;
select plan(4);

select ok(
  position(
    'Asia/Seoul' in pg_get_functiondef(
      'public.consume_receipt_analysis_quota(uuid)'::regprocedure
    )
  ) > 0,
  'receipt quota uses the Seoul business date'
);

select ok(
  position(
    'current_date' in lower(pg_get_functiondef(
      'public.add_voucher_with_initial_topup(uuid,text,uuid,bigint,bigint,uuid,text,uuid,uuid)'::regprocedure
    ))
  ) = 0,
  'voucher onboarding no longer depends on the Postgres session date'
);

select ok(
  position(
    'Asia/Seoul' in pg_get_functiondef(
      'public.add_voucher_with_initial_topup(uuid,text,uuid,bigint,bigint,uuid,text,uuid,uuid)'::regprocedure
    )
  ) > 0,
  'voucher onboarding uses the Seoul business date'
);

select like(
  pg_get_expr(d.adbin, d.adrelid),
  '%Asia/Seoul%',
  'receipt quota default uses the Seoul business date'
)
from pg_attrdef d
join pg_class c on c.oid = d.adrelid
join pg_namespace n on n.oid = c.relnamespace
join pg_attribute a on a.attrelid = c.oid and a.attnum = d.adnum
where n.nspname = 'public'
  and c.relname = 'receipt_analysis_usage'
  and a.attname = 'usage_date';

select * from finish();
rollback;
