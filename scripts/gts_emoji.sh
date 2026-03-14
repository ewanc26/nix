#!/usr/bin/env bash
# upload-emojis.sh
# Bulk-upload custom emoji from fedi-emojis-main to a GoToSocial instance.
#
# Usage:
#   ./upload-emojis.sh [--clean] [--yes]
#
#   --clean   Delete ALL local custom emoji from the instance before uploading.
#             Prompts for confirmation unless --yes is also passed.
#   --all     Upload all packs without interactive selection.
#   --yes     Skip confirmation prompts (use with --clean or pack selection).
#
# On first run the script will:
#   1. Register an OAuth app with your GTS instance (cached for future runs)
#   2. Print an authorization URL — open it in your browser, log in, approve,
#      then paste the out-of-band code back into the terminal.
#   3. Exchange the code for a bearer token (cached for future runs).
#
# Cached credentials are stored in ~/.config/gts-emoji-uploader/
#
# Optional overrides (env vars):
#   GTS_TOKEN=<bearer_token>               (skip auto-auth entirely)
#   GTS_INSTANCE=https://ap.ewancroft.uk   (default)
#   EMOJI_DIR=/path/to/fedi-emojis-main    (default)
#   EMOJI_SIZE_LIMIT_KB=5120               (must match media-emoji-local-max-size in config; default 5 MiB)
#   DRY_RUN=1                              (print what would happen, no requests)
#
# Oversized emoji are automatically resized using ffmpeg if available.
# Server-side limit is set via media-emoji-local-max-size in gotosocial.nix.

set -euo pipefail

INSTANCE="${GTS_INSTANCE:-https://ap.ewancroft.uk}"
EMOJI_DIR="${EMOJI_DIR:-/Users/ewan/Developer/Other/fedi-emojis-main}"
ENDPOINT="${INSTANCE}/api/v1/admin/custom_emojis"
DRY_RUN="${DRY_RUN:-0}"

# Default matches media-emoji-local-max-size = 5242880 (5 MiB) in gotosocial.nix
EMOJI_SIZE_LIMIT_KB="${EMOJI_SIZE_LIMIT_KB:-5120}"
EMOJI_SIZE_LIMIT=$((EMOJI_SIZE_LIMIT_KB * 1024))

CACHE_DIR="${HOME}/.config/gts-emoji-uploader"
CREDS_FILE="${CACHE_DIR}/app_credentials"
TOKEN_FILE="${CACHE_DIR}/token"

CLEAN=0
YES=0
ALL_PACKS=0

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

for arg in "$@"; do
	case "$arg" in
	--clean) CLEAN=1 ;;
	--yes) YES=1 ;;
	--all) ALL_PACKS=1 ;;
	*)
		echo "Unknown argument: $arg" >&2
		echo "Usage: $0 [--clean] [--all] [--yes]" >&2
		exit 1
		;;
	esac
done

# ---------------------------------------------------------------------------
# OAuth helpers
# ---------------------------------------------------------------------------

register_app() {
	echo "Registering OAuth app with ${INSTANCE}..." >&2
	local response
	response=$(curl -sf -X POST "${INSTANCE}/api/v1/apps" \
		-H "Content-Type: application/json" \
		-d '{
      "client_name":   "gts-emoji-uploader",
      "redirect_uris": "urn:ietf:wg:oauth:2.0:oob",
      "scopes":        "admin",
      "website":       "https://ewancroft.uk"
    }')

	local client_id client_secret
	client_id=$(echo "$response" | grep -o '"client_id":"[^"]*"' | cut -d'"' -f4)
	client_secret=$(echo "$response" | grep -o '"client_secret":"[^"]*"' | cut -d'"' -f4)

	if [[ -z "$client_id" || -z "$client_secret" ]]; then
		echo "Error: failed to register app. Response:" >&2
		echo "$response" >&2
		exit 1
	fi

	mkdir -p "$CACHE_DIR"
	chmod 700 "$CACHE_DIR"
	printf 'CLIENT_ID=%s\nCLIENT_SECRET=%s\n' "$client_id" "$client_secret" >"$CREDS_FILE"
	chmod 600 "$CREDS_FILE"
	echo "App registered and credentials cached." >&2
}

fetch_token() {
	local client_id="$1"
	local client_secret="$2"

	local auth_url="${INSTANCE}/oauth/authorize?client_id=${client_id}&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&scope=admin"

	echo >&2
	echo "Open this URL in your browser to authorise the app:" >&2
	echo >&2
	echo "  ${auth_url}" >&2
	echo >&2

	if command -v open &>/dev/null; then
		open "$auth_url" 2>/dev/null || true
	fi

	read -rp "Paste the authorisation code here: " auth_code

	local response
	response=$(curl -sf -X POST "${INSTANCE}/oauth/token" \
		-H "Content-Type: application/json" \
		-d "{
      \"client_id\":     \"${client_id}\",
      \"client_secret\": \"${client_secret}\",
      \"redirect_uri\":  \"urn:ietf:wg:oauth:2.0:oob\",
      \"grant_type\":    \"authorization_code\",
      \"code\":          \"${auth_code}\"
    }")

	local token
	token=$(echo "$response" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

	if [[ -z "$token" ]]; then
		echo "Error: failed to obtain token. Response:" >&2
		echo "$response" >&2
		exit 1
	fi

	mkdir -p "$CACHE_DIR"
	chmod 700 "$CACHE_DIR"
	printf '%s\n' "$token" >"$TOKEN_FILE"
	chmod 600 "$TOKEN_FILE"
	echo "Token obtained and cached at ${TOKEN_FILE}." >&2
	echo "$token"
}

ensure_token() {
	if [[ -n "${GTS_TOKEN:-}" ]]; then
		return
	fi

	if [[ -f "$TOKEN_FILE" ]]; then
		GTS_TOKEN="$(cat "$TOKEN_FILE")"
		echo "Using cached token from ${TOKEN_FILE}." >&2
		return
	fi

	if [[ ! -f "$CREDS_FILE" ]]; then
		register_app
	fi

	# Declare vars so shellcheck knows they exist after sourcing.
	CLIENT_ID=""
	CLIENT_SECRET=""
	# shellcheck source=/dev/null
	source "$CREDS_FILE"

	GTS_TOKEN="$(fetch_token "$CLIENT_ID" "$CLIENT_SECRET")"
}

# ---------------------------------------------------------------------------
# Rate-limit helpers
# ---------------------------------------------------------------------------

# Parse X-RateLimit-Reset into a Unix timestamp.
# GTS sends an ISO 8601 string e.g. "2026-03-14T17:23:26.000Z".
# Falls back gracefully if the value is already a plain integer.
parse_reset_timestamp() {
	local raw="$1"
	# Plain integer — already a Unix timestamp
	if [[ "$raw" =~ ^[0-9]+$ ]]; then
		echo "$raw"
		return
	fi
	# ISO 8601 — convert via date
	if command -v date &>/dev/null; then
		# macOS date requires -j -f; GNU date accepts --date or -d
		local ts
		if date --version &>/dev/null 2>&1; then
			# GNU date
			ts=$(date -d "$raw" +%s 2>/dev/null || true)
		else
			# BSD/macOS date — strip trailing Z and sub-second part
			local clean="${raw%.*}"
			clean="${clean%Z}"
			ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null || true)
		fi
		[[ -n "$ts" && "$ts" =~ ^[0-9]+$ ]] && echo "$ts" && return
	fi
	# Could not parse — return empty
	echo ""
}

# Calculate seconds to sleep until the rate-limit window resets.
# Reads X-RateLimit-Reset (ISO 8601 or Unix) or Retry-After (delta seconds).
# Falls back to 60s if neither header is parseable.
rate_limit_sleep_time() {
	local headers_file="$1"
	local wait=60

	local reset_raw retry_after
	reset_raw=$(grep -i '^x-ratelimit-reset:' "$headers_file" 2>/dev/null |
		head -1 | sed 's/^[^:]*: *//' | tr -d '[:space:]\r' || true)
	retry_after=$(grep -i '^retry-after:' "$headers_file" 2>/dev/null |
		head -1 | tr -d '[:space:]\r' | cut -d':' -f2 || true)

	if [[ -n "$reset_raw" ]]; then
		local reset_ts
		reset_ts=$(parse_reset_timestamp "$reset_raw")
		if [[ -n "$reset_ts" ]]; then
			local now
			now=$(date +%s)
			wait=$((reset_ts - now + 1))
			((wait < 1)) && wait=1
			echo "$wait"
			return
		fi
	fi

	if [[ -n "$retry_after" && "$retry_after" =~ ^[0-9]+$ ]]; then
		echo "$retry_after"
		return
	fi

	echo "$wait"
}

# Call after every API response. Reads X-RateLimit-Remaining from the given
# headers file and sleeps until the window resets if the bucket is exhausted.
# Pass an optional label (e.g. ":shortcode:") for the log message.
respect_rate_limit() {
	local headers_file="$1"
	local label="${2:-}"

	local remaining
	remaining=$(grep -i '^x-ratelimit-remaining:' "$headers_file" 2>/dev/null |
		head -1 | tr -d '[:space:]\r' | cut -d':' -f2 || true)

	[[ -n "$remaining" && "$remaining" =~ ^[0-9]+$ ]] || return 0
	((remaining > 0)) && return 0

	local wait
	wait=$(rate_limit_sleep_time "$headers_file")
	echo "  [RATE] ${label:+$label — }bucket exhausted, sleeping ${wait}s until reset..." >&2
	sleep "$wait"
}

# ---------------------------------------------------------------------------
# Clean mode: delete all local custom emoji
# ---------------------------------------------------------------------------

delete_all_emoji() {
	echo "Fetching list of all local custom emoji..." >&2

	local all_ids=()
	local next_url="${ENDPOINT}?limit=80&filter=domain:local"

	while [[ -n "$next_url" ]]; do
		local http_status body
		http_status=$(curl -s --max-time 30 \
			-D /tmp/gts_list_headers.txt \
			-o /tmp/gts_emoji_list.json \
			-w "%{http_code}" \
			-X GET "$next_url" \
			-H "Authorization: Bearer $GTS_TOKEN")

		if [[ "$http_status" != "200" ]]; then
			echo "Error: failed to list emoji (HTTP ${http_status})." >&2
			cat /tmp/gts_emoji_list.json >&2
			exit 1
		fi

		respect_rate_limit /tmp/gts_list_headers.txt

		body=$(cat /tmp/gts_emoji_list.json)

		local page_ids=()
		mapfile -t page_ids < <(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)

		[[ ${#page_ids[@]} -eq 0 ]] && break

		all_ids+=("${page_ids[@]}")

		local link_next
		link_next=$(grep -i '^link:' /tmp/gts_list_headers.txt 2>/dev/null |
			grep -o '<[^>]*>; rel="next"' |
			grep -o 'https\?://[^>]*' || true)

		next_url="$link_next"
		[[ ${#page_ids[@]} -lt 80 || -z "$next_url" ]] && break
	done

	local count=${#all_ids[@]}

	if [[ $count -eq 0 ]]; then
		echo "No local custom emoji found — nothing to delete." >&2
		return
	fi

	echo "Found ${count} local custom emoji." >&2

	if [[ "$YES" -ne 1 ]]; then
		read -rp "Delete all ${count} emoji? This cannot be undone. [y/N] " confirm
		[[ "${confirm,,}" == "y" ]] || {
			echo "Aborted." >&2
			exit 0
		}
	fi

	if [[ "$DRY_RUN" == "1" ]]; then
		echo "[DRY] Would delete ${count} emoji." >&2
		return
	fi

	local deleted=0 del_failed=0
	for id in "${all_ids[@]}"; do
		local status
		status=$(curl -s --max-time 30 \
			-D /tmp/gts_del_headers.txt \
			-o /tmp/gts_del_response.json \
			-w "%{http_code}" \
			-X DELETE "${ENDPOINT}/${id}" \
			-H "Authorization: Bearer $GTS_TOKEN")

		if [[ "$status" == "200" || "$status" == "204" ]]; then
			((deleted++)) || true
			echo "  [DEL]  ${id}"
		else
			local err
			err=$(cat /tmp/gts_del_response.json 2>/dev/null || echo '{}')
			echo "  [FAIL] delete ${id} — HTTP ${status}: ${err}" >&2
			((del_failed++)) || true
		fi

		respect_rate_limit /tmp/gts_del_headers.txt
	done

	echo >&2
	echo "Deleted: ${deleted}  Failed: ${del_failed}" >&2
	echo >&2
}

# ---------------------------------------------------------------------------
# Upload helpers
# ---------------------------------------------------------------------------

shrink_emoji() {
	local file="$1"
	local ext="$2"

	command -v ffmpeg &>/dev/null || return 1

	local tmp="/tmp/gts_emoji_resized.${ext}"

	for scale in 0.75 0.5 0.35; do
		local vf="scale=trunc(iw*${scale}/2)*2:trunc(ih*${scale}/2)*2:flags=lanczos"
		case "${ext,,}" in
		gif)
			ffmpeg -y -loglevel error -i "$file" -vf "$vf" "$tmp" 2>/dev/null || return 1
			;;
		jpg | jpeg)
			ffmpeg -y -loglevel error -i "$file" -vf "$vf" -q:v 4 "$tmp" 2>/dev/null || return 1
			;;
		*)
			ffmpeg -y -loglevel error -i "$file" -vf "$vf" "$tmp" 2>/dev/null || return 1
			;;
		esac

		local newsize
		newsize=$(wc -c <"$tmp")
		if ((newsize <= EMOJI_SIZE_LIMIT)); then
			echo "$tmp"
			return 0
		fi
	done

	return 1
}

# POST an emoji. On 429, reads rate-limit headers to sleep the exact right
# amount before retrying. On every response, proactively checks remaining quota.
# Outputs two lines: HTTP status, then response body.
post_emoji() {
	local upload_file="$1"
	local upload_filename="$2"
	local mime="$3"
	local shortcode="$4"
	local category="$5"

	local max_retries=4

	for ((attempt = 0; attempt <= max_retries; attempt++)); do
		local http_status response
		http_status=$(curl -s --max-time 60 \
			-D /tmp/gts_upload_headers.txt \
			-o /tmp/gts_emoji_response.json \
			-w "%{http_code}" \
			-X POST "$ENDPOINT" \
			-H "Authorization: Bearer $GTS_TOKEN" \
			-F "shortcode=${shortcode}" \
			-F "category=${category}" \
			-F "image=@${upload_file};filename=${upload_filename};type=${mime}")
		response="$(cat /tmp/gts_emoji_response.json 2>/dev/null || echo '{}')"

		if [[ "$http_status" == "429" && $attempt -lt $max_retries ]]; then
			local wait
			wait=$(rate_limit_sleep_time /tmp/gts_upload_headers.txt)
			echo "  [WAIT] :${shortcode}: — 429 rate limited, sleeping ${wait}s..." >&2
			sleep "$wait"
			continue
		fi

		# Proactively pause if the bucket is now empty
		respect_rate_limit /tmp/gts_upload_headers.txt ":${shortcode}:"

		printf '%s\n%s\n' "$http_status" "$response"
		return
	done
}

# ---------------------------------------------------------------------------
# Upload
# ---------------------------------------------------------------------------

ok=0
skipped=0
failed=0
total=0

upload_emoji() {
	local file="$1"
	local category="$2"
	local filename shortcode ext mime

	filename="$(basename "$file")"
	ext="${filename##*.}"
	shortcode="${filename%.*}"

	case "${ext,,}" in
	png) mime="image/png" ;;
	gif) mime="image/gif" ;;
	webp) mime="image/webp" ;;
	jpg | jpeg) mime="image/jpeg" ;;
	*)
		echo "  [SKIP] $filename — unsupported extension"
		((skipped++)) || true
		return
		;;
	esac

	((total++)) || true

	if [[ "$DRY_RUN" == "1" ]]; then
		echo "  [DRY]  :${shortcode}: (${category}) ← ${filename}"
		((ok++)) || true
		return
	fi

	local upload_file="$file"
	local filesize
	filesize=$(wc -c <"$file")

	if ((filesize > EMOJI_SIZE_LIMIT)); then
		local shrunk
		if shrunk=$(shrink_emoji "$file" "$ext") && [[ -n "$shrunk" ]]; then
			local orig_kb=$((filesize / 1024))
			local new_kb=$(($(wc -c <"$shrunk") / 1024))
			echo "  [SHRK] :${shortcode}: — resized ${orig_kb}KB → ${new_kb}KB"
			upload_file="$shrunk"
		else
			echo "  [SKIP] :${shortcode}: — $((filesize / 1024))KB > ${EMOJI_SIZE_LIMIT_KB}KB limit (ffmpeg resize failed or unavailable)"
			((skipped++)) || true
			return
		fi
	fi

	local result http_status response
	result=$(post_emoji "$upload_file" "$filename" "$mime" "$shortcode" "$category")
	http_status=$(echo "$result" | head -1)
	response=$(echo "$result" | tail -n +2)

	case "$http_status" in
	200 | 201)
		echo "  [OK]   :${shortcode}: (${category})"
		((ok++)) || true
		;;
	401)
		echo "  [FAIL] :${shortcode}: — 401 Unauthorised (token may be expired)" >&2
		echo "  Hint: delete ${TOKEN_FILE} and re-run to get a fresh token." >&2
		((failed++)) || true
		;;
	422)
		local error
		error="$(echo "$response" | grep -o '"error":"[^"]*"' | head -1 || echo 'unknown')"
		echo "  [SKIP] :${shortcode}: — 422 ${error}"
		((skipped++)) || true
		;;
	413)
		echo "  [SKIP] :${shortcode}: — 413 file too large (raise media-emoji-local-max-size in gotosocial.nix)"
		((skipped++)) || true
		;;
	429)
		echo "  [FAIL] :${shortcode}: — 429 rate limited after max retries"
		((failed++)) || true
		;;
	*)
		local error
		error="$(echo "$response" | grep -o '"error":"[^"]*"' | head -1 || echo 'unknown')"
		echo "  [FAIL] :${shortcode}: — HTTP ${http_status} ${error}"
		((failed++)) || true
		;;
	esac
}

# ---------------------------------------------------------------------------
# Pack selection
# ---------------------------------------------------------------------------

# Builds SELECTED_PACKS (associative set) and DESELECTED_PACKS arrays.
# Uses fzf if available; falls back to a numbered toggle prompt.
select_packs() {
	local -a all_packs=()
	for pack_dir in "$EMOJI_DIR"/*/; do
		[[ -d "$pack_dir" ]] || continue
		all_packs+=("$(basename "$pack_dir")")
	done

	if [[ ${#all_packs[@]} -eq 0 ]]; then
		echo "Error: no pack directories found in $EMOJI_DIR" >&2
		exit 1
	fi

	if [[ "$ALL_PACKS" -eq 1 ]]; then
		for p in "${all_packs[@]}"; do SELECTED_PACKS["$p"]=1; done
		return
	fi

	local chosen
	if command -v fzf &>/dev/null; then
		# fzf multi-select: TAB to toggle, ENTER to confirm
		chosen=$(printf '%s\n' "${all_packs[@]}" |
			fzf --multi \
				--prompt='Select packs (TAB to toggle, ENTER to confirm): ' \
				--height=50% \
				--layout=reverse \
				--bind='ctrl-a:toggle-all' \
				--header='CTRL-A: toggle all' 2>/dev/tty) || {
			echo "No packs selected — aborting." >&2
			exit 0
		}
		while IFS= read -r p; do
			[[ -n "$p" ]] && SELECTED_PACKS["$p"]=1
		done <<<"$chosen"
	else
		# Fallback: numbered toggle menu
		local -a selected_flags=()
		for _ in "${all_packs[@]}"; do selected_flags+=(1); done

		while true; do
			echo >&2
			echo "Select packs to upload (deselected packs will have their emoji deleted)." >&2
			echo "Enter a number to toggle, 'a' to toggle all, or 'done' to confirm." >&2
			echo >&2
			for i in "${!all_packs[@]}"; do
				local mark
				[[ "${selected_flags[$i]}" -eq 1 ]] && mark="[x]" || mark="[ ]"
				printf '  %2d  %s  %s\n' "$((i + 1))" "$mark" "${all_packs[$i]}" >&2
			done
			echo >&2
			read -rp '> ' choice </dev/tty
			case "$choice" in
			done | '')
				break
				;;
			a)
				local any_on=0
				for f in "${selected_flags[@]}"; do ((f)) && any_on=1 && break; done
				for i in "${!selected_flags[@]}"; do
					((any_on)) && selected_flags[i]=0 || selected_flags[i]=1
				done
				;;
			*[0-9]*)
				local idx=$((choice - 1))
				if ((idx >= 0 && idx < ${#all_packs[@]})); then
					((selected_flags[idx])) && selected_flags[idx]=0 || selected_flags[idx]=1
				else
					echo "  Invalid choice." >&2
				fi
				;;
			*)
				echo "  Invalid choice." >&2
				;;
			esac
		done

		for i in "${!all_packs[@]}"; do
			[[ "${selected_flags[$i]}" -eq 1 ]] && SELECTED_PACKS["${all_packs[$i]}"]=1
		done
	fi

	if [[ ${#SELECTED_PACKS[@]} -eq 0 ]]; then
		echo "No packs selected — aborting." >&2
		exit 0
	fi

	# Build the deselected list
	for p in "${all_packs[@]}"; do
		[[ -v SELECTED_PACKS["$p"] ]] || DESELECTED_PACKS+=("$p")
	done
}

# Fetch all local emoji in a given category and delete them.
delete_category_emoji() {
	local category="$1"
	echo "  Removing existing emoji in category '${category}'..."

	local next_url="${ENDPOINT}?limit=80&filter=domain:local,category:${category}"

	while [[ -n "$next_url" ]]; do
		local http_status body
		http_status=$(curl -s --max-time 30 \
			-D /tmp/gts_list_headers.txt \
			-o /tmp/gts_emoji_list.json \
			-w "%{http_code}" \
			-X GET "$next_url" \
			-H "Authorization: Bearer $GTS_TOKEN")

		if [[ "$http_status" != "200" ]]; then
			echo "  [FAIL] list category '${category}' — HTTP ${http_status}" >&2
			return
		fi

		body=$(cat /tmp/gts_emoji_list.json)
		respect_rate_limit /tmp/gts_list_headers.txt

		local -a page_ids=()
		mapfile -t page_ids < <(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
		[[ ${#page_ids[@]} -eq 0 ]] && break

		for id in "${page_ids[@]}"; do
			if [[ "$DRY_RUN" == "1" ]]; then
				echo "  [DRY]  would delete emoji ${id} (category: ${category})"
				continue
			fi
			local del_status
			del_status=$(curl -s --max-time 30 \
				-D /tmp/gts_del_headers.txt \
				-o /tmp/gts_del_response.json \
				-w "%{http_code}" \
				-X DELETE "${ENDPOINT}/${id}" \
				-H "Authorization: Bearer $GTS_TOKEN")
			if [[ "$del_status" == "200" || "$del_status" == "204" ]]; then
				echo "  [DEL]  emoji ${id}"
			else
				echo "  [FAIL] delete emoji ${id} — HTTP ${del_status}" >&2
			fi
			respect_rate_limit /tmp/gts_del_headers.txt
		done

		local link_next
		link_next=$(grep -i '^link:' /tmp/gts_list_headers.txt 2>/dev/null |
			grep -o '<[^>]*>; rel="next"' |
			grep -o 'https\?://[^>]*' || true)
		next_url="$link_next"
		[[ ${#page_ids[@]} -lt 80 || -z "$next_url" ]] && break
	done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

ensure_token

if [[ ! -d "$EMOJI_DIR" ]]; then
	echo "Error: EMOJI_DIR not found: $EMOJI_DIR" >&2
	exit 1
fi

# Associative set of selected pack names; array of deselected ones.
declare -A SELECTED_PACKS=()
declare -a DESELECTED_PACKS=()

select_packs

echo
echo "GoToSocial emoji uploader"
echo "  instance    : $INSTANCE"
echo "  emoji dir   : $EMOJI_DIR"
echo "  size limit  : ${EMOJI_SIZE_LIMIT_KB}KB"
echo "  dry run     : $DRY_RUN"
echo "  clean       : $CLEAN"
echo "  ffmpeg      : $(command -v ffmpeg 2>/dev/null || echo 'not found — oversized emoji will be skipped')"
echo "  selected    : ${!SELECTED_PACKS[*]}"
echo "  deselected  : ${DESELECTED_PACKS[*]:-none}"
echo

if [[ "$CLEAN" -eq 1 ]]; then
	delete_all_emoji
elif [[ ${#DESELECTED_PACKS[@]} -gt 0 ]]; then
	if [[ "$YES" -ne 1 ]]; then
		echo "The following pack categories will have their emoji deleted from the instance:"
		printf '  %s\n' "${DESELECTED_PACKS[@]}"
		read -rp "Proceed? [y/N] " confirm </dev/tty
		[[ "${confirm,,}" == "y" ]] || {
			echo "Aborted." >&2
			exit 0
		}
		echo
	fi
	for category in "${DESELECTED_PACKS[@]}"; do
		echo "── Removing deselected pack: ${category}"
		delete_category_emoji "$category"
		echo
	done
fi

for pack_dir in "$EMOJI_DIR"/*/; do
	[[ -d "$pack_dir" ]] || continue
	category="$(basename "$pack_dir")"
	[[ -v SELECTED_PACKS["$category"] ]] || continue

	echo "── Pack: ${category}"

	for file in "$pack_dir"*; do
		[[ -f "$file" ]] || continue
		upload_emoji "$file" "$category"
	done

	echo
done

echo "Done."
echo "  uploaded : $ok"
echo "  skipped  : $skipped"
echo "  failed   : $failed"
echo "  total    : $total"
