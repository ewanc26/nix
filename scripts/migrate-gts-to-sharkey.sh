#!/usr/bin/env bash
# =============================================================================
#  migrate-gts-to-sharkey.sh  —  identity-only migration
#
#  Preserves @ewan@ewancroft.uk by:
#    1. Extracting the RSA keypair from GTS SQLite
#    2. Converting JSON-encoded Go big.Int keys → PEM (via nix + cryptography)
#    3. Stopping GTS, switching to Sharkey via nixos-rebuild
#    4. Injecting the old RSA keypair into Sharkey's PostgreSQL
#
#  GTS schema (SQLite):
#    table: accounts
#    columns: private_key, public_key
#    format: JSON-encoded Go *rsa.PrivateKey / *rsa.PublicKey (big.Int as
#            decimal JSON numbers, e.g. {"N":12345...,"E":65537,"D":...})
#    note:   GTS holds a WAL lock — must use immutable=1 URI to read
#
#  Sharkey schema (PostgreSQL, 2025.4.6):
#    table: user_keypair
#    columns: "userId" (PK), "publicKey", "privateKey"  (varchar 4096, PEM)
#
#  Run as root on the NixOS server.
#  Prereq: sharkey.nix written + secrets/sharkey.env sops-encrypted + rebuilt.
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

# ── Inline Python converter: Go JSON RSA key → PEM ────────────────────────────
# Called as: json_to_pem <private|public> <<< "$JSON"
# Uses nix-shell to provide python3 + cryptography without a global install.
#
# Go's encoding/json marshals *rsa.PrivateKey with fields:
#   private: {"N":...,"E":...,"D":...,"Primes":[p,q],...}
# Go's encoding/json marshals *rsa.PublicKey with fields:
#   public:  {"N":...,"E":...}
JSON_TO_PEM_PY='
import sys, json
from cryptography.hazmat.primitives.asymmetric.rsa import (
    RSAPrivateNumbers, RSAPublicNumbers, rsa_crt_iqmp, rsa_crt_dmp1, rsa_crt_dmq1
)
from cryptography.hazmat.primitives.serialization import (
    Encoding, PrivateFormat, PublicFormat, NoEncryption
)

k    = json.loads(sys.stdin.read())
mode = sys.argv[1]
N    = int(k["N"])
E    = int(k["E"])
pub  = RSAPublicNumbers(E, N)

if mode == "private":
    D    = int(k["D"])
    P    = int(k["Primes"][0])
    Q    = int(k["Primes"][1])
    priv = RSAPrivateNumbers(P, Q, D, rsa_crt_dmp1(D, P), rsa_crt_dmq1(D, Q), rsa_crt_iqmp(P, Q), pub)
    sys.stdout.write(priv.private_key().private_bytes(Encoding.PEM, PrivateFormat.TraditionalOpenSSL, NoEncryption()).decode())
else:
    sys.stdout.write(pub.public_key().public_bytes(Encoding.PEM, PublicFormat.SubjectPublicKeyInfo).decode())
'

json_to_pem() {
	local mode="$1" # private | public
	local json_input tmppy
	json_input="$(cat)"
	tmppy=$(mktemp /tmp/gts_key_convert.XXXXXX.py)
	echo "$JSON_TO_PEM_PY" >"$tmppy"
	echo "$json_input" | nix-shell -p "python3.withPackages(ps: [ps.cryptography])" \
		--run "python3 $tmppy $mode"
	rm -f "$tmppy"
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
[[ "$(id -u)" -eq 0 ]] || error "Run as root."
[[ -f "$GTS_DB" ]] || error "GTS DB not found: $GTS_DB"
for cmd in sqlite3 psql systemctl curl jq nix-shell; do
	command -v "$cmd" &>/dev/null || error "Missing required command: $cmd"
done

# ── Step 1: Extract RSA keys from GTS SQLite ─────────────────────────────────
# GTS holds a WAL lock on the DB even when stopped (until it flushes).
# immutable=1 bypasses the lock for read-only access.
info "Extracting RSA keypair for @${GTS_USERNAME} from SQLite..."

GTS_DB_URI="file://${GTS_DB}?mode=ro&immutable=1"

PRIVATE_KEY_JSON=$(sqlite3 "$GTS_DB_URI" \
	"SELECT private_key FROM accounts WHERE username='${GTS_USERNAME}' AND domain IS NULL LIMIT 1;")
PUBLIC_KEY_JSON=$(sqlite3 "$GTS_DB_URI" \
	"SELECT public_key FROM accounts WHERE username='${GTS_USERNAME}' AND domain IS NULL LIMIT 1;")

[[ -n "$PRIVATE_KEY_JSON" ]] || error "private_key is empty — check GTS_USERNAME."
[[ -n "$PUBLIC_KEY_JSON" ]] || error "public_key is empty."

info "Converting JSON-encoded RSA keys to PEM (fetching cryptography via nix)..."
PRIVATE_KEY=$(echo "$PRIVATE_KEY_JSON" | json_to_pem private)
PUBLIC_KEY=$(echo "$PUBLIC_KEY_JSON" | json_to_pem public)

[[ "$PRIVATE_KEY" == *"BEGIN"* ]] || error "PEM conversion failed for private key."
[[ "$PUBLIC_KEY" == *"BEGIN"* ]] || error "PEM conversion failed for public key."
info "Conversion OK."

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
warn "Create @${GTS_USERNAME} in the Sharkey setup wizard:"
warn "  https://${AP_HOSTNAME}  (first run triggers the setup wizard)"
warn "  Username must be exactly: ${GTS_USERNAME}"
read -r -p "$(echo -e "${YELLOW}Press Enter once the account exists...${NC}")"

SHARKEY_USER_ID=$(sudo -u postgres psql -d "$SHARKEY_DB" -tA \
	-c "SELECT id FROM \"user\" WHERE username='${GTS_USERNAME}' AND host IS NULL LIMIT 1;" 2>/dev/null || true)
SHARKEY_USER_ID="${SHARKEY_USER_ID// /}"

[[ -n "$SHARKEY_USER_ID" ]] || error "@${GTS_USERNAME} not found in Sharkey DB — create the account first."
info "Sharkey user ID: ${SHARKEY_USER_ID}"

# ── Step 4: Inject old RSA keypair into user_keypair ─────────────────────────
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
