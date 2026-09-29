#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: bash tool/run_configured.sh DEVICE_ID [flutter run options]" >&2
  exit 2
fi
device_id="$1"
shift

config_file=".env.json"
if [[ ! -f "$config_file" ]]; then
  echo "Missing .env.json" >&2
  exit 2
fi

# Never pass the entire local file to dart-define: it may contain server keys.
supabase_url="$(jq -er '.SUPABASE_URL // empty' "$config_file")"
supabase_key="$(jq -er '.SUPABASE_PUBLISHABLE_KEY // empty' "$config_file")"
redirect_url="$(jq -er '.AUTH_REDIRECT_URL // empty' "$config_file")"

exec flutter run -d "$device_id" \
  --dart-define="SUPABASE_URL=$supabase_url" \
  --dart-define="SUPABASE_PUBLISHABLE_KEY=$supabase_key" \
  --dart-define="AUTH_REDIRECT_URL=$redirect_url" \
  "$@"
