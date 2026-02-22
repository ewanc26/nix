#!/usr/bin/env bash
# Audits all sops secrets in the nix-config repo.
# Reports: format, recipient count, whether server key is present, and decryptability.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
cd "$REPO_ROOT"

SERVER_KEY="age1xvny7h8cahajamj4lz9cew5w0dqlge0yy6tys7szj42grcrl95jqsrutsu"
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

  local count
  count=$(echo "$sops_json" | jq '.age | length' 2>/dev/null || echo "0")
  echo "  Recipients: $count"

  if echo "$sops_json" | jq -r '.age[].recipient' 2>/dev/null | grep -q "$SERVER_KEY"; then
    echo "  ✓ Server key present"
  else
    echo "  ✗ Server key MISSING"
    ((FAIL++))
  fi

  local modified
  modified=$(echo "$sops_json" | jq -r '.lastmodified' 2>/dev/null || echo "unknown")
  echo "  Last modified: $modified"

  local plaintext
  plaintext=$(SOPS_AGE_KEY_FILE=~/.config/age/keys.txt \
    nix run nixpkgs#sops -- decrypt --output-type binary "$file" 2>&1)
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
