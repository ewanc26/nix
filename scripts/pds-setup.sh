#!/usr/bin/env bash
# =============================================================================
#  pds-setup.sh — Hands-off pre-deploy PDS setup
#
#  Runs entirely on your macmini/laptop BEFORE the server exists.
#  Idempotent by default; use --force-* flags to redo individual steps.
#
#  Usage:
#    bash ./scripts/pds-setup.sh [flags]
#
#  Flags:
#    --force-settings   Re-prompt for hostname / port / email and repatch pds.nix
#    --force-secrets    Regenerate and re-encrypt pds.env.age
#    --force-tunnel     Delete the existing Cloudflare tunnel and recreate it
#    --force-dns        Re-encrypt credentials and re-patch tunnelId (implies new tunnel)
#    --force-all        All of the above
#    --help             Show this message
#
#  SMTP env shortcut (skip the interactive SMTP prompt):
#    PDS_EMAIL_SMTP_URL=smtps://resend:<key>@smtp.resend.com:465/ \
#    PDS_EMAIL_FROM_ADDRESS=pds@ewancroft.uk \
#    bash ./scripts/pds-setup.sh
# =============================================================================
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────

BOLD=$'\e[1m'; DIM=$'\e[2m'; GREEN=$'\e[32m'
YELLOW=$'\e[33m'; RED=$'\e[31m'; CYAN=$'\e[36m'; RESET=$'\e[0m'

log()    { echo; echo "${BOLD}${CYAN}==> $*${RESET}"; }
ok()     { echo "${GREEN}  ✓${RESET} $*"; }
warn()   { echo "${YELLOW}  ⚠${RESET} $*"; }
skip()   { echo "${DIM}  –${RESET} $*${DIM} (already done — use --force to redo)${RESET}"; }
fail()   { echo "${RED}  ✗${RESET} $*" >&2; exit 1; }
section(){ echo; echo "${BOLD}${YELLOW}  >${RESET} $*"; }

# ── Argument parsing ──────────────────────────────────────────────────────────

FORCE_SETTINGS=false
FORCE_SECRETS=false
FORCE_TUNNEL=false
FORCE_DNS=false

for arg in "$@"; do case "$arg" in
    --force-settings) FORCE_SETTINGS=true ;;
    --force-secrets)  FORCE_SECRETS=true  ;;
    --force-tunnel)   FORCE_TUNNEL=true; FORCE_DNS=true ;;
    --force-dns)      FORCE_DNS=true      ;;
    --force-all)      FORCE_SETTINGS=true; FORCE_SECRETS=true
                      FORCE_TUNNEL=true;   FORCE_DNS=true ;;
    --help|-h)
        sed -n '3,/^# ={10}/p' "$0" | sed 's/^#  \?//' | sed 's/^#$//'
        exit 0 ;;
    *) fail "Unknown flag: $arg (try --help)" ;;
esac; done

# ── Paths & globals ───────────────────────────────────────────────────────────

ROOT="$(git -C "$(dirname "${BASH_SOURCE[0]}")" rev-parse --show-toplevel)"
SETTINGS="$ROOT/settings/config/pds.nix"
SECRETS_FILE="$ROOT/secrets/secrets.nix"
SECRETS_DIR="$ROOT/secrets/age"
AGE_KEY="${AGE_KEY:-$HOME/.config/age/keys.txt}"
CF_DIR="$HOME/.cloudflared"
TUNNEL_NAME="pds"
PLACEHOLDER_UUID="00000000-0000-0000-0000-000000000000"

RAGENIX=(nix run github:yaxitech/ragenix --)

# Encrypt a plaintext file ($1) into a .age file ($2), fully hands-off.
# ragenix calls $EDITOR <tmpfile>; we set EDITOR to "cp $src" so it injects
# our content immediately without opening an interactive editor.
ragenix_encrypt() {
    local src="$1" target="$2"
    rm -f "$target"
    EDITOR="cp $src" "${RAGENIX[@]}" \
        --rules "$SECRETS_FILE" \
        --identity "$AGE_KEY" \
        -e "$target"
}

# Portable in-place sed (handles macOS BSD sed vs GNU sed).
sedi() { if [[ "$(uname -s)" == Darwin ]]; then sed -i '' "$@"; else sed -i "$@"; fi; }

# Read a value from pds.nix by key name. Works for quoted strings and integers.
read_setting() {
    local key="$1"
    grep "${key}\s*=" "$SETTINGS" | grep -o '"[^"]*"\|[0-9]\+' | head -1 | tr -d '"'
}

# Send a test email via Resend API
# Args: $1=API_KEY, $2=FROM_ADDRESS, $3=TO_ADDRESS
send_test_email() {
    local api_key="$1" from="$2" to="$3"
    
    local response
    response=$(curl -s -X POST 'https://api.resend.com/emails' \
        -H "Authorization: Bearer ${api_key}" \
        -H 'Content-Type: application/json' \
        -d "{
            \"from\": \"${from}\",
            \"to\": [\"${to}\"],
            \"subject\": \"PDS Setup Complete! 🎉\",
            \"html\": \"<h2>Your PDS is ready to deploy!</h2><p>SMTP email is working correctly. You can now proceed with deployment.</p><p><strong>Next steps:</strong></p><ul><li>Commit your changes</li><li>Deploy to your server</li><li>Add DNS records</li></ul>\"
        }" 2>&1)
    
    if echo "$response" | grep -q '"id"'; then
        ok "Test email sent to $to"
    else
        warn "Test email failed: $response"
    fi
}

# ── Step 1: Prerequisites ─────────────────────────────────────────────────────

log "Step 1/9 — Prerequisites"

missing=()
for cmd in openssl nix git curl; do command -v "$cmd" &>/dev/null || missing+=("$cmd"); done
(( ${#missing[@]} == 0 )) || fail "Missing commands: ${missing[*]}"

if command -v cloudflared &>/dev/null; then
    CLOUDFLARED=(cloudflared)
    ok "cloudflared: $(command -v cloudflared)"
else
    warn "cloudflared not in PATH — using nix run nixpkgs#cloudflared"
    CLOUDFLARED=(nix run nixpkgs#cloudflared --)
fi

[[ -f "$AGE_KEY" ]] || fail "No age key at $AGE_KEY — run secrets/setup.sh first"
ok "age key: $AGE_KEY"

# ── Step 2: PDS settings ──────────────────────────────────────────────────────

log "Step 2/9 — PDS settings"

# Read current values from settings/config/pds.nix
CUR_HOSTNAME=$(read_setting hostname)
CUR_PORT=$(read_setting 'port' | grep -v caddy || true)
# port line is "  port = 3000;" — pick the first bare number not on a caddyPort line
CUR_PORT=$(grep -v 'caddy\|Caddy' "$SETTINGS" \
    | grep 'port\s*=' | grep -o '[0-9]\+' | head -1)
CUR_EMAIL=$(read_setting adminEmail)

if ! $FORCE_SETTINGS; then
    skip "Using existing settings (hostname=$CUR_HOSTNAME port=$CUR_PORT email=$CUR_EMAIL)"
else
    section "Leave a field blank to keep the current value shown in [brackets]."
    echo

    read -rp "  PDS hostname  [${CUR_HOSTNAME}]: " NEW_HOSTNAME
    read -rp "  PDS port      [${CUR_PORT}]:     " NEW_PORT
    read -rp "  Admin email   [${CUR_EMAIL}]:    " NEW_EMAIL

    NEW_HOSTNAME="${NEW_HOSTNAME:-$CUR_HOSTNAME}"
    NEW_PORT="${NEW_PORT:-$CUR_PORT}"
    NEW_EMAIL="${NEW_EMAIL:-$CUR_EMAIL}"

    # Validate port is numeric
    [[ "$NEW_PORT" =~ ^[0-9]+$ ]] || fail "Port must be a number, got: $NEW_PORT"

    # Patch settings/config/pds.nix
    sedi "s|hostname\s*=\s*\"[^\"]*\"|hostname = \"${NEW_HOSTNAME}\"|"    "$SETTINGS"
    sedi "s|adminEmail\s*=\s*\"[^\"]*\"|adminEmail = \"${NEW_EMAIL}\"|"   "$SETTINGS"
    # Port is a bare integer; match the specific line (not caddyPort)
    sedi "/caddyPort/! s|\(port\s*=\s*\)[0-9]\+|\1${NEW_PORT}|"           "$SETTINGS"

    CUR_HOSTNAME="$NEW_HOSTNAME"
    CUR_PORT="$NEW_PORT"
    CUR_EMAIL="$NEW_EMAIL"

    ok "Patched: hostname=$CUR_HOSTNAME port=$CUR_PORT email=$CUR_EMAIL"
fi

# ── SMTP (optional; read from env or prompt once) ─────────────────────────────

SMTP_URL="${PDS_EMAIL_SMTP_URL:-}"
SMTP_FROM="${PDS_EMAIL_FROM_ADDRESS:-}"

if [[ -z "$SMTP_URL" ]]; then
    echo
    warn "SMTP is optional but required for password resets and email verification."
    warn "Easiest: Resend (https://resend.com) — free tier is plenty for a personal PDS."
    warn "Skip with Enter, or pre-set via env to suppress this prompt entirely:"
    warn "  PDS_EMAIL_SMTP_URL=... PDS_EMAIL_FROM_ADDRESS=... bash $0"
    echo
    read -rp "  SMTP URL     (blank to skip): " SMTP_URL
    [[ -n "$SMTP_URL" ]] && read -rp "  FROM address (blank to skip): " SMTP_FROM
fi

if [[ -n "$SMTP_URL" ]]; then
    ok "SMTP: $SMTP_FROM via $SMTP_URL"
    
    # Send test email if using Resend
    if [[ "$SMTP_URL" == *"resend"* ]]; then
        # Extract API key from SMTP URL: smtps://resend:<API_KEY>@smtp.resend.com:465/
        RESEND_API_KEY=$(echo "$SMTP_URL" | sed -n 's|.*resend:\([^@]*\)@.*|\1|p')
        
        if [[ -n "$RESEND_API_KEY" ]] && [[ -n "$SMTP_FROM" ]] && [[ -n "$CUR_EMAIL" ]]; then
            echo
            section "Sending test email..."
            send_test_email "$RESEND_API_KEY" "$SMTP_FROM" "$CUR_EMAIL"
        fi
    fi
else
    warn "SMTP skipped"
fi

# ── Step 3: PDS runtime secrets ───────────────────────────────────────────────

log "Step 3/9 — PDS runtime secrets (pds.env.age)"

PDS_ENV_AGE="$SECRETS_DIR/pds.env.age"
IS_REAL_AGE=false
[[ -f "$PDS_ENV_AGE" ]] && head -1 "$PDS_ENV_AGE" | grep -q "^age-encryption.org" \
    && IS_REAL_AGE=true

if $IS_REAL_AGE && ! $FORCE_SECRETS; then
    skip "pds.env.age"
else
    $FORCE_SECRETS && $IS_REAL_AGE && warn "Regenerating secrets as requested (--force-secrets)"
    ! $IS_REAL_AGE && [[ -f "$PDS_ENV_AGE" ]] \
        && warn "pds.env.age exists but is not valid age ciphertext — replacing"

    JWT_SECRET=$(openssl rand --hex 16)
    ADMIN_PASSWORD=$(openssl rand --hex 16)
    ROTATION_KEY=$(openssl ecparam --name secp256k1 --genkey --noout --outform DER \
        | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32)

    TMPENV=$(mktemp); chmod 600 "$TMPENV"
    trap 'rm -f "$TMPENV"' EXIT

    {
        echo "PDS_JWT_SECRET=${JWT_SECRET}"
        echo "PDS_ADMIN_PASSWORD=${ADMIN_PASSWORD}"
        echo "PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=${ROTATION_KEY}"
        [[ -n "$SMTP_URL"  ]] && echo "PDS_EMAIL_SMTP_URL=${SMTP_URL}"
        [[ -n "$SMTP_FROM" ]] && echo "PDS_EMAIL_FROM_ADDRESS=${SMTP_FROM}"
    } > "$TMPENV"

    ragenix_encrypt "$TMPENV" "$PDS_ENV_AGE"
    rm -f "$TMPENV"; trap - EXIT

    ok "pds.env.age encrypted"
    echo
    echo "  ${BOLD}Save these — they cannot be recovered from the encrypted file:${RESET}"
    printf "  %-52s %s\n" "PDS_JWT_SECRET:"                           "$JWT_SECRET"
    printf "  %-52s %s\n" "PDS_ADMIN_PASSWORD:"                       "$ADMIN_PASSWORD"
    printf "  %-52s\n"    "PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX:"
    printf "    %s\n"                                                   "$ROTATION_KEY"
fi

# ── Step 4: Cloudflare authentication ─────────────────────────────────────────

log "Step 4/9 — Cloudflare authentication"

if [[ -f "$CF_DIR/cert.pem" ]] && ! $FORCE_TUNNEL; then
    ok "Already authenticated ($CF_DIR/cert.pem exists)"
else
    $FORCE_TUNNEL && warn "Re-authenticating (--force-tunnel)"
    warn "A browser window will open — this only happens once."
    "${CLOUDFLARED[@]}" tunnel login
    ok "Authenticated"
fi

# ── Step 5: Cloudflare tunnel ─────────────────────────────────────────────────

log "Step 5/9 — Cloudflare tunnel"

TUNNEL_UUID=""

# Check for an existing tunnel with this name
EXISTING_UUID=$("${CLOUDFLARED[@]}" tunnel list 2>/dev/null \
    | awk -v n="$TUNNEL_NAME" '$2 == n {print $1; exit}' || true)

if [[ -n "$EXISTING_UUID" ]] && $FORCE_TUNNEL; then
    warn "Deleting existing tunnel $EXISTING_UUID (--force-tunnel)"
    "${CLOUDFLARED[@]}" tunnel delete --force "$EXISTING_UUID"
    EXISTING_UUID=""
fi

if [[ -n "$EXISTING_UUID" ]]; then
    TUNNEL_UUID="$EXISTING_UUID"
    ok "Using existing tunnel: $TUNNEL_UUID"
else
    CREATE_OUTPUT=$("${CLOUDFLARED[@]}" tunnel create "$TUNNEL_NAME" 2>&1)
    echo "$CREATE_OUTPUT"
    TUNNEL_UUID=$(echo "$CREATE_OUTPUT" \
        | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
        | head -1)
    [[ -n "$TUNNEL_UUID" ]] || fail "Could not extract UUID from cloudflared output"
    ok "Tunnel created: $TUNNEL_UUID"
fi

TUNNEL_CREDS="$CF_DIR/$TUNNEL_UUID.json"
[[ -f "$TUNNEL_CREDS" ]] || fail "Credentials file missing: $TUNNEL_CREDS"

# ── Step 6: Patch tunnelId into pds.nix ───────────────────────────────────────

log "Step 6/9 — Patch tunnelId in settings/config/pds.nix"

CURRENT_UUID=$(read_setting tunnelId)

if [[ "$CURRENT_UUID" == "$TUNNEL_UUID" ]]; then
    ok "tunnelId already correct"
else
    sedi "s|tunnelId = \"${CURRENT_UUID}\"|tunnelId = \"${TUNNEL_UUID}\"|" "$SETTINGS"
    ok "Patched: $CURRENT_UUID → $TUNNEL_UUID"
fi

# ── Step 7: Encrypt tunnel credentials ───────────────────────────────────────

log "Step 7/9 — Encrypt tunnel credentials (cf-tunnel-pds.json.age)"

CF_AGE="$SECRETS_DIR/cf-tunnel-pds.json.age"
IS_REAL_CF_AGE=false
[[ -f "$CF_AGE" ]] && head -1 "$CF_AGE" | grep -q "^age-encryption.org" \
    && IS_REAL_CF_AGE=true

if $IS_REAL_CF_AGE && ! $FORCE_DNS; then
    skip "cf-tunnel-pds.json.age"
else
    $FORCE_DNS && $IS_REAL_CF_AGE && warn "Re-encrypting credentials (--force-dns)"
    ! $IS_REAL_CF_AGE && [[ -f "$CF_AGE" ]] \
        && warn "cf-tunnel-pds.json.age is a placeholder — replacing"
    ragenix_encrypt "$TUNNEL_CREDS" "$CF_AGE"
    ok "cf-tunnel-pds.json.age encrypted"
fi

# Remove plaintext credentials now they're encrypted in the repo.
rm -f "$TUNNEL_CREDS"
ok "Removed plaintext $TUNNEL_CREDS"

# ── Step 8: DNS ───────────────────────────────────────────────────────────────

log "Step 8/9 — DNS records"

HANDLE_DOMAINS=$(grep -A10 'serviceHandleDomains' "$SETTINGS" \
    | grep -B10 '];' | head -n-1 \
    | grep -o '"[^"]*"' | tr -d '"' | sed 's/^\.//' || true)

echo
echo "  Add these CNAMEs in Cloudflare DNS (Proxied ✓):"
echo
printf "  ${BOLD}%-45s %s${RESET}\n" "Name" "Target"
printf "  %-45s %s\n" "$CUR_HOSTNAME" "${TUNNEL_UUID}.cfargotunnel.com"
for domain in $HANDLE_DOMAINS; do
    printf "  %-45s %s\n" "*.${domain}" "${TUNNEL_UUID}.cfargotunnel.com"
done
echo
echo "  Or add automatically via the API:"
echo "    ${CLOUDFLARED[*]} tunnel route dns $TUNNEL_NAME $CUR_HOSTNAME"
for domain in $HANDLE_DOMAINS; do
    echo "    ${CLOUDFLARED[*]} tunnel route dns $TUNNEL_NAME '*.${domain}'"
done

# ── Step 9: Rekey ─────────────────────────────────────────────────────────────

log "Step 9/9 — Rekey secrets"

AGE_COUNT=$(find "$SECRETS_DIR" -name "*.age" \
    -exec grep -l "^age-encryption.org" {} \; 2>/dev/null | wc -l | tr -d ' ')

if (( AGE_COUNT > 0 )); then
    "${RAGENIX[@]}" --rules "$SECRETS_FILE" --identity "$AGE_KEY" -r
    ok "Rekeyed $AGE_COUNT secrets"
else
    warn "No encrypted .age files to rekey"
fi

# ── Done ──────────────────────────────────────────────────────────────────────

echo
echo "${BOLD}${GREEN}══════════════════════════════════════════════${RESET}"
echo "${BOLD}${GREEN}  Done.${RESET}"
echo "${BOLD}${GREEN}══════════════════════════════════════════════${RESET}"
echo
echo "  ${CYAN}git add settings/config/pds.nix secrets/${RESET}"
echo "  ${CYAN}git commit -m 'pds: pre-deploy setup (tunnel ${TUNNEL_UUID})'${RESET}"
echo "  ${CYAN}git push${RESET}"
echo
echo "  ${BOLD}Still needed on deploy day:${RESET}"
echo "  1. Generate hardware config → hosts/server/minimal-hardware.nix"
echo "  2. Get server age key:"
echo "     ${CYAN}nix-shell -p ssh-to-age --run 'cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age'${RESET}"
echo "  3. Add to secrets/secrets.nix → systems.server, update pdsKeys"
echo "  4. Rekey: ${CYAN}nix run github:yaxitech/ragenix -- --rules secrets/secrets.nix -r${RESET}"
echo "  5. ${CYAN}nixos-install --flake .#server && reboot${RESET}"
echo "  6. ${CYAN}curl https://${CUR_HOSTNAME}/xrpc/_health${RESET}"
echo
