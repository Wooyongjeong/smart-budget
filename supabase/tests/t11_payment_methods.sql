begin;
select plan(4);

select has_function_privilege(
  'authenticated',
  'public.archive_payment_method(uuid, uuid)',
  'execute'
);

select has_function_privilege(
  'authenticated',
  'public.create_household(text, text)',
  'execute'
);

select has_function_privilege(
  'authenticated',
  'public.add_payment_method(uuid, text, text, uuid)',
  'execute'
);

select has_table_privilege(
  'authenticated',
  'public.payment_methods',
  'insert'
) is false;

select * from finish();
rollback;
