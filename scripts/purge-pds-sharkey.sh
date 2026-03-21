#!/usr/bin/env bash
# purge-pds-sharkey.sh
#
# Permanently deletes all data for the Bluesky PDS and Sharkey instances.
# Run this on the NixOS server AFTER nrs has applied the disabled config
# and confirmed both services are no longer running.
#
# !! THIS IS IRREVERSIBLE — double-check before running !!

set -euo pipefail

# ── Preflight ─────────────────────────────────────────────────────────────────

if [[ $EUID -ne 0 ]]; then
	echo "error: must be run as root (sudo $0)" >&2
	exit 1
fi

echo "==> Checking services are stopped..."

for svc in bluesky-pds pds-gatekeeper sharkey meilisearch; do
	if systemctl is-active --quiet "$svc" 2>/dev/null; then
		echo "error: $svc is still running — rebuild with services disabled first" >&2
		exit 1
	fi
done

echo "    All target services are inactive."
echo ""
echo "    The following will be permanently deleted:"
echo "      /srv/bluesky-pds           (PDS data directory)"
echo "      /srv/sharkey               (Sharkey media directory)"
echo "      PostgreSQL database:       sharkey"
echo "      PostgreSQL role:           sharkey"
echo "      /var/lib/meilisearch       (Meilisearch index data)"
echo "      /var/lib/private/sharkey   (Sharkey state, if present)"
echo ""
read -r -p "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
	echo "Aborted."
	exit 0
fi

# ── PDS ───────────────────────────────────────────────────────────────────────

echo ""
echo "==> Removing PDS data directory..."
rm -rf /srv/bluesky-pds
echo "    Done."

# ── PDS state (var/lib paths) ─────────────────────────────────────────────────

for p in /var/lib/bluesky-pds /var/lib/private/bluesky-pds; do
	if [[ -d "$p" ]]; then
		echo "==> Removing $p..."
		rm -rf "$p"
		echo "    Done."
	fi
done

# ── Sharkey media ─────────────────────────────────────────────────────────────

echo "==> Removing Sharkey media directory..."
rm -rf /srv/sharkey
echo "    Done."

# ── Sharkey state (DynamicUser path, if present) ──────────────────────────────

if [[ -d /var/lib/private/sharkey ]]; then
	echo "==> Removing /var/lib/private/sharkey..."
	rm -rf /var/lib/private/sharkey
	echo "    Done."
fi

if [[ -d /var/lib/sharkey ]]; then
	echo "==> Removing /var/lib/sharkey..."
	rm -rf /var/lib/sharkey
	echo "    Done."
fi

# ── Meilisearch ───────────────────────────────────────────────────────────────

echo "==> Removing Meilisearch data..."
rm -rf /var/lib/meilisearch
rm -rf /var/lib/private/meilisearch
echo "    Done."

# ── PostgreSQL ────────────────────────────────────────────────────────────────

echo "==> Dropping Sharkey PostgreSQL database and role..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS sharkey;" &&
	echo "    Dropped database 'sharkey'."
sudo -u postgres psql -c "DROP ROLE IF EXISTS sharkey;" &&
	echo "    Dropped role 'sharkey'."

# ── Redis ─────────────────────────────────────────────────────────────────────

echo ""
echo "NOTE: Redis data has NOT been touched."
echo "      If Sharkey had a dedicated Redis instance, flush it manually:"
echo "        redis-cli -n <db> FLUSHDB"
echo "      (The nixpkgs Sharkey module uses the default Redis instance"
echo "       with no DB isolation, so flushing blindly would affect other services.)"

# ── Done ──────────────────────────────────────────────────────────────────────

echo ""
echo "==> All done. PDS and Sharkey data have been purged."
