#!/usr/bin/env bash
# update-cache.sh — Appends today's total repo count to the rolling 31-day
# cache used by the PDS landing page chart.
#
# Reads from: PDS_URL (default: http://127.0.0.1:3000)
# Writes to:  CACHE_DIR (default: /var/lib/pds-landing/cache)
#
# Deps: curl, jq (injected via pkgs.writeShellApplication in pds.nix)
set -euo pipefail

PDS_URL="${PDS_URL:-http://127.0.0.1:3000}"
CACHE_DIR="${CACHE_DIR:-/var/lib/pds-landing/cache}"
CACHE_FILE="$CACHE_DIR/records.json"
TODAY=$(date -u +%Y-%m-%d)

mkdir -p "$CACHE_DIR"

# ── Load existing data ────────────────────────────────────────────────────────
if [[ -f "$CACHE_FILE" ]]; then
  existing=$(cat "$CACHE_FILE")
else
  existing="[]"
fi

# Skip if today is already recorded (idempotent re-runs)
if echo "$existing" | jq -e --arg d "$TODAY" 'any(.[]; .date == $d)' > /dev/null 2>&1; then
  echo "pds-cache: already recorded for $TODAY, skipping."
  exit 0
fi

# ── Count repos via com.atproto.sync.listRepos (paginated) ───────────────────
total=0
cursor=""
while true; do
  url="$PDS_URL/xrpc/com.atproto.sync.listRepos?limit=1000"
  [[ -n "$cursor" ]] && url+="&cursor=$(printf '%s' "$cursor" | jq -Rr @uri)"

  response=$(curl -sf --max-time 30 "$url")
  batch=$(echo "$response" | jq '.repos | length')
  total=$((total + batch))
  cursor=$(echo "$response" | jq -r '.cursor // ""')
  [[ -z "$cursor" ]] && break
done

# ── Append, sort, trim to last 31 days ───────────────────────────────────────
updated=$(
  echo "$existing" \
  | jq \
      --arg d "$TODAY" \
      --argjson n "$total" \
      '. + [{"date": $d, "count": $n}] | sort_by(.date) | unique_by(.date) | .[-31:]'
)

# Atomic write
tmp=$(mktemp "$CACHE_FILE.XXXXXX")
echo "$updated" > "$tmp"
mv "$tmp" "$CACHE_FILE"

echo "pds-cache: recorded $total repos for $TODAY."
