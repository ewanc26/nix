#!/usr/bin/env bash
# =============================================================================
#  migrate-gts-to-sharkey.sh  —  identity-only migration
#
#  Preserves @ewan@ewancroft.uk by:
#    1. Extracting the RSA keypair from GTS SQLite
#    2. Stopping GTS, switching to Sharkey via nixos-rebuild
#    3. Injecting the old RSA keypair into Sharkey's PostgreSQL
#
#  Run as root on the NixOS server.
#  Prereq: sharkey.nix written + secrets/sharkey.env encrypted + options updated.
# =============================================================================
set -euo pipefail

GTS_USERNAME="ewan"
GTS_DB="/srv/gotosocial/sqlite.db"
GTS_SERVICE="gotosocial"
AP_HOSTNAME="ap.ewancroft.uk"
ACCOUNT_DOMAIN="ewancroft.uk"
SHARKEY_DB="sharkey"
KEY_BACKUP="/root/gts-keypair-$(date +%Y%m%d-%H%M%S).env"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() {
	echo -e "${RED}[ERROR]${NC} $*" >&2
	exit 1
}
confirm() {
	read -r -p "$(echo -e "${YELLOW}${1} [y/N] ${NC}")" r
	[[ "${r,,}" == "y" ]]
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
[[ "$(id -u)" -eq 0 ]] || error "Run as root."
[[ -f "$GTS_DB" ]] || error "GTS DB not found: $GTS_DB"
for cmd in sqlite3 psql systemctl curl jq; do
	command -v "$cmd" &>/dev/null || error "Missing required command: $cmd"
done

# ── Step 1: Extract RSA keys ──────────────────────────────────────────────────
info "Extracting RSA keypair for @${GTS_USERNAME} from SQLite..."

PRIVATE_KEY=$(sqlite3 "$GTS_DB" \
	"SELECT private_key FROM accounts WHERE username='${GTS_USERNAME}' AND domain IS NULL LIMIT 1;")
PUBLIC_KEY=$(sqlite3 "$GTS_DB" \
	"SELECT public_key FROM accounts WHERE username='${GTS_USERNAME}' AND domain IS NULL LIMIT 1;")

[[ -n "$PRIVATE_KEY" && -n "$PUBLIC_KEY" ]] || error "Could not extract keys — check username."

# Persist to a backup file in case we need to re-run step 3
{
	echo "PRIVATE_KEY<<EOF"
	echo "$PRIVATE_KEY"
	echo "EOF"
	echo "PUBLIC_KEY<<EOF"
	echo "$PUBLIC_KEY"
	echo "EOF"
} >"$KEY_BACKUP"
chmod 600 "$KEY_BACKUP"
info "Keys backed up to: $KEY_BACKUP"

# ── Step 2: Stop GTS, rebuild with Sharkey ────────────────────────────────────
warn "About to stop GoToSocial. ap.ewancroft.uk will be down until Sharkey starts."
confirm "Continue?" || {
	info "Aborted."
	exit 0
}

info "Stopping GoToSocial..."
systemctl stop "$GTS_SERVICE"

warn "Now run:  nixos-rebuild switch --flake .#server"
warn "(services.gotosocial.enable = false, services.sharkey.enable = true)"
read -r -p "$(echo -e "${YELLOW}Press Enter once nixos-rebuild switch completes...${NC}")"

systemctl is-active --quiet sharkey || error "Sharkey is not running. Check: journalctl -u sharkey -n 50"
systemctl is-active --quiet postgresql || error "PostgreSQL is not running."
info "Sharkey + PostgreSQL are up."

# ── Step 3: Create account in Sharkey ─────────────────────────────────────────
warn "Create the @${GTS_USERNAME} account in the Sharkey admin panel now."
warn "  https://${AP_HOSTNAME}  ->  Admin  ->  Users  ->  Create"
warn "Username must be: ${GTS_USERNAME}"
read -r -p "$(echo -e "${YELLOW}Press Enter once the account exists...${NC}")"

SHARKEY_USER_ID=$(sudo -u postgres psql -d "$SHARKEY_DB" -tA \
	-c "SELECT id FROM \"user\" WHERE username='${GTS_USERNAME}' AND host IS NULL LIMIT 1;" 2>/dev/null || true)

[[ -n "$SHARKEY_USER_ID" ]] || error "User @${GTS_USERNAME} not found in Sharkey DB. Create the account first."
info "Sharkey user ID: ${SHARKEY_USER_ID}"

# ── Step 4: Inject old RSA keypair ────────────────────────────────────────────
info "Injecting GTS RSA keypair into Sharkey..."

HAS_KEYPAIR_TABLE=$(sudo -u postgres psql -d "$SHARKEY_DB" -tA \
	-c "SELECT to_regclass('public.user_keypair');" 2>/dev/null || echo "")

if [[ "$HAS_KEYPAIR_TABLE" == "user_keypair" ]]; then
	sudo -u postgres psql -d "$SHARKEY_DB" -c \
		"INSERT INTO user_keypair (\"userId\", \"publicKey\", \"privateKey\")
         VALUES ('${SHARKEY_USER_ID}', \$pem\$${PUBLIC_KEY}\$pem\$, \$pem\$${PRIVATE_KEY}\$pem\$)
         ON CONFLICT (\"userId\") DO UPDATE
           SET \"publicKey\"  = EXCLUDED.\"publicKey\",
               \"privateKey\" = EXCLUDED.\"privateKey\";"
	info "Updated user_keypair table."
else
	# Older schema — keys inline on user table
	sudo -u postgres psql -d "$SHARKEY_DB" -c \
		"UPDATE \"user\"
         SET \"publicKey\"  = \$pem\$${PUBLIC_KEY}\$pem\$,
             \"privateKey\" = \$pem\$${PRIVATE_KEY}\$pem\$
         WHERE id = '${SHARKEY_USER_ID}';"
	info "Updated user table (inline key columns)."
fi

info "Restarting Sharkey..."
systemctl restart sharkey
sleep 5
systemctl is-active --quiet sharkey || error "Sharkey failed to restart."

# ── Step 5: Verify ────────────────────────────────────────────────────────────
info "Verifying WebFinger..."
WF=$(curl -fsSL "https://${ACCOUNT_DOMAIN}/.well-known/webfinger?resource=acct:${GTS_USERNAME}@${ACCOUNT_DOMAIN}" 2>/dev/null || true)
if echo "$WF" | jq -e '.subject' &>/dev/null; then
	info "WebFinger OK: $(echo "$WF" | jq -r '.subject')"
else
	warn "WebFinger returned unexpected result — check your Vercel redirect."
fi

info "Verifying actor public key..."
ACTOR=$(curl -fsSL -H 'Accept: application/activity+json' "https://${AP_HOSTNAME}/users/${GTS_USERNAME}" 2>/dev/null || true)
if echo "$ACTOR" | jq -e '.publicKey.publicKeyPem' &>/dev/null; then
	ACTOR_KEY=$(echo "$ACTOR" | jq -r '.publicKey.publicKeyPem')
	if [[ "$ACTOR_KEY" == "$PUBLIC_KEY" ]]; then
		info "Actor public key matches GTS original. Identity preserved."
	else
		warn "Public key mismatch — Sharkey may not have reloaded yet. Try: systemctl restart sharkey"
	fi
else
	warn "Could not retrieve actor JSON — Sharkey may still be starting up."
fi

echo ""
info "Done. Key backup retained at: ${KEY_BACKUP}"
