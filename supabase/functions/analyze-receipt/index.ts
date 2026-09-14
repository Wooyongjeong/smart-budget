import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const MAX_BYTES = 10 * 1024 * 1024;
const MAX_ITEMS = 50;
const ALLOWED_TYPES = new Set(['image/jpeg', 'image/png']);
const TYPES = new Set(['income', 'expense', 'refund', 'voucher_topup', 'voucher_use', 'unknown']);

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
    const amount = row.amount === null || row.amount === undefined ? null : Number.isSafeInteger(row.amount) ? row.amount : invalid('invalid_amount');
    const date = row.date === null || row.date === undefined ? null : typeof row.date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(row.date) ? row.date : invalid('invalid_date');
    const text = (key: string) => row[key] === null || row[key] === undefined ? null : typeof row[key] === 'string' && row[key].length <= 200 ? row[key] : invalid(`invalid_${key}`);
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

Deno.serve(async (request) => {
  if (request.method !== 'POST') return json({ code: 'method_not_allowed' }, 405);
  const token = request.headers.get('authorization')?.replace(/^Bearer\s+/i, '');
  if (!token) return json({ code: 'unauthorized' }, 401);
  const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_ANON_KEY')!, { global: { headers: { Authorization: `Bearer ${token}` } } });
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return json({ code: 'unauthorized' }, 401);
  const type = request.headers.get('content-type') ?? '';
  if (!ALLOWED_TYPES.has(type)) return json({ code: 'validation_failed', field: 'content_type' }, 415);
  const bytes = new Uint8Array(await request.arrayBuffer());
  if (bytes.byteLength === 0 || bytes.byteLength > MAX_BYTES) return json({ code: 'validation_failed', field: 'image_size' }, 413);
  const endpoint = Deno.env.get('RECEIPT_AI_ENDPOINT');
  const apiKey = Deno.env.get('RECEIPT_AI_API_KEY');
  if (!endpoint || !apiKey) return json({ code: 'provider_not_configured' }, 503);
  try {
    const provider = await fetch(endpoint, { method: 'POST', headers: { authorization: `Bearer ${apiKey}`, 'content-type': 'application/json' }, body: JSON.stringify({ mime_type: type, image_base64: base64(bytes) }) });
    if (!provider.ok) return json({ code: 'provider_error' }, 502);
    const items = validateItems(await provider.json());
    return json({ draft_id: crypto.randomUUID(), items });
  } catch (error) {
    return json({ code: error instanceof Error && error.message.startsWith('invalid_') ? 'validation_failed' : 'provider_error' }, 502);
  }
});
