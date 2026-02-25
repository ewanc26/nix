#!/usr/bin/env bash
# fix-acme-cert.sh — Full diagnose, rebuild, and fix for the Let's Encrypt
# wildcard cert (*.ewancroft.uk) on the NixOS server.
# Run on the server as root (or with sudo).
set -euo pipefail

OPENSSL="nix run nixpkgs#openssl --"

CERT_DIR="/var/lib/acme/ewancroft.uk"
SECRET_PATH="/run/secrets/cloudflare-acme.env"
ACME_SERVICE="acme-ewancroft.uk.service"
FLAKE="/home/ewan/.config/nix-config#server"

RED='\033[0;31m'
GRN='\033[0;32m'
YLW='\033[1;33m'
NC='\033[0m'

ok() { echo -e "${GRN}  ✔ $*${NC}"; }
fail() { echo -e "${RED}  ✘ $*${NC}"; }
info() { echo -e "${YLW}  → $*${NC}"; }
header() { echo -e "\n${YLW}══ $* ══${NC}"; }

die() {
	fail "$*"
	echo ""
	echo "  Aborting. Fix the issue above and re-run the script."
	exit 1
}

# ── Must run as root ──────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
	echo "Re-running with sudo..."
	exec sudo "$0" "$@"
fi

# ── Parse flags ───────────────────────────────────────────────────────────────
SKIP_REBUILD=false
for arg in "$@"; do
	case $arg in
	--skip-rebuild) SKIP_REBUILD=true ;;
	--help | -h)
		echo "Usage: $0 [--skip-rebuild]"
		echo "  --skip-rebuild   Skip nixos-rebuild switch (use if already rebuilt)"
		exit 0
		;;
	esac
done

# ─────────────────────────────────────────────────────────────────────────────
header "1. NixOS rebuild"
# ─────────────────────────────────────────────────────────────────────────────
if $SKIP_REBUILD; then
	info "Skipping rebuild (--skip-rebuild passed)"
else
	info "Running: nixos-rebuild switch --flake $FLAKE"
	if nixos-rebuild switch --flake "$FLAKE"; then
		ok "nixos-rebuild switch succeeded"
	else
		die "nixos-rebuild switch failed — fix the error above first"
	fi
fi

# ─────────────────────────────────────────────────────────────────────────────
header "2. Cloudflare API token"
# ─────────────────────────────────────────────────────────────────────────────
if [[ ! -f "$SECRET_PATH" ]]; then
	die "Secret not decrypted at $SECRET_PATH — the rebuild should have fixed this.\n    Check that secrets/cloudflare-acme.env is committed and sops-encrypted."
fi

TOKEN=$(cat "$SECRET_PATH")
if [[ -z "$TOKEN" ]]; then
	die "Secret file exists but is empty: $SECRET_PATH\n    Re-encrypt with: sops --encrypt --in-place secrets/cloudflare-acme.env"
fi
ok "Token present (${#TOKEN} chars)"

# ─────────────────────────────────────────────────────────────────────────────
header "3. acme user can read the token"
# ─────────────────────────────────────────────────────────────────────────────
if sudo -u acme cat "$SECRET_PATH" &>/dev/null; then
	ok "acme user can read $SECRET_PATH"
else
	die "acme user cannot read $SECRET_PATH\n    In caddy.nix ensure: owner = \"acme\"; mode = \"0440\";"
fi

# ─────────────────────────────────────────────────────────────────────────────
header "4. Current cert status"
# ─────────────────────────────────────────────────────────────────────────────
if [[ -f "$CERT_DIR/fullchain.pem" ]]; then
	EXPIRY=$($OPENSSL x509 -enddate -noout -in "$CERT_DIR/fullchain.pem" | cut -d= -f2)
	ISSUER=$($OPENSSL x509 -issuer -noout -in "$CERT_DIR/fullchain.pem" | sed 's/.*CN *= *//')
	ok "Cert exists — issuer: $ISSUER | expires: $EXPIRY"
	if echo "$ISSUER" | grep -qi "minica\|self"; then
		info "Cert is minica/self-signed — will replace with Let's Encrypt"
	fi
else
	info "No cert found at $CERT_DIR/fullchain.pem — will obtain a fresh one"
fi

# ─────────────────────────────────────────────────────────────────────────────
header "5. ACME service last status (pre-run)"
# ─────────────────────────────────────────────────────────────────────────────
systemctl status "$ACME_SERVICE" --no-pager -l 2>/dev/null ||
	info "Service has not run yet — that's fine"

# ─────────────────────────────────────────────────────────────────────────────
header "6. Triggering ACME cert acquisition"
# ─────────────────────────────────────────────────────────────────────────────
# Remove existing cert state so lego requests a fresh cert from Let's Encrypt
# rather than skipping because a (minica) cert already exists.
if [[ -d "$CERT_DIR" ]]; then
	info "Removing existing cert state to force fresh Let's Encrypt request..."
	rm -rf "$CERT_DIR"
	ok "Cleared $CERT_DIR"
fi

# ─────────────────────────────────────────────────────────────────────────────
header "6b. All ACME-related units"
# ─────────────────────────────────────────────────────────────────────────────
systemctl list-units "acme*" --all --no-pager || true

# ─────────────────────────────────────────────────────────────────────────────
header "6c. Generated acme service script"
# ─────────────────────────────────────────────────────────────────────────────
SCRIPT=$(systemctl show "$ACME_SERVICE" -p ExecStart --value | awk '{print $1}')
if [[ -n "$SCRIPT" && -f "$SCRIPT" ]]; then
	info "Script path: $SCRIPT"
	cat "$SCRIPT"
else
	info "Falling back to nix store search..."
	SCRIPT=$(find /nix/store -maxdepth 3 -name "acme-ewancroft.uk-start" 2>/dev/null | head -1)
	if [[ -n "$SCRIPT" ]]; then cat "$SCRIPT"; else fail "Script not found"; fi
fi

# ─────────────────────────────────────────────────────────────────────────────
header "6d. Triggering ACME (systemctl clean + start)"
# ─────────────────────────────────────────────────────────────────────────────
# systemctl clean --what=state is the official NixOS method: it removes the
# cert dir AND the lego accounts/state directory so the next start is a full
# fresh run rather than a renewal.
info "Cleaning all ACME state (official NixOS method)..."
systemctl clean --what=state "$ACME_SERVICE"
ok "State cleaned"

info "Starting $ACME_SERVICE — this may take ~30–90s (DNS propagation)..."
START_TIME=$(date --iso-8601=seconds)
if systemctl start "$ACME_SERVICE"; then
	ok "ACME service completed successfully"
else
	fail "ACME service failed"
	echo ""
	echo "  Full journal for this run:"
	journalctl -u "$ACME_SERVICE" --since "$START_TIME" --no-pager
	die "See journal output above for the root cause"
fi

info "Journal output from this run:"
journalctl -u "$ACME_SERVICE" --since "$START_TIME" --no-pager

# ─────────────────────────────────────────────────────────────────────────────
header "7. Verifying new cert"
# ─────────────────────────────────────────────────────────────────────────────
if [[ ! -f "$CERT_DIR/fullchain.pem" ]]; then
	die "Cert still missing at $CERT_DIR/fullchain.pem after ACME run"
fi

EXPIRY=$($OPENSSL x509 -enddate -noout -in "$CERT_DIR/fullchain.pem" | cut -d= -f2)
ISSUER=$($OPENSSL x509 -issuer -noout -in "$CERT_DIR/fullchain.pem" | sed 's/.*CN *= *//')
SAN=$($OPENSSL x509 -ext subjectAltName -noout -in "$CERT_DIR/fullchain.pem" 2>/dev/null |
	grep -o 'DNS:[^,]*' | head -1 || echo "unknown")

ok "Cert issued — issuer : $ISSUER"
ok "            SAN     : $SAN"
ok "            expires : $EXPIRY"

if echo "$ISSUER" | grep -qi "minica\|self"; then
	die "Cert is still minica/self-signed — something went wrong with the ACME run"
fi

# ─────────────────────────────────────────────────────────────────────────────
header "8. Reloading Caddy"
# ─────────────────────────────────────────────────────────────────────────────
if systemctl reload caddy 2>/dev/null || systemctl restart caddy; then
	ok "Caddy reloaded"
else
	fail "Caddy reload/restart failed"
	journalctl -u caddy -n 30 --no-pager
	die "Caddy failed to start with the new cert — check logs above"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GRN}══ All done! ══${NC}"
ok "cloud.ewancroft.uk and all other tailnet services should now show a"
ok "valid Let's Encrypt cert. If Firefox still warns, do a hard refresh"
ok "(Ctrl+Shift+R) or clear site data for the affected hostname."
