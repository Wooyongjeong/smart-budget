-- Only the idempotent nine-argument onboarding contract may be called by clients.
-- Keep the older overload for migration history, but remove its client grant.
revoke all on function public.add_voucher_with_initial_topup(uuid,text,uuid,bigint,bigint,uuid)
  from public, anon, authenticated;
