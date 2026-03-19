#!/usr/bin/env bash
# =============================================================================
#  cleanup-service-data.sh
#
#  Removes residual on-disk data from services that have been uninstalled
#  (i.e., disabled in NixOS config and no longer running).
#
#  For each known service the script checks:
#    1. Whether the service unit is currently active or enabled — if so,
#       the service is live and its data is NEVER touched.
#    2. Whether the data path(s) exist on disk.
#    3. For PostgreSQL-backed services, whether the DB still exists.
#
#  Nothing is deleted without explicit per-service confirmation.
#
#  Run as root on the NixOS server.
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
skip() { echo -e "${CYAN}[SKIP]${NC}  $*"; }
removed() { echo -e "${RED}[DEL]${NC}   $*"; }
section() { echo -e "\n${BOLD}── $* ${NC}"; }
confirm() {
	read -r -p "$(echo -e "${YELLOW}  ${1} [y/N] ${NC}")" r
	[[ "${r,,}" == "y" ]]
}

[[ "$(id -u)" -eq 0 ]] || {
	echo -e "${RED}Run as root.${NC}" >&2
	exit 1
}

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && warn "Dry-run mode — nothing will be deleted."

# ── Helpers ───────────────────────────────────────────────────────────────────

# Returns 0 if the systemd service is active or enabled (i.e., still live).
service_live() {
	local unit="$1"
	systemctl is-active --quiet "$unit" 2>/dev/null ||
		systemctl is-enabled --quiet "$unit" 2>/dev/null
}

# Removes a directory, respecting dry-run.
remove_dir() {
	local path="$1"
	if [[ ! -d "$path" ]]; then return; fi
	local size
	size=$(du -sh "$path" 2>/dev/null | cut -f1 || echo "?")
	if $DRY_RUN; then
		warn "  DRY-RUN: would remove $path ($size)"
	else
		rm -rf "$path"
		removed "$path ($size freed)"
	fi
}

# Drops a PostgreSQL database if it exists.
drop_pg_db() {
	local db="$1"
	local exists
	exists=$(sudo -u postgres psql -tA -c \
		"SELECT 1 FROM pg_database WHERE datname='${db}';" 2>/dev/null || echo "")
	if [[ "$exists" != "1" ]]; then
		skip "  PostgreSQL DB '${db}' does not exist — nothing to drop."
		return
	fi
	if $DRY_RUN; then
		warn "  DRY-RUN: would drop PostgreSQL DB '${db}'"
	else
		sudo -u postgres dropdb "$db"
		removed "  PostgreSQL DB '${db}' dropped."
	fi
}

# Drops a PostgreSQL role if it exists and has no remaining owned objects.
drop_pg_role() {
	local role="$1"
	local exists
	exists=$(sudo -u postgres psql -tA -c \
		"SELECT 1 FROM pg_roles WHERE rolname='${role}';" 2>/dev/null || echo "")
	if [[ "$exists" != "1" ]]; then return; fi
	if $DRY_RUN; then
		warn "  DRY-RUN: would drop PostgreSQL role '${role}'"
	else
		if sudo -u postgres dropuser "$role" 2>/dev/null; then
			removed "  PostgreSQL role '${role}' dropped."
		else
			warn "  Could not drop role '${role}' (may still own objects)."
		fi
	fi
}

# ── Service definitions ───────────────────────────────────────────────────────
# Each entry: check_unit  display_name  pg_db(or-)  dirs...

declare -A SVC_LABELS=(
	[gotosocial]="GoToSocial (ActivityPub)"
	[sharkey]="Sharkey (ActivityPub)"
	[forgejo]="Forgejo (Git forge)"
	[nextcloud]="Nextcloud"
	[immich - server]="Immich (photos)"
	[jellyfin]="Jellyfin"
	[vaultwarden]="Vaultwarden"
	[bluesky - pds]="Bluesky PDS (ATProto)"
	[samba - smbd]="Time Machine (Samba)"
	[grafana]="Grafana"
	[prometheus]="Prometheus"
)

# unit → "pg_db:pg_role dir1 dir2 ..."  (- means no PostgreSQL)
declare -A SVC_DATA=(
	[gotosocial]="-:/srv/gotosocial"
	[sharkey]="sharkey:sharkey /srv/sharkey"
	[forgejo]="-:/srv/forgejo"
	[nextcloud]="nextcloud:nextcloud /srv/nextcloud"
	[immich - server]="immich:immich /srv/immich"
	# Jellyfin: /var/lib/jellyfin is config/metadata — the media dir
	# (/srv/nextcloud/data/.../Media) is shared with Nextcloud and is NOT cleaned.
	[jellyfin]="-:/var/lib/jellyfin"
	[vaultwarden]="-:/srv/vaultwarden"
	[bluesky - pds]="-:/srv/bluesky-pds"
	[samba - smbd]="-:/srv/timemachine"
	[grafana]="-:/var/lib/grafana"
	[prometheus]="-:/var/lib/prometheus2"
)

# ── Main loop ─────────────────────────────────────────────────────────────────
FOUND=0

for unit in "${!SVC_DATA[@]}"; do
	label="${SVC_LABELS[$unit]}"
	entry="${SVC_DATA[$unit]}"

	# Parse "pg_db:pg_role dir1 dir2 ..."
	pg_part="${entry%%:*}"
	dirs_raw="${entry#*:}"
	IFS=' ' read -r -a dirs <<<"$dirs_raw"

	# Determine whether any data actually exists on disk
	data_present=false
	for d in "${dirs[@]}"; do
		[[ -d "$d" ]] && data_present=true && break
	done

	# Also check for PostgreSQL DB if applicable
	pg_present=false
	pg_db=""
	pg_role=""
	if [[ "$pg_part" != "-" ]]; then
		pg_db="${pg_part%%/*}"
		pg_role="${pg_part##*/}"
		# Only check if psql is available
		if command -v psql &>/dev/null; then
			exists=$(sudo -u postgres psql -tA -c \
				"SELECT 1 FROM pg_database WHERE datname='${pg_db}';" 2>/dev/null || echo "")
			[[ "$exists" == "1" ]] && pg_present=true
		fi
	fi

	$data_present || $pg_present || continue

	FOUND=$((FOUND + 1))
	section "$label"

	# ── Guard: skip if service is still live ──────────────────────────────
	if service_live "$unit"; then
		skip "$unit is still active/enabled — skipping."
		continue
	fi

	# Show what was found
	for d in "${dirs[@]}"; do
		if [[ -d "$d" ]]; then
			size=$(du -sh "$d" 2>/dev/null | cut -f1 || echo "?")
			echo -e "  ${CYAN}dir${NC}  $d  ($size)"
		fi
	done
	if $pg_present; then
		echo -e "  ${CYAN}pg${NC}   database: $pg_db  role: $pg_role"
	fi

	# ── Confirm and remove ────────────────────────────────────────────────
	confirm "Remove all data for $label?" || {
		skip "Skipped."
		continue
	}

	for d in "${dirs[@]}"; do
		remove_dir "$d"
	done

	if $pg_present; then
		drop_pg_db "$pg_db"
		drop_pg_role "$pg_role"
	fi

	info "Cleaned up $label."
done

# ── /root key backups from migration ──────────────────────────────────────────
KEYPAIR_BACKUPS=(/root/gts-keypair-*.env)
if [[ -f "${KEYPAIR_BACKUPS[0]}" ]]; then
	section "GTS keypair migration backups"
	for f in "${KEYPAIR_BACKUPS[@]}"; do
		[[ -f "$f" ]] || continue
		echo -e "  ${CYAN}file${NC} $f"
	done
	if confirm "Remove GTS keypair backup(s) from /root?"; then
		for f in "${KEYPAIR_BACKUPS[@]}"; do
			[[ -f "$f" ]] || continue
			if $DRY_RUN; then
				warn "  DRY-RUN: would remove $f"
			else
				rm -f "$f"
				removed "$f"
			fi
		done
	else
		skip "Skipped."
	fi
fi

# ── GTS .nix.bak ──────────────────────────────────────────────────────────────
BAK_DIR="$(dirname "$(realpath "$0")")"
GTS_BAK="${BAK_DIR}/../modules/server/gotosocial.nix.bak"
GTS_BAK="$(realpath --canonicalize-missing "$GTS_BAK")"
if [[ -f "$GTS_BAK" ]]; then
	section "GTS module backup"
	echo -e "  ${CYAN}file${NC} $GTS_BAK"
	if confirm "Remove gotosocial.nix.bak?"; then
		if $DRY_RUN; then
			warn "  DRY-RUN: would remove $GTS_BAK"
		else
			rm -f "$GTS_BAK"
			removed "$GTS_BAK"
		fi
	else
		skip "Skipped."
	fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
if [[ "$FOUND" -eq 0 ]]; then
	info "No residual service data found."
else
	info "Done."
fi
