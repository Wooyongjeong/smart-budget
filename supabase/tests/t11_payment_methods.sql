begin;
select plan(4);

select ok(has_function_privilege(
  'authenticated',
  'public.archive_payment_method(uuid, uuid)',
  'execute'
), 'authenticated can archive payment methods');

select ok(has_function_privilege(
  'authenticated',
  'public.create_household(text, text)',
  'execute'
), 'authenticated can create households');

select ok(has_function_privilege(
  'authenticated',
  'public.add_payment_method(uuid, text, text, uuid)',
  'execute'
), 'authenticated can add payment methods');

select ok(not has_table_privilege(
  'authenticated',
  'public.payment_methods',
  'insert'
), 'authenticated cannot directly insert payment methods');

select * from finish();
rollback;
