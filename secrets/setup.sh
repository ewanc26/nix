#!/usr/bin/env bash
# secrets/setup.sh — Bootstrap all sops-encrypted secrets for the nix-config.
#
# Only requirement: nix (with flakes enabled).
# All tools (sops, age, cloudflared, …) are run via `nix run nixpkgs#…` if
# they are not already on PATH — nothing needs to be installed first.
#
# For each secret file this script will:
#   1. Skip the file if it is already sops-encrypted (safe to re-run).
#   2. Generate keys/tokens where possible (openssl, which ships on macOS/Linux).
#   3. Prompt interactively for values that cannot be derived.
#   4. Encrypt the result with sops using the recipients in .sops.yaml.
#
# Secrets are encrypted to your PGP key (you) plus each host's age key (derived
# from its SSH host key). See .sops.yaml for the recipient rules.
#
# Flags:
#   --force        Re-generate and re-encrypt every file, even if already encrypted.
#   --skip-cf      Skip the Cloudflare tunnel step.
#   --rekey-only   Skip generation entirely; just re-encrypt every existing
#                  secret to the current recipients in .sops.yaml. This is what
#                  you run after changing keys.

set -euo pipefail

# ── Bootstrap: re-exec inside nix shell if tools aren't present ───────────────
# This means the only hard requirement is `nix` itself.
if [[ -z "${_NIX_SETUP_ENV:-}" ]]; then
    export _NIX_SETUP_ENV=1
    exec nix shell \
        nixpkgs#sops \
        nixpkgs#age \
        nixpkgs#gnupg \
        nixpkgs#cloudflared \
        --command bash "$0" "$@"
fi

# ── Colours ────────────────────────────────────────────────────────────────────
BOLD=$'\e[1m'; GREEN=$'\e[32m'; YELLOW=$'\e[33m'
RED=$'\e[31m'; CYAN=$'\e[36m'; RESET=$'\e[0m'

log()  { echo; echo "${BOLD}${CYAN}==> $*${RESET}"; }
ok()   { echo "  ${GREEN}✓${RESET}  $*"; }
warn() { echo "  ${YELLOW}⚠${RESET}  $*"; }
fail() { echo "  ${RED}✗${RESET}  $*" >&2; exit 1; }
ask()  { printf "  ${BOLD}?${RESET}  %s " "$*"; }

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$(dirname "$SCRIPT_DIR")")"
SECRETS_DIR="$ROOT/secrets"
SOPS_YAML="$ROOT/.sops.yaml"

# The user key is PGP, but the age keyfile is still exported deliberately.
#
# `sops updatekeys` has to DECRYPT a file before it can re-encrypt it to a new
# recipient set. During the migration away from an age user key, the only key
# that can still open the existing files is that age key — so it must remain
# available for the first rekey run. It is harmless afterwards, and the Faol
# secrets decrypted at activation on macOS still use it.
AGE_KEY="$HOME/.config/age/keys.txt"
[[ -s "$AGE_KEY" ]] && export SOPS_AGE_KEY_FILE="$AGE_KEY"

# ── Flags ──────────────────────────────────────────────────────────────────────
FORCE=false
SKIP_CF=false
REKEY_ONLY=false
for arg in "$@"; do case "$arg" in
    --force)      FORCE=true ;;
    --skip-cf)    SKIP_CF=true ;;
    --rekey-only) REKEY_ONLY=true ;;
esac; done

# openssl ships on both macOS and Linux.
run_openssl() { openssl "$@"; }

# ── Core helpers ───────────────────────────────────────────────────────────────

# Returns 0 if the file exists and contains sops metadata.
# sops always writes a JSON envelope with a "sops" key, even for binary files,
# so a grep is sufficient — no decryption attempt needed.
is_encrypted() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    [[ -s "$file" ]] || return 1
    grep -q '"sops"' "$file" 2>/dev/null
}

# Encrypt a plaintext file as a sops binary secret.
# The temp file must live under $SECRETS_DIR so its path matches the
# creation rules in .sops.yaml (sops uses the INPUT path for rule matching).
encrypt_file() {
    local src="$1" dst="$2"
    # Stage plaintext next to the destination so the path matches sops rules,
    # then encrypt in-place and move into position.
    local stage="${dst}.plaintext"
    cp "$src" "$stage"
    cd "$ROOT"
    sops --encrypt --input-type binary --output-type binary --in-place "$stage"
    mv "$stage" "$dst"
    ok "Encrypted → ${dst#"$ROOT/"}"
    command -v shred &>/dev/null && shred -u "$src" || rm -f "$src"
}

# Write a string to a temp file, encrypt it, remove the temp.
encrypt_content() {
    local content="$1" dst="$2"
    local tmp
    tmp=$(mktemp)
    printf '%s' "$content" > "$tmp"
    encrypt_file "$tmp" "$dst"
}

# Prompt for a secret value with hidden input.
prompt_secret() {
    local prompt="$1" value=""
    while [[ -z "$value" ]]; do
        ask "$prompt"
        read -rs value; echo
        [[ -z "$value" ]] && warn "Value cannot be empty, try again."
    done
    printf '%s' "$value"
}

# ── 0. PGP key preflight ───────────────────────────────────────────────────────
# The user recipient in .sops.yaml is a PGP fingerprint. Verify before touching
# anything that (a) it has actually been filled in, and (b) the matching secret
# key is in this machine's keyring — otherwise sops fails partway through with a
# far less obvious error.
preflight_pgp_key() {
    log "PGP key"

    [[ -f "$SOPS_YAML" ]] || fail "No .sops.yaml at $SOPS_YAML"

    if grep -q 'REPLACE_WITH_YOUR_PGP_FINGERPRINT' "$SOPS_YAML"; then
        echo
        fail "$(cat <<'EOM'
.sops.yaml still contains the placeholder fingerprint.

Replace it with your own long-form PGP fingerprint (40 hex characters):

    gpg --list-secret-keys --with-colons --fingerprint \
      | awk -F: '/^fpr:/{print $10; exit}'

then edit the `&ewan_pgp` anchor near the top of .sops.yaml.
EOM
)"
    fi

    local fpr
    fpr=$(awk '/&ewan_pgp/{print $3; exit}' "$SOPS_YAML")
    [[ -n "$fpr" ]] || fail "Could not read the &ewan_pgp fingerprint from .sops.yaml"

    if ! gpg --list-secret-keys "$fpr" &>/dev/null; then
        fail "No secret key for $fpr in this keyring — import it before continuing."
    fi

    ok "User PGP key: $fpr"
    USER_PGP_FPR="$fpr"

    # Warn, but do not fail: the age key is only needed to open secrets that
    # have not been rekeyed to PGP yet.
    if [[ -s "$AGE_KEY" ]]; then
        ok "Age key present at $AGE_KEY (used to decrypt not-yet-rekeyed secrets)"
    else
        warn "No age key at $AGE_KEY — fine once every secret is rekeyed to PGP,"
        warn "but a first-time migration cannot decrypt the old files without it."
    fi
}

# ── 1. forgejo.env ─────────────────────────────────────────────────────────────
secret_forgejo() {
    log "forgejo.env  (Forgejo SECRET_KEY + INTERNAL_TOKEN)"
    local dst="$SECRETS_DIR/forgejo.env"
    if [[ "$FORCE" == false ]] && is_encrypted "$dst"; then
        ok "Already encrypted — skipping (use --force to regenerate)"; return
    fi
    local secret_key internal_token
    secret_key=$(run_openssl rand -hex 32)
    internal_token=$(run_openssl rand -hex 32)
    encrypt_content "$(printf 'SECRET_KEY=%s\nINTERNAL_TOKEN=%s\n' \
        "$secret_key" "$internal_token")" "$dst"
    ok "Forgejo secrets generated."
}

# ── 2. pds.env ─────────────────────────────────────────────────────────────────
secret_pds() {
    log "pds.env  (Bluesky PDS JWT secret, admin password, PLC rotation key)"
    local dst="$SECRETS_DIR/pds.env"
    if [[ "$FORCE" == false ]] && is_encrypted "$dst"; then
        ok "Already encrypted — skipping"; return
    fi

    local jwt admin plc_hex
    jwt=$(run_openssl rand -hex 16)
    admin=$(run_openssl rand -hex 16)

    # Extract a secp256k1 private key scalar from an openssl-generated key.
    # The DER encoding of a bare EC private key puts the 32-byte scalar at
    # offset 7. Fall back to 32 random bytes if parsing fails.
    local tmp_pem
    tmp_pem=$(mktemp)
    if run_openssl ecparam -name secp256k1 -genkey -noout -out "$tmp_pem" 2>/dev/null; then
        plc_hex=$(run_openssl ec -in "$tmp_pem" -outform DER 2>/dev/null \
            | dd bs=1 skip=7 count=32 2>/dev/null \
            | od -An -tx1 -v | tr -d ' \n' || true)
    fi
    rm -f "$tmp_pem"
    [[ ${#plc_hex} -eq 64 ]] || plc_hex=$(run_openssl rand -hex 32)

    encrypt_content "$(printf \
        'PDS_JWT_SECRET=%s\nPDS_ADMIN_PASSWORD=%s\nPDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=%s\n' \
        "$jwt" "$admin" "$plc_hex")" "$dst"

    echo
    warn "PDS admin password (save this!): ${BOLD}${admin}${RESET}"
    ok "PDS secrets generated."
}

# ── 4. cf-tunnel.json ──────────────────────────────────────────────────────────
secret_cf_tunnel() {
    log "cf-tunnel.json  (Cloudflare Tunnel credentials)"
    local dst="$SECRETS_DIR/cf-tunnel.json"

    if [[ "$SKIP_CF" == true ]]; then
        warn "Skipping (--skip-cf passed)"; return
    fi
    if [[ "$FORCE" == false ]] && is_encrypted "$dst"; then
        ok "Already encrypted — skipping"; return
    fi

    # Verify auth works (cert.pem can exist but be expired/invalid).
    # Re-login if tunnel list fails for any reason.
    ok "Checking Cloudflare auth..."
    if ! cloudflared tunnel list &>/dev/null; then
        warn "Not authenticated (or session expired) — opening browser to log in..."
        cloudflared tunnel login
    fi

    # Reuse existing tunnel named 'server' or create a new one
    local uuid
    ok "Listing existing tunnels..."
    cloudflared tunnel list
    uuid=$(cloudflared tunnel list 2>/dev/null \
        | awk '/[[:space:]]server[[:space:]]/{print $1}' | head -1 || true)

    if [[ -z "$uuid" ]]; then
        log "Creating Cloudflare tunnel 'server'..."
        local tmp_out; tmp_out=$(mktemp)
        cloudflared tunnel create server 2>&1 | tee "$tmp_out"
        uuid=$(grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' \
            "$tmp_out" | head -1 || true)
        rm -f "$tmp_out"
        [[ -n "$uuid" ]] || fail "Could not parse tunnel UUID from cloudflared output."
    else
        ok "Reusing existing tunnel: $uuid"
    fi

    local creds="$HOME/.cloudflared/$uuid.json"
    if [[ ! -f "$creds" ]]; then
        warn "Credentials file not found at $creds"
        warn "Available files in ~/.cloudflared/:"
        ls -la "$HOME/.cloudflared/" || true
        fail "Cannot continue without tunnel credentials."
    fi

    ok "Encrypting credentials from $creds"
    local tmp; tmp=$(mktemp)
    cp "$creds" "$tmp"
    encrypt_file "$tmp" "$dst"

    # Patch tunnelId in modules/options.nix
    local opts="$ROOT/modules/options.nix"
    if [[ -f "$opts" ]]; then
        # Use python3 (ships on macOS) for reliable in-place multi-line substitution
        # rather than fighting BSD sed's limitations with address ranges.
        python3 - "$opts" "$uuid" <<'PYEOF'
import sys, re
path, uuid = sys.argv[1], sys.argv[2]
text = open(path).read()
# Replace the default value of the tunnelId option
text = re.sub(
    r'(tunnelId[^{]*default\s*=\s*")[^"]*"',
    lambda m: m.group(1) + uuid + '"',
    text
)
open(path, 'w').write(text)
PYEOF
        ok "Updated tunnelId in modules/options.nix → $uuid"
    fi

    ok "Cloudflare tunnel UUID: $uuid"
    export TUNNEL_UUID="$uuid"
}

# ── 5. docker-config.json ──────────────────────────────────────────────────────
secret_docker() {
    log "docker-config.json  (~/.docker/config.json)"
    local dst="$SECRETS_DIR/docker-config.json"
    if [[ "$FORCE" == false ]] && is_encrypted "$dst"; then
        ok "Already encrypted — skipping"; return
    fi

    local content
    if [[ -s "$HOME/.docker/config.json" ]]; then
        ok "Found existing ~/.docker/config.json — using it"
        content=$(cat "$HOME/.docker/config.json")
    else
        echo "  No ~/.docker/config.json found."
        ask "Registry hostname to add credentials for [Enter to create empty config]:"
        local registry; read -r registry

        if [[ -z "$registry" ]]; then
            content='{"auths":{}}'
        else
            ask "Username for $registry:"; local user; read -r user
            local pass; pass=$(prompt_secret "Password for $registry (hidden):")
            local auth; auth=$(printf '%s:%s' "$user" "$pass" | base64)
            content=$(printf '{"auths":{"%s":{"auth":"%s"}}}' "$registry" "$auth")
        fi
    fi

    encrypt_content "$content" "$dst"
    ok "Docker config encrypted."
}

# ── 6. claude.json ─────────────────────────────────────────────────────────────
secret_claude() {
    log "claude.json  (~/.claude.json)"
    local dst="$SECRETS_DIR/claude.json"
    if [[ "$FORCE" == false ]] && is_encrypted "$dst"; then
        ok "Already encrypted — skipping"; return
    fi

    local content
    if [[ -s "$HOME/.claude.json" ]]; then
        ok "Found existing ~/.claude.json — using it"
        content=$(cat "$HOME/.claude.json")
    else
        echo "  No ~/.claude.json found."
        echo "  Get your API key from https://console.anthropic.com/settings/keys"
        local api_key
        api_key=$(prompt_secret "Anthropic API key (sk-ant-...):")
        [[ "$api_key" == sk-ant-* ]] \
            || warn "Key doesn't look like an Anthropic key — continuing anyway."
        content=$(printf '{"apiKey":"%s"}' "$api_key")
    fi

    encrypt_content "$content" "$dst"
    ok "Claude config encrypted."
}


# ── Rekey all secrets ──────────────────────────────────────────────────────────
rekey_all() {
    log "Re-keying all secrets with current .sops.yaml recipients"
    cd "$ROOT"
    local failures=0
    while IFS= read -r -d '' f; do
        local name="${f#"$SECRETS_DIR/"}"
        local err
        if err=$(sops updatekeys --yes --input-type binary "$f" 2>&1); then
            # Confirm the PGP recipient actually landed in the file's metadata.
            # sops records it as an `fp` field; a rule that failed to match
            # would otherwise leave the file silently PGP-less.
            if grep -qi "$USER_PGP_FPR" "$f"; then
                ok "$name"
            else
                warn "$name — rekeyed, but your PGP fingerprint is not among the"
                warn "    recipients. Check the path_regex rules in .sops.yaml."
                (( failures++ )) || true
            fi
        else
            warn "$name — updatekeys failed:"
            echo "$err" | sed 's/^/      /'
            (( failures++ )) || true
        fi
    done < <(find "$SECRETS_DIR" -maxdepth 1 -type f \
        ! -name "setup.sh" ! -name ".gitignore" -print0 2>/dev/null)
    [[ $failures -eq 0 ]] || warn "$failures file(s) could not be rekeyed."
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
    echo
    echo "${BOLD}${CYAN}  ┌──────────────────────────────────────────┐"
    echo "  │   nix-config secrets bootstrap           │"
    echo "  └──────────────────────────────────────────┘${RESET}"
    echo

    # All tools are available — we're running inside `nix shell` at this point.
    [[ "$FORCE" == true ]] && warn "--force: existing encrypted secrets will be regenerated"

    preflight_pgp_key

    mkdir -p "$SECRETS_DIR"

    if [[ "$REKEY_ONLY" == true ]]; then
        warn "--rekey-only: skipping secret generation"
    else
        secret_forgejo
        secret_pds
        secret_cf_tunnel
        secret_docker
        secret_claude
    fi

    rekey_all

    echo
    echo "${BOLD}${GREEN}✨  Done.${RESET}"
    echo
    echo "Next steps:"
    echo "  1. Commit the encrypted secrets:"
    echo "     git add secrets/ && git commit -m 'chore: bootstrap encrypted secrets'"
    echo "  2. On each host, rebuild:"
    echo "     sudo nixos-rebuild switch --flake ~/.config/nix-config        # Linux"
    echo "     darwin-rebuild switch --flake ~/.config/nix-config#macmini   # macOS"
    echo
    echo "To regenerate a single secret, pass --force and re-run."
}

main "$@"
