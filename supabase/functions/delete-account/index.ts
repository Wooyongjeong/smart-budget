import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ code: 'method_not_allowed' }, 405);

  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return json({ code: 'unauthorized' }, 401);

  const url = Deno.env.get('SUPABASE_URL');
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !publishableKey || !serviceKey) {
    return json({ code: 'server_unavailable' }, 503);
  }

  const userClient = createClient(url, publishableKey);
  const { data: { user }, error: userError } = await userClient.auth.getUser(token);
  if (userError || !user) return json({ code: 'unauthorized' }, 401);

  const admin = createClient(url, serviceKey);
  const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
  if (deleteError) return json({ code: 'delete_failed' }, 500);

  return json({ deleted: true }, 200);
});
