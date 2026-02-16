#!/usr/bin/env bash
################################################################################
# unified-setup.sh — Combined Matrix + PDS + Cloudflare Setup
################################################################################
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
BOLD=$'\e[1m'; DIM=$'\e[2m'; GREEN=$'\e[32m'
YELLOW=$'\e[33m'; RED=$'\e[31m'; CYAN=$'\e[36m'; RESET=$'\e[0m'

log()    { echo; echo "${BOLD}${CYAN}==> $*${RESET}"; }
ok()     { echo "${GREEN}  ✓${RESET} $*"; }
warn()   { echo "${YELLOW}  ⚠${RESET} $*"; }
fail()   { echo "${RED}  ✗${RESET} $*" >&2; exit 1; }
log_step() { echo -e "${CYAN}[STEP]${NC} $*"; }

# ── Configuration & Paths ─────────────────────────────────────────────────────
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
CONFIG_DIR="$HOME/.config/nix-config"
SECRETS_FILE="$ROOT/secrets/secrets.nix"
SECRETS_DIR="$ROOT/secrets/age"
AGE_KEY="$HOME/.config/age/keys.txt"
WEBSITE_DIR="$HOME/Developer/Git/GitHub/ewanc26/website"
DOMAIN="ewancroft.uk"

# Flags
RESUME=false
FORCE_TUNNEL=false

for arg in "$@"; do case "$arg" in
    --resume) RESUME=true ;;
    --force-tunnel) FORCE_TUNNEL=true ;;
esac; done

# ── Helpers ───────────────────────────────────────────────────────────────────
run_cmd() {
    local cmd="$1"; shift
    if command -v "$cmd" &> /dev/null; then "$cmd" "$@"
    else
        case "$cmd" in
            cloudflared) nix run nixpkgs#cloudflared -- "$@" ;;
            pwgen)       nix run nixpkgs#pwgen -- "$@" ;;
            age)         nix run nixpkgs#age -- "$@" ;;
            ragenix)     nix run github:yaxitech/ragenix -- "$@" ;;
            *)           fail "Command $cmd not found." ;;
        esac
    fi
}

sedi() { if [[ "$(uname -s)" == Darwin ]]; then sed -i '' "$@"; else sed -i "$@"; fi; }

ensure_secrets_rules() {
    log "Verifying Ragenix rules..."
    # 1. Ensure matrixKeys block
    if ! grep -q "matrixKeys =" "$SECRETS_FILE"; then
        sedi "/in/i\\
  matrixKeys = [ users.ewan ];" "$SECRETS_FILE"
    fi
    # 2. Add required rules
    local rules=(
        "\"age/matrix.env.age\".publicKeys = matrixKeys;"
        "\"age/pds.env.age\".publicKeys = pdsKeys;"
        "\"age/cf-tunnel.json.age\".publicKeys = matrixKeys;"
        "\"age/cloudflare.token.age\".publicKeys = matrixKeys;"
    )
    for rule in "${rules[@]}"; do
        local key=$(echo "$rule" | cut -d'"' -f2)
        if ! grep -q "$key" "$SECRETS_FILE"; then
            sedi "/^}/i\\
  $rule" "$SECRETS_FILE"
        fi
    done
}

# ── Step 0: Cloudflare Credentials (Auto-Vault) ───────────────────────────────
load_cf_creds() {
    local token_age="$SECRETS_DIR/cloudflare.token.age"
    if [[ -f "$token_age" ]]; then
        log "Decrypting Cloudflare credentials..."
        local decrypted=$(run_cmd age -d -i "$AGE_KEY" "$token_age")
        export CF_TOKEN=$(echo "$decrypted" | awk '{print $1}')
        export CF_ZONE=$(echo "$decrypted" | awk '{print $2}')
    else
        warn "Cloudflare credentials not found in vault."
        read -rp "  Enter CF API Token: " CF_TOKEN
        read -rp "  Enter CF Zone ID:   " CF_ZONE
        ensure_secrets_rules
        local tmp=$(mktemp)
        echo "$CF_TOKEN $CF_ZONE" > "$tmp"
        cd "$ROOT"
        EDITOR="cp $tmp" run_cmd ragenix --rules "secrets/secrets.nix" --identity "$AGE_KEY" -e "secrets/age/cloudflare.token.age"
        rm "$tmp"
    fi
}

# ── Step 1: PDS Secrets ───────────────────────────────────────────────────────
step_pds_secrets() {
    log "Step 1: PDS Secrets (pds.env.age)"
    if [[ -f "$SECRETS_DIR/pds.env.age" ]] && [[ "$RESUME" == true ]]; then ok "Skipping PDS secrets"; return 0; fi
    
    local jwt=$(openssl rand --hex 16)
    local admin=$(openssl rand --hex 16)
    
    local tmp=$(mktemp)
    echo "PDS_JWT_SECRET=$jwt" > "$tmp"
    echo "PDS_ADMIN_PASSWORD=$admin" >> "$tmp"
    
    cd "$ROOT"
    EDITOR="cp $tmp" run_cmd ragenix --rules "secrets/secrets.nix" --identity "$AGE_KEY" -e "secrets/age/pds.env.age"
    rm "$tmp"
    ok "PDS secrets encrypted. Admin Password: $admin"
}

# ── Step 2: Matrix Secrets ────────────────────────────────────────────────────
step_matrix_secrets() {
    log "Step 2: Matrix Secrets (matrix.env.age)"
    if [[ -f "$SECRETS_DIR/matrix.env.age" ]] && [[ "$RESUME" == true ]]; then ok "Skipping Matrix secrets"; return 0; fi

    local reg=$(run_cmd pwgen -s 64 1)
    local mac=$(run_cmd pwgen -s 64 1)
    
    local tmp=$(mktemp)
    echo "REGISTRATION_SHARED_SECRET=$reg" > "$tmp"
    echo "MACAROON_SECRET_KEY=$mac" >> "$tmp"
    
    cd "$ROOT"
    EDITOR="cp $tmp" run_cmd ragenix --rules "secrets/secrets.nix" --identity "$AGE_KEY" -e "secrets/age/matrix.env.age"
    rm "$tmp"
    ok "Matrix secrets encrypted."
}

# ── Step 3: Tunnel Setup ──────────────────────────────────────────────────────
step_tunnel() {
    log "Step 3: Cloudflare Tunnel (shared)"
    ensure_secrets_rules
    
    local uuid=$(run_cmd cloudflared tunnel list | grep "server" | awk '{print $1}' || echo "")
    
    if [[ -z "$uuid" ]] || [[ "$FORCE_TUNNEL" == true ]]; then
        [[ -n "$uuid" ]] && run_cmd cloudflared tunnel delete -f "$uuid"
        log "Creating new tunnel 'server'..."
        local output=$(run_cmd cloudflared tunnel create server 2>&1 || true)
        uuid=$(echo "$output" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)
    fi
    
    local creds="$HOME/.cloudflared/$uuid.json"
    if [[ -f "$creds" ]]; then
        cd "$ROOT"
        EDITOR="cp $creds" run_cmd ragenix --rules "secrets/secrets.nix" --identity "$AGE_KEY" -e "secrets/age/cf-tunnel.json.age"
    fi

    # Update tunnelId in BOTH configs if they exist
    [[ -f "$ROOT/settings/config/cloudflare.nix" ]] && sedi "s|tunnelId = \".*\";|tunnelId = \"$uuid\";|" "$ROOT/settings/config/cloudflare.nix"
    [[ -f "$ROOT/settings/config/pds.nix" ]] && sedi "s|tunnelId = \".*\";|tunnelId = \"$uuid\";|" "$ROOT/settings/config/pds.nix"
    
    export TUNNEL_UUID="$uuid"
    ok "Tunnel configured: $uuid"
}

# ── Step 4: DNS Automation ────────────────────────────────────────────────────
step_dns() {
    log "Step 4: Cloudflare DNS Records"
    for sub in "matrix" "pds"; do
        log "  Setting $sub.$DOMAIN -> $TUNNEL_UUID"
        curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE/dns_records" \
            -H "Authorization: Bearer $CF_TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"type\":\"CNAME\",\"name\":\"$sub\",\"content\":\"$TUNNEL_UUID.cfargotunnel.com\",\"proxied\":true}" | grep -q "success" || warn "$sub record already exists."
    done
}

# ── Step 5: Website Well-Known ────────────────────────────────────────────────
step_wellknown() {
    log "Step 5: Matrix Delegation (.well-known)"
    if [[ ! -d "$WEBSITE_DIR" ]]; then warn "Website dir not found, skipping Step 5"; return 0; fi
    
    local wk="$WEBSITE_DIR/static/.well-known/matrix"
    mkdir -p "$wk"
    echo '{"m.server":"matrix.ewancroft.uk:443"}' > "$wk/server"
    echo '{"m.homeserver":{"base_url":"https://matrix.ewancroft.uk"}}' > "$wk/client"
    
    cd "$WEBSITE_DIR"
    git add . && git commit -m "docs: matrix delegation" && git push || true
    ok "Well-known files pushed to website repository."
}

# ── Execution ─────────────────────────────────────────────────────────────────
main() {
    load_cf_creds
    step_pds_secrets
    step_matrix_secrets
    step_tunnel
    step_dns
    step_wellknown
    
    log "Final Rekeying..."
    cd "$ROOT"
    run_cmd ragenix --rules "secrets/secrets.nix" --identity "$AGE_KEY" -r
    
    echo -e "\n${BOLD}${GREEN}Deployment Ready!${RESET}"
    echo "1. Git add and push your nix-config."
    echo "2. On the server: nixos-rebuild switch --flake .#server"
}

main