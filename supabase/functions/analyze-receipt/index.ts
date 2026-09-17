import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const MAX_BYTES = 10 * 1024 * 1024;
const MAX_ITEMS = 50;
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png']);
const TYPES = new Set(['income', 'expense', 'refund', 'voucher_topup', 'voucher_use', 'unknown']);
const MODEL = Deno.env.get('OPENROUTER_MODEL') ?? 'inclusionai/ling-3.0-flash-vl:free';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

function invalid(message: string): never {
  throw new Error(message);
}

function validateItems(value: unknown) {
  if (!value || typeof value !== 'object' || !Array.isArray((value as { items?: unknown }).items)) invalid('invalid_provider_response');
  const items = (value as { items: unknown[] }).items;
  if (items.length > MAX_ITEMS) invalid('too_many_items');
  return items.map((item) => {
    if (!item || typeof item !== 'object') invalid('invalid_item');
    const row = item as Record<string, unknown>;
    const suggestedType = typeof row.suggested_type === 'string' && TYPES.has(row.suggested_type) ? row.suggested_type : 'unknown';
    const amount = row.amount === null || row.amount === undefined ? null : Number.isSafeInteger(row.amount) && Number(row.amount) > 0 ? Number(row.amount) : invalid('invalid_amount');
    const date = row.date === null || row.date === undefined ? null : typeof row.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(row.date) ? row.date : invalid('invalid_date');
    const text = (key: string) => row[key] === null || row[key] === undefined ? null : typeof row[key] === 'string' && row[key].trim().length <= 200 ? row[key].trim() : invalid(`invalid_${key}`);
    const reasons = Array.isArray(row.review_reasons) && row.review_reasons.every((reason) => typeof reason === 'string' && reason.length <= 200) ? row.review_reasons : [];
    return { date, merchant: text('merchant'), amount, suggested_type: suggestedType, payment_hint: text('payment_hint'), category_hint: text('category_hint'), review_reasons: reasons };
  });
}

function base64(bytes: Uint8Array) {
  let binary = '';
  const chunk = 0x8000;
  for (let index = 0; index < bytes.length; index += chunk) {
    binary += String.fromCharCode(...bytes.subarray(index, Math.min(index + chunk, bytes.length)));
  }
  return btoa(binary);
}

function parseContent(content: unknown) {
  if (typeof content !== 'string') invalid('invalid_provider_response');
  const cleaned = content.trim().replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/, '');
  try {
    return validateItems(JSON.parse(cleaned));
  } catch (_) {
    invalid('invalid_provider_response');
  }
}

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ code: 'method_not_allowed' }, 405);
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  const householdId = request.headers.get('x-household-id');
  if (!token) return json({ code: 'unauthorized' }, 401);
  if (!householdId) return json({ code: 'validation_failed', field: 'household_id' }, 400);
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: `Bearer ${token}` } } });
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return json({ code: 'unauthorized' }, 401);
  const { data: membership, error: membershipError } = await supabase
    .from('household_members')
    .select('id')
    .eq('household_id', householdId)
    .eq('user_id', user.id)
    .is('left_at', null)
    .maybeSingle();
  if (membershipError || !membership) return json({ code: 'forbidden' }, 403);
  const type = request.headers.get('content-type') ?? '';
  if (!ALLOWED_TYPES.has(type)) return json({ code: 'validation_failed', field: 'content_type' }, 415);
  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength === 0 || bytes.byteLength > MAX_BYTES) return json({ code: 'validation_failed', field: 'image_size' }, 413);
  const apiKey = Deno.env.get('OPENROUTER_API_KEY');
  if (!apiKey) return json({ code: 'provider_not_configured' }, 503);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30_000);
  try {
    const provider = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: { authorization: `Bearer ${apiKey}`, 'content-type': 'application/json', 'http-referer': 'https://github.com/Wooyongjeong/smart-budget', 'x-title': 'smart-budget' },
      signal: controller.signal,
      body: JSON.stringify({
        model: MODEL,
        temperature: 0,
        max_tokens: 2000,
        reasoning: { exclude: true },
        messages: [{ role: 'user', content: [
          { type: 'text', text: 'Extract actual purchase rows only. Exclude totals, balances, and clipped rows. Read date as YYYY-MM-DD when the year is visible, otherwise null. Keep merchant and payment card hint separate. Use positive integer won amounts. Classify canceled rows as refund and uncertain rows as unknown. Return only JSON in this shape: {"items":[{"date":null,"merchant":null,"amount":null,"suggested_type":"expense|refund|unknown","payment_hint":null,"category_hint":null,"review_reasons":[]}]}' },
          { type: 'image_url', image_url: { url: `data:${type};base64,${base64(bytes)}` } },
        ] }],
      }),
    });
    if (!provider.ok) return json({ code: provider.status === 429 ? 'rate_limited' : 'provider_error' }, provider.status === 429 ? 429 : 502);
    const body = await provider.json();
    const items = parseContent(body?.choices?.[0]?.message?.content);
    return json({ draft_id: crypto.randomUUID(), items });
  } catch (error) {
    if (error instanceof DOMException && error.name === 'AbortError') {
      return json({ code: 'timeout' }, 502);
    }
    if (error instanceof Error && (error.message.startsWith('invalid_') || error.message === 'too_many_items')) {
      return json({ code: 'validation_failed' }, 502);
    }
    return json({ code: 'provider_error' }, 502);
  } finally {
    clearTimeout(timeout);
  }
});
