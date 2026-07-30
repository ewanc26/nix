#!/usr/bin/env bash
# Audits all sops secrets in the nix-config repo.
#
# Secrets are encrypted to two kinds of recipient (see .sops.yaml): your PGP key
# and each host's age key. This reports both, plus decryptability.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
cd "$REPO_ROOT"

SERVER_KEY="age1xvny7h8cahajamj4lz9cew5w0dqlge0yy6tys7szj42grcrl95jqsrutsu"

# User PGP fingerprint, read from .sops.yaml so there is one source of truth.
USER_PGP_FPR="$(awk '/&ewan_pgp/{print $3; exit}' .sops.yaml 2>/dev/null)"
if [ -z "$USER_PGP_FPR" ] || [ "$USER_PGP_FPR" = "REPLACE_WITH_YOUR_PGP_FINGERPRINT" ]; then
  echo "✗ .sops.yaml has no usable PGP fingerprint for &ewan_pgp."
  echo "  Fill in the placeholder before auditing — see docs/secrets.md."
  exit 1
fi

# The age key is only needed to open secrets not yet rekeyed to PGP.
[ -s "$HOME/.config/age/keys.txt" ] && export SOPS_AGE_KEY_FILE="$HOME/.config/age/keys.txt"

PASS=0
FAIL=0

check_secret() {
  local file="$1"
  local expected_format="$2"
  echo "── $file ──────────────────────────────"

  # sops metadata is always in a JSON sidecar regardless of file format.
  # For dotenv/binary files, extract the sops block from the file directly.
  local sops_json
  if [[ "$expected_format" == "json" ]]; then
    if ! jq empty "$file" 2>/dev/null; then
      echo "  ✗ Not valid JSON — may be corrupted"
      ((FAIL++)); return
    fi
    sops_json=$(jq '.sops' "$file" 2>/dev/null)
  else
    # dotenv/binary: sops appends a JSON block at the end after a blank line
    sops_json=$(awk '/^sops:/{found=1} found{print}' "$file" 2>/dev/null || true)
    if [ -z "$sops_json" ]; then
      # fallback: try treating whole file as JSON anyway
      sops_json=$(jq '.sops' "$file" 2>/dev/null || echo "{}")
    fi
  fi

  local age_count pgp_count
  age_count=$(echo "$sops_json" | jq '.age | length' 2>/dev/null || echo "0")
  pgp_count=$(echo "$sops_json" | jq '.pgp | length' 2>/dev/null || echo "0")
  echo "  Recipients: ${age_count:-0} age, ${pgp_count:-0} pgp"

  if echo "$sops_json" | jq -r '.pgp[].fp' 2>/dev/null \
      | grep -qi "$USER_PGP_FPR"; then
    echo "  ✓ User PGP key present"
  else
    echo "  ✗ User PGP key MISSING — run ./secrets/setup.sh --rekey-only"
    ((FAIL++))
  fi

  if echo "$sops_json" | jq -r '.age[].recipient' 2>/dev/null | grep -q "$SERVER_KEY"; then
    echo "  ✓ Server key present"
  else
    echo "  ✗ Server key MISSING"
    ((FAIL++))
  fi

  local modified
  modified=$(echo "$sops_json" | jq -r '.lastmodified' 2>/dev/null || echo "unknown")
  echo "  Last modified: $modified"

  # sops tries every recipient it holds a key for, so this exercises the PGP
  # path on a rekeyed file and the age path on one that has not been rekeyed.
  local plaintext
  plaintext=$(nix run nixpkgs#sops -- decrypt --output-type binary "$file" 2>&1)
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    if echo "$plaintext" | grep -q '"data": "ENC\['; then
      echo "  ✗ Decrypted to raw SOPS JSON — encrypted with wrong format (expected: $expected_format)"
      ((FAIL++))
    else
      echo "  ✓ Decrypts successfully"
      ((PASS++))
    fi
  else
    echo "  ✗ Decryption failed: $plaintext"
    ((FAIL++))
  fi
  echo ""
}

echo "Checking secrets..."
echo ""

check_secret secrets/pds.env        "dotenv"
check_secret secrets/forgejo.env    "dotenv"
check_secret secrets/cf-tunnel.json "json"

for f in secrets/*.env secrets/*.json secrets/*.token; do
  [[ "$f" == "secrets/pds.env" ]] && continue
  [[ "$f" == "secrets/forgejo.env" ]] && continue
  [[ "$f" == "secrets/cf-tunnel.json" ]] && continue
  [[ -f "$f" ]] && check_secret "$f" "unknown"
done

echo "══════════════════════════════════════"
echo "  Passed: $PASS  Failed: $FAIL"
