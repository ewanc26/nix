#!/usr/bin/env bash
# =============================================================================
#  migrate-gts-to-sharkey.sh  —  identity-only migration
#
#  Preserves @ewan@ewancroft.uk by:
#    1. Extracting the RSA keypair from GTS SQLite
#    2. Stopping GTS, switching to Sharkey via nixos-rebuild
#    3. Injecting the old RSA keypair into Sharkey's PostgreSQL
#
#  GTS schema (SQLite):
#    table: accounts
#    columns: private_key, public_key  (PEM strings, local account has domain IS NULL)
#
#  Sharkey schema (PostgreSQL, 2025.4.6):
#    table: user_keypair
#    columns: "userId" (PK, FK → user.id), "publicKey", "privateKey"  (varchar 4096)
#
#  Run as root on the NixOS server.
#  Prereq: sharkey.nix written + secrets/sharkey.env sops-encrypted + nixos-rebuild pending.
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

# ── Step 1: Extract RSA keys from GTS SQLite ─────────────────────────────────
# GTS bun ORM maps PrivateKey/PublicKey (*rsa.PrivateKey/*rsa.PublicKey) to
# snake_case columns private_key/public_key, stored as PEM strings.
info "Extracting RSA keypair for @${GTS_USERNAME} from SQLite..."

PRIVATE_KEY=$(sqlite3 "$GTS_DB" \
	"SELECT private_key FROM accounts WHERE username='${GTS_USERNAME}' AND domain IS NULL LIMIT 1;")
PUBLIC_KEY=$(sqlite3 "$GTS_DB" \
	"SELECT public_key FROM accounts WHERE username='${GTS_USERNAME}' AND domain IS NULL LIMIT 1;")

[[ -n "$PRIVATE_KEY" ]] || error "private_key is empty — check GTS_USERNAME and that the account is local."
[[ -n "$PUBLIC_KEY" ]] || error "public_key is empty."

# Sanity-check PEM headers
[[ "$PRIVATE_KEY" == *"BEGIN RSA PRIVATE KEY"* || "$PRIVATE_KEY" == *"BEGIN PRIVATE KEY"* ]] ||
	error "private_key does not look like a PEM block."
[[ "$PUBLIC_KEY" == *"BEGIN PUBLIC KEY"* ]] ||
	error "public_key does not look like a PEM block."

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
warn "About to stop GoToSocial. ap.ewancroft.uk will be offline until Sharkey starts."
confirm "Continue?" || {
	info "Aborted."
	exit 0
}

info "Stopping GoToSocial..."
systemctl stop "$GTS_SERVICE"

warn "Now run:  nixos-rebuild switch --flake .#server"
warn "(myConfig.services.sharkey.enable = true in your host config)"
read -r -p "$(echo -e "${YELLOW}Press Enter once nixos-rebuild switch completes...${NC}")"

systemctl is-active --quiet sharkey || error "Sharkey is not running. Check: journalctl -u sharkey -n 50"
systemctl is-active --quiet postgresql || error "PostgreSQL is not running."
info "Sharkey + PostgreSQL are up."

# ── Step 3: Create the local account in Sharkey ───────────────────────────────
warn "Create @${GTS_USERNAME} in the Sharkey setup wizard or admin panel:"
warn "  https://${AP_HOSTNAME}  (first run triggers the setup wizard)"
warn "  Username must be exactly: ${GTS_USERNAME}"
read -r -p "$(echo -e "${YELLOW}Press Enter once the account exists...${NC}")"

SHARKEY_USER_ID=$(sudo -u postgres psql -d "$SHARKEY_DB" -tA \
	-c "SELECT id FROM \"user\" WHERE username='${GTS_USERNAME}' AND host IS NULL LIMIT 1;" 2>/dev/null || true)
SHARKEY_USER_ID="${SHARKEY_USER_ID// /}" # trim whitespace psql may add

[[ -n "$SHARKEY_USER_ID" ]] || error "@${GTS_USERNAME} not found in Sharkey DB — create the account first."
info "Sharkey user ID: ${SHARKEY_USER_ID}"

# ── Step 4: Inject old RSA keypair into user_keypair ─────────────────────────
# Sharkey 2025.4.6 always has the user_keypair table (UserKeypair.ts entity).
# Columns: "userId" (PK), "publicKey" varchar(4096), "privateKey" varchar(4096).
# Dollar-quoting ($pem$...$pem$) handles PEM newlines safely without escaping.
info "Injecting GTS RSA keypair into Sharkey's user_keypair table..."

sudo -u postgres psql -d "$SHARKEY_DB" -c \
	"INSERT INTO user_keypair (\"userId\", \"publicKey\", \"privateKey\")
     VALUES (
       '${SHARKEY_USER_ID}',
       \$pem\$${PUBLIC_KEY}\$pem\$,
       \$pem\$${PRIVATE_KEY}\$pem\$
     )
     ON CONFLICT (\"userId\") DO UPDATE
       SET \"publicKey\"  = EXCLUDED.\"publicKey\",
           \"privateKey\" = EXCLUDED.\"privateKey\";"

info "user_keypair updated."

info "Restarting Sharkey to pick up the new keypair..."
systemctl restart sharkey
sleep 5
systemctl is-active --quiet sharkey || error "Sharkey failed to restart. Check: journalctl -u sharkey -n 50"

# ── Step 5: Verify ────────────────────────────────────────────────────────────
info "Verifying WebFinger..."
WF=$(curl -fsSL \
	"https://${ACCOUNT_DOMAIN}/.well-known/webfinger?resource=acct:${GTS_USERNAME}@${ACCOUNT_DOMAIN}" \
	2>/dev/null || true)
if echo "$WF" | jq -e '.subject' &>/dev/null; then
	info "WebFinger OK: $(echo "$WF" | jq -r '.subject')"
else
	warn "WebFinger probe failed — check the Vercel redirect at ewancroft.uk."
fi

info "Verifying actor public key..."
ACTOR=$(curl -fsSL -H 'Accept: application/activity+json' \
	"https://${AP_HOSTNAME}/users/${GTS_USERNAME}" 2>/dev/null || true)
if echo "$ACTOR" | jq -e '.publicKey.publicKeyPem' &>/dev/null; then
	ACTOR_KEY=$(echo "$ACTOR" | jq -r '.publicKey.publicKeyPem')
	if [[ "$ACTOR_KEY" == "$PUBLIC_KEY" ]]; then
		info "Actor public key matches GTS original. ✓  Identity preserved."
	else
		warn "Public key mismatch — Sharkey may be caching its generated key."
		warn "Try:  systemctl restart sharkey  and re-run the verify block."
	fi
else
	warn "Could not fetch actor JSON — Sharkey may still be starting up."
fi

echo ""
info "Done. Key backup at: ${KEY_BACKUP}"
