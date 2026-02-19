#!/usr/bin/env bash
################################################################################
# pds-matrix-setup.sh — PDS + Matrix + Cloudflare tunnel initial setup
#
# NOTE: Secret generation has moved to secrets/setup.sh, which handles all
# seven encrypted secrets (pds.env, matrix.env, forgejo.env, cf-tunnel.json,
# docker-config.json, claude.json, duckdns.tar.gz) in one place.
#
# This script now focuses on the post-secret steps: Cloudflare DNS records
# and Matrix .well-known delegation. Run secrets/setup.sh first.
#
# Prerequisites:
#   - age key at ~/.config/age/keys.txt  (run: age-keygen -o ~/.config/age/keys.txt)
#   - secrets/setup.sh already run (all secrets encrypted)
#   - cloudflared, jq, curl in PATH (or installable via nix run)
#
# Usage:
#   ./scripts/pds-matrix-setup.sh             # full run
#   ./scripts/pds-matrix-setup.sh --resume    # skip steps whose output files exist
#   ./scripts/pds-matrix-setup.sh --force-tunnel  # delete + recreate CF tunnel
################################################################################
set -euo pipefail

# ── Colour helpers ─────────────────────────────────────────────────────────────
BOLD=$'\e[1m'; DIM=$'\e[2m'; GREEN=$'\e[32m'
YELLOW=$'\e[33m'; RED=$'\e[31m'; CYAN=$'\e[36m'; RESET=$'\e[0m'
NC=$RESET

log()  { echo; echo "${BOLD}${CYAN}==> $*${RESET}"; }
ok()   { echo "${GREEN}  ✓${RESET} $*"; }
warn() { echo "${YELLOW}  ⚠${RESET} $*"; }
fail() { echo "${RED}  ✗${RESET} $*" >&2; exit 1; }

# ── Configuration ──────────────────────────────────────────────────────────────
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$HOME/.config/nix-config")"
SECRETS_DIR="$ROOT/secrets"
AGE_KEY="$HOME/.config/age/keys.txt"
WEBSITE_DIR="$HOME/Developer/Git/GitHub/ewanc26/website"
DOMAIN="ewancroft.uk"

# sops needs to find the age private key for decryption.
# The public key is already in .sops.yaml for encryption.
export SOPS_AGE_KEY_FILE="$AGE_KEY"

# Flags
RESUME=false
FORCE_TUNNEL=false
for arg in "$@"; do case "$arg" in
    --resume)       RESUME=true ;;
    --force-tunnel) FORCE_TUNNEL=true ;;
esac; done

# ── Helpers ────────────────────────────────────────────────────────────────────
run_cmd() {
    local cmd="$1"; shift
    if command -v "$cmd" &>/dev/null; then
        "$cmd" "$@"
    else
        case "$cmd" in
            cloudflared) nix run nixpkgs#cloudflared -- "$@" ;;
            pwgen)       nix run nixpkgs#pwgen       -- "$@" ;;
            sops)        nix run nixpkgs#sops         -- "$@" ;;
            *)           fail "Command '$cmd' not found and no nix fallback configured." ;;
        esac
    fi
}

sops_encrypt_binary() {
    # Encrypt a plaintext file as a sops binary secret.
    # Usage: sops_encrypt_binary <plaintext-tmpfile> <output-secrets-path>
    local src="$1" dst="$2"
    # sops matches creation rules against the *input* file path, not --output.
    # So we copy the plaintext to the destination path and encrypt in-place,
    # ensuring the path matches a creation_rule in .sops.yaml.
    cd "$ROOT"
    cp "$src" "$dst"
    run_cmd sops --encrypt --input-type binary --output-type binary \
        --in-place "$dst"
    ok "Encrypted → $dst"
}

# ── Step 0: Cloudflare credentials ─────────────────────────────────────────────
# The CF token is stored encrypted as secrets/cloudflare.token (binary sops secret).
load_cf_creds() {
    log "Step 0: Cloudflare credentials"
    local token_file="$SECRETS_DIR/cloudflare.token"

    if [[ -f "$token_file" ]]; then
        ok "Found encrypted credentials at $token_file"
        local decrypted
        decrypted=$(run_cmd sops --decrypt --input-type binary --output-type binary "$token_file")
        export CF_TOKEN=$(echo "$decrypted" | awk '{print $1}')
        export CF_ZONE=$(echo  "$decrypted" | awk '{print $2}')
    else
        warn "No cloudflare.token secret found — prompting for credentials."
        read -rp "  Enter CF API Token: " CF_TOKEN
        read -rp "  Enter CF Zone ID:   " CF_ZONE
        export CF_TOKEN CF_ZONE

        # Encrypt and store
        local tmp
        tmp=$(mktemp)
        echo "$CF_TOKEN $CF_ZONE" > "$tmp"
        sops_encrypt_binary "$tmp" "$SECRETS_DIR/cloudflare.token"
        rm "$tmp"
    fi
    ok "Cloudflare credentials loaded."
}

# ── Step 1: PDS secrets ────────────────────────────────────────────────────────
step_pds_secrets() {
    log "Step 1: PDS secrets (secrets/pds.env)"
    local dst="$SECRETS_DIR/pds.env"
    if [[ -f "$dst" ]] && [[ "$RESUME" == true ]]; then ok "Skipping (exists)"; return 0; fi

    local jwt admin tmp
    jwt=$(openssl rand --hex 16)
    admin=$(openssl rand --hex 16)

    tmp=$(mktemp)
    printf "PDS_JWT_SECRET=%s\nPDS_ADMIN_PASSWORD=%s\n" "$jwt" "$admin" > "$tmp"
    sops_encrypt_binary "$tmp" "$dst"
    rm "$tmp"

    ok "PDS secrets encrypted.  Admin password: ${BOLD}${admin}${RESET}  (save this!)"
}

# ── Step 2: Matrix secrets ─────────────────────────────────────────────────────
step_matrix_secrets() {
    log "Step 2: Matrix secrets (secrets/matrix.env)"
    local dst="$SECRETS_DIR/matrix.env"
    if [[ -f "$dst" ]] && [[ "$RESUME" == true ]]; then ok "Skipping (exists)"; return 0; fi

    local reg mac tmp
    reg=$(run_cmd pwgen -s 64 1)
    mac=$(run_cmd pwgen -s 64 1)

    tmp=$(mktemp)
    printf "REGISTRATION_SHARED_SECRET=%s\nMACAROON_SECRET_KEY=%s\n" "$reg" "$mac" > "$tmp"
    sops_encrypt_binary "$tmp" "$dst"
    rm "$tmp"

    ok "Matrix secrets encrypted."
}

# ── Step 3: Cloudflare tunnel ──────────────────────────────────────────────────
step_tunnel() {
    log "Step 3: Cloudflare tunnel (shared for all services)"
    local dst="$SECRETS_DIR/cf-tunnel.json"

    local uuid
    uuid=$(run_cmd cloudflared tunnel list 2>/dev/null | awk '/server/{print $1}' || true)

    if [[ -z "$uuid" ]] || [[ "$FORCE_TUNNEL" == true ]]; then
        if [[ -n "$uuid" ]]; then
            warn "Deleting existing 'server' tunnel: $uuid"
            run_cmd cloudflared tunnel delete -f "$uuid" || true
        fi
        log "Creating new tunnel 'server'…"
        local output
        output=$(run_cmd cloudflared tunnel create server 2>&1)
        uuid=$(echo "$output" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
        [[ -n "$uuid" ]] || fail "Could not parse tunnel UUID from cloudflared output."
    fi

    local creds="$HOME/.cloudflared/$uuid.json"
    if [[ -f "$creds" ]]; then
        sops_encrypt_binary "$creds" "$dst"
        ok "Tunnel credentials encrypted → $dst"
    else
        warn "Credentials file $creds not found — did cloudflared tunnel create succeed?"
    fi

    # Update tunnelId default in modules/options.nix
    local opts="$ROOT/modules/options.nix"
    if [[ -f "$opts" ]]; then
        # Use Python for cross-platform DOTALL regex — BSD sed can't handle '}' in
        # range-end addresses, and the tunnelId block spans multiple lines.
        python3 - "$opts" "$uuid" <<'PYEOF'
import re, sys
path, uuid = sys.argv[1], sys.argv[2]
text = open(path).read()
text = re.sub(
    r'(tunnelId[^}]*?default\s*=\s*")[^"]*(")',
    lambda m: m.group(1) + uuid + m.group(2),
    text,
    flags=re.DOTALL
)
open(path, 'w').write(text)
PYEOF
        ok "Updated tunnelId in modules/options.nix → $uuid"
    fi

    export TUNNEL_UUID="$uuid"
    ok "Tunnel UUID: $uuid"
}

# ── Step 4: DNS records ────────────────────────────────────────────────────────
step_dns() {
    log "Step 4: Cloudflare DNS CNAME records (upsert)"
    local target="$TUNNEL_UUID.cfargotunnel.com"
    for sub in git matrix pds; do
        echo "  Upserting $sub.$DOMAIN → $target"
        local payload result record_id
        payload="{\"type\":\"CNAME\",\"name\":\"$sub\",\"content\":\"$target\",\"proxied\":true}"

        # Look up existing record ID
        record_id=$(curl -s \
            "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records?type=CNAME&name=$sub.$DOMAIN" \
            -H "Authorization: Bearer $CF_TOKEN" \
            | python3 -c "import sys,json; recs=json.load(sys.stdin)['result']; print(recs[0]['id'] if recs else '')")

        if [[ -n "$record_id" ]]; then
            result=$(curl -s -X PUT \
                "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records/$record_id" \
                -H "Authorization: Bearer $CF_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$payload")
            if echo "$result" | grep -q '"success":true'; then
                ok "  $sub.$DOMAIN updated"
            else
                warn "  $sub.$DOMAIN update failed: $(echo "$result" | python3 -c "import sys,json; e=json.load(sys.stdin)['errors']; print(e[0]['message'] if e else 'unknown')")" 
            fi
        else
            result=$(curl -s -X POST \
                "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records" \
                -H "Authorization: Bearer $CF_TOKEN" \
                -H "Content-Type: application/json" \
                -d "$payload")
            if echo "$result" | grep -q '"success":true'; then
                ok "  $sub.$DOMAIN created"
            else
                warn "  $sub.$DOMAIN create failed: $(echo "$result" | python3 -c "import sys,json; e=json.load(sys.stdin)['errors']; print(e[0]['message'] if e else 'unknown')")"
            fi
        fi
    done
}

# ── Step 5: Matrix .well-known delegation ──────────────────────────────────────
step_wellknown() {
    log "Step 5: Matrix .well-known delegation files"
    if [[ ! -d "$WEBSITE_DIR" ]]; then
        warn "Website directory not found ($WEBSITE_DIR) — skipping."
        return 0
    fi

    local wk="$WEBSITE_DIR/static/.well-known/matrix"
    mkdir -p "$wk"
    echo '{"m.server":"matrix.ewancroft.uk:443"}' > "$wk/server"
    echo '{"m.homeserver":{"base_url":"https://matrix.ewancroft.uk"}}' > "$wk/client"

    cd "$WEBSITE_DIR"
    git add . && git commit -m "docs: add Matrix .well-known delegation" && git push || true
    ok "Well-known files pushed."
}

# ── Forgejo secrets (optional, run separately if needed) ─────────────────────
step_forgejo_secrets() {
    log "Forgejo secrets (secrets/forgejo.env)"
    local dst="$SECRETS_DIR/forgejo.env"
    if [[ -f "$dst" ]] && [[ "$RESUME" == true ]]; then ok "Skipping (exists)"; return 0; fi

    local secret_key internal_token tmp
    secret_key=$(openssl rand -hex 32)
    internal_token=$(openssl rand -hex 32)

    tmp=$(mktemp)
    printf "SECRET_KEY=%s\nINTERNAL_TOKEN=%s\n" "$secret_key" "$internal_token" > "$tmp"
    sops_encrypt_binary "$tmp" "$dst"
    rm "$tmp"
    ok "Forgejo secrets encrypted."
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
    echo "${BOLD}${CYAN}"
    echo "  ┌────────────────────────────────────────┐"
    echo "  │   PDS + Matrix + Cloudflare Setup      │"
    echo "  └────────────────────────────────────────┘"
    echo "${RESET}"

    [[ -f "$AGE_KEY" ]] || fail "Age key not found at $AGE_KEY. Run: age-keygen -o $AGE_KEY"

    load_cf_creds
    step_pds_secrets
    step_matrix_secrets
    step_tunnel
    step_dns
    step_wellknown

    echo
    echo "${BOLD}${GREEN}✨  Setup complete!${RESET}"
    echo
    echo "Next steps:"
    echo "  1. Review modules/options.nix — verify tunnelId was updated correctly"
    echo "  2. Commit and push: git add -A && git commit -m 'chore: initial server secrets setup'"
    echo "  3. On server: sudo nixos-rebuild switch --flake .#server"
    echo
    echo "To also set up Forgejo secrets:"
    echo "  source this script and call: step_forgejo_secrets"
}

main
