#!/usr/bin/env bash
# sharkey_emoji.sh
# Bulk-upload custom emoji from fedi-emojis-main to a Sharkey instance.
#
# Usage:
#   ./sharkey_emoji.sh [--clean] [--all] [--yes]
#
#   --clean   Delete ALL local custom emoji from the instance before uploading.
#             Prompts for confirmation unless --yes is also passed.
#   --all     Upload all packs without interactive selection.
#   --yes     Skip confirmation prompts.
#
# On first run the script will:
#   1. Generate a MiAuth session and print an authorisation URL — open it in
#      your browser, log in, approve, then press ENTER in the terminal.
#   2. Exchange the session for a bearer token (cached for future runs).
#
# Cached credentials are stored in ~/.config/sharkey-emoji-uploader/
#
# Optional overrides (env vars):
#   SHARKEY_TOKEN=<api_token>                  (skip auto-auth entirely)
#   SHARKEY_INSTANCE=https://ap.ewancroft.uk   (default)
#   EMOJI_DIR=/path/to/fedi-emojis-main        (default)
#   EMOJI_SIZE_LIMIT_KB=5120                   (default 5 MiB)
#   DRY_RUN=1                                  (print what would happen, no requests)
#
# Oversized emoji are automatically resized using ffmpeg if available.
#
# Sharkey API flow:
#   Upload emoji file → POST /api/drive/files/create  (multipart) → fileId
#   Register emoji    → POST /api/admin/emoji/add      (JSON)
#   List emoji        → POST /api/admin/emoji/list     (JSON, sinceId pagination)
#   Delete emoji      → POST /api/admin/emoji/delete   (JSON)

set -euo pipefail

INSTANCE="${SHARKEY_INSTANCE:-https://ap.ewancroft.uk}"
EMOJI_DIR="${EMOJI_DIR:-/Users/ewan/Developer/Other/fedi-emojis-main}"
DRY_RUN="${DRY_RUN:-0}"

EMOJI_SIZE_LIMIT_KB="${EMOJI_SIZE_LIMIT_KB:-5120}"
EMOJI_SIZE_LIMIT=$((EMOJI_SIZE_LIMIT_KB * 1024))

CACHE_DIR="${HOME}/.config/sharkey-emoji-uploader"
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
# MiAuth helpers
# ---------------------------------------------------------------------------

gen_uuid() {
	if command -v uuidgen &>/dev/null; then
		uuidgen | tr '[:upper:]' '[:lower:]'
	else
		cat /proc/sys/kernel/random/uuid 2>/dev/null ||
			printf '%08x-%04x-%04x-%04x-%012x\n' \
				$RANDOM$RANDOM $RANDOM $RANDOM $RANDOM $RANDOM$RANDOM$RANDOM
	fi
}

fetch_token_miauth() {
	local session_id
	session_id=$(gen_uuid)

	local permissions="read:admin:emoji,write:admin:emoji,write:drive,read:drive"
	local auth_url="${INSTANCE}/miauth/${session_id}?name=sharkey-emoji-uploader&permission=${permissions}"

	echo >&2
	echo "Open this URL in your browser to authorise the app:" >&2
	echo >&2
	echo "  ${auth_url}" >&2
	echo >&2

	if command -v open &>/dev/null; then
		open "$auth_url" 2>/dev/null || true
	fi

	read -rp "Press ENTER once you have approved access in your browser..." _confirm </dev/tty

	local response
	response=$(curl -sf -X POST "${INSTANCE}/api/miauth/${session_id}/check" \
		-H "Content-Type: application/json" \
		-d '{}')

	local token
	token=$(echo "$response" | grep -o '"token":"[^"]*"' | head -1 | cut -d'"' -f4)

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
	if [[ -n "${SHARKEY_TOKEN:-}" ]]; then
		return
	fi

	if [[ -f "$TOKEN_FILE" ]]; then
		SHARKEY_TOKEN="$(cat "$TOKEN_FILE")"
		echo "Using cached token from ${TOKEN_FILE}." >&2
		return
	fi

	SHARKEY_TOKEN="$(fetch_token_miauth)"
}

# ---------------------------------------------------------------------------
# Low-level API helper
# ---------------------------------------------------------------------------

# POST JSON to a Sharkey API endpoint.
# Outputs the HTTP status code; response body goes to <body_file>.
api_post() {
	local endpoint="$1"
	local payload="$2"
	local headers_file="$3"
	local body_file="$4"

	curl -s --max-time 60 \
		-D "$headers_file" \
		-o "$body_file" \
		-w "%{http_code}" \
		-X POST "${INSTANCE}${endpoint}" \
		-H "Authorization: Bearer ${SHARKEY_TOKEN}" \
		-H "Content-Type: application/json" \
		-d "$payload"
}

# ---------------------------------------------------------------------------
# Rate-limit helpers
# ---------------------------------------------------------------------------

parse_reset_timestamp() {
	local raw="$1"
	if [[ "$raw" =~ ^[0-9]+$ ]]; then
		echo "$raw"
		return
	fi
	if command -v date &>/dev/null; then
		local ts
		if date --version &>/dev/null 2>&1; then
			ts=$(date -d "$raw" +%s 2>/dev/null || true)
		else
			local clean="${raw%.*}"
			clean="${clean%Z}"
			ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "$clean" +%s 2>/dev/null || true)
		fi
		[[ -n "$ts" && "$ts" =~ ^[0-9]+$ ]] && echo "$ts" && return
	fi
	echo ""
}

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
# Emoji list helper (POST-based, sinceId pagination)
# ---------------------------------------------------------------------------

# Fetches all local emoji, optionally filtered by category query.
# Outputs lines of: <id> <name>
list_local_emoji() {
	local filter_category="${1:-}"
	local since_id=""
	local limit=100

	while true; do
		local payload
		payload=$(printf '{"limit":%d%s%s}' \
			"$limit" \
			"${since_id:+,\"sinceId\":\"${since_id}\"}" \
			"${filter_category:+,\"query\":\"${filter_category}\"}")

		local http_status
		http_status=$(api_post /api/admin/emoji/list "$payload" \
			/tmp/sk_list_headers.txt /tmp/sk_emoji_list.json)

		if [[ "$http_status" == "429" ]]; then
			local wait
			wait=$(rate_limit_sleep_time /tmp/sk_list_headers.txt)
			echo "  [RATE] list — 429 rate limited, sleeping ${wait}s..." >&2
			sleep "$wait"
			continue
		fi

		if [[ "$http_status" != "200" ]]; then
			echo "Error: failed to list emoji (HTTP ${http_status})." >&2
			cat /tmp/sk_emoji_list.json >&2
			exit 1
		fi

		respect_rate_limit /tmp/sk_list_headers.txt

		local body
		body=$(cat /tmp/sk_emoji_list.json)

		local -a ids names
		mapfile -t ids < <(echo "$body" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
		mapfile -t names < <(echo "$body" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)

		[[ ${#ids[@]} -eq 0 ]] && break

		for i in "${!ids[@]}"; do
			printf '%s %s\n' "${ids[$i]}" "${names[$i]:-unknown}"
		done

		[[ ${#ids[@]} -lt $limit ]] && break
		since_id="${ids[-1]}"
	done
}

# ---------------------------------------------------------------------------
# Clean mode
# ---------------------------------------------------------------------------

delete_all_emoji() {
	echo "Fetching list of all local custom emoji..." >&2

	local -a all_ids=()
	mapfile -t all_ids < <(list_local_emoji | awk '{print $1}')

	local count=${#all_ids[@]}

	if [[ $count -eq 0 ]]; then
		echo "No local custom emoji found — nothing to delete." >&2
		return
	fi

	echo "Found ${count} local custom emoji." >&2

	if [[ "$YES" -ne 1 ]]; then
		read -rp "Delete all ${count} emoji? This cannot be undone. [y/N] " confirm </dev/tty
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
		local http_status
		while true; do
			http_status=$(api_post /api/admin/emoji/delete \
				"{\"id\":\"${id}\"}" \
				/tmp/sk_del_headers.txt /tmp/sk_del_response.json)
			[[ "$http_status" != "429" ]] && break
			local wait
			wait=$(rate_limit_sleep_time /tmp/sk_del_headers.txt)
			echo "  [RATE] delete ${id} — 429 rate limited, sleeping ${wait}s..." >&2
			sleep "$wait"
		done

		if [[ "$http_status" == "200" || "$http_status" == "204" ]]; then
			((deleted++)) || true
			echo "  [DEL]  ${id}"
		else
			local err
			err=$(cat /tmp/sk_del_response.json 2>/dev/null || echo '{}')
			echo "  [FAIL] delete ${id} — HTTP ${http_status}: ${err}" >&2
			((del_failed++)) || true
		fi

		respect_rate_limit /tmp/sk_del_headers.txt
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

	local tmp="/tmp/sk_emoji_resized.${ext}"

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

# Step 1: Upload file to Sharkey drive → returns fileId.
upload_to_drive() {
	local file="$1"
	local filename="$2"
	local mime="$3"

	local max_retries=4
	for ((attempt = 0; attempt <= max_retries; attempt++)); do
		local http_status
		http_status=$(curl -s --max-time 60 \
			-D /tmp/sk_drive_headers.txt \
			-o /tmp/sk_drive_response.json \
			-w "%{http_code}" \
			-X POST "${INSTANCE}/api/drive/files/create" \
			-H "Authorization: Bearer ${SHARKEY_TOKEN}" \
			-F "file=@${file};filename=${filename};type=${mime}" \
			-F "isSensitive=false")

		if [[ "$http_status" == "429" && $attempt -lt $max_retries ]]; then
			local wait
			wait=$(rate_limit_sleep_time /tmp/sk_drive_headers.txt)
			echo "  [WAIT] drive upload — 429 rate limited, sleeping ${wait}s..." >&2
			sleep "$wait"
			continue
		fi

		respect_rate_limit /tmp/sk_drive_headers.txt

		if [[ "$http_status" != "200" ]]; then
			echo "HTTP_${http_status}"
			return
		fi

		grep -o '"id":"[^"]*"' /tmp/sk_drive_response.json | head -1 | cut -d'"' -f4
		return
	done

	echo ""
}

# Step 2: Register a drive file as a custom emoji.
add_emoji_from_drive() {
	local file_id="$1"
	local shortcode="$2"
	local category="$3"

	local payload
	payload=$(printf '{"fileId":"%s","name":"%s","category":"%s","aliases":[]}' \
		"$file_id" "$shortcode" "$category")

	local max_retries=4
	for ((attempt = 0; attempt <= max_retries; attempt++)); do
		local http_status
		http_status=$(api_post /api/admin/emoji/add "$payload" \
			/tmp/sk_emoji_headers.txt /tmp/sk_emoji_response.json)

		if [[ "$http_status" == "429" && $attempt -lt $max_retries ]]; then
			local wait
			wait=$(rate_limit_sleep_time /tmp/sk_emoji_headers.txt)
			echo "  [WAIT] :${shortcode}: — 429 rate limited, sleeping ${wait}s..." >&2
			sleep "$wait"
			continue
		fi

		respect_rate_limit /tmp/sk_emoji_headers.txt
		echo "$http_status"
		return
	done

	echo "0"
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

	# Step 1: upload to drive
	local file_id
	file_id=$(upload_to_drive "$upload_file" "$filename" "$mime")

	if [[ -z "$file_id" || "$file_id" == HTTP_* ]]; then
		echo "  [FAIL] :${shortcode}: — drive upload failed (${file_id:-empty response})" >&2
		((failed++)) || true
		return
	fi

	# Step 2: register as emoji
	local http_status
	http_status=$(add_emoji_from_drive "$file_id" "$shortcode" "$category")

	case "$http_status" in
	200 | 204)
		echo "  [OK]   :${shortcode}: (${category})"
		((ok++)) || true
		;;
	401)
		echo "  [FAIL] :${shortcode}: — 401 Unauthorised (token may be expired)" >&2
		echo "  Hint: delete ${TOKEN_FILE} and re-run to get a fresh token." >&2
		((failed++)) || true
		;;
	409)
		echo "  [SKIP] :${shortcode}: — 409 already exists"
		((skipped++)) || true
		;;
	422)
		local error
		error=$(grep -o '"message":"[^"]*"' /tmp/sk_emoji_response.json 2>/dev/null | head -1 || echo 'unknown')
		echo "  [SKIP] :${shortcode}: — 422 ${error}"
		((skipped++)) || true
		;;
	429)
		echo "  [FAIL] :${shortcode}: — 429 rate limited after max retries"
		((failed++)) || true
		;;
	*)
		local error
		error=$(grep -o '"message":"[^"]*"' /tmp/sk_emoji_response.json 2>/dev/null | head -1 || echo 'unknown')
		echo "  [FAIL] :${shortcode}: — HTTP ${http_status} ${error}"
		((failed++)) || true
		;;
	esac
}

# ---------------------------------------------------------------------------
# Pack selection
# ---------------------------------------------------------------------------

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

	for p in "${all_packs[@]}"; do
		[[ -v SELECTED_PACKS["$p"] ]] || DESELECTED_PACKS+=("$p")
	done
}

delete_category_emoji() {
	local category="$1"
	echo "  Removing existing emoji in category '${category}'..."

	local -a ids=()
	mapfile -t ids < <(list_local_emoji "$category" | awk '{print $1}')

	if [[ ${#ids[@]} -eq 0 ]]; then
		echo "  (none found)"
		return
	fi

	for id in "${ids[@]}"; do
		if [[ "$DRY_RUN" == "1" ]]; then
			echo "  [DRY]  would delete emoji ${id} (category: ${category})"
			continue
		fi

		local del_status
		while true; do
			del_status=$(api_post /api/admin/emoji/delete \
				"{\"id\":\"${id}\"}" \
				/tmp/sk_del_headers.txt /tmp/sk_del_response.json)
			[[ "$del_status" != "429" ]] && break
			local wait
			wait=$(rate_limit_sleep_time /tmp/sk_del_headers.txt)
			echo "  [RATE] delete ${id} — 429 rate limited, sleeping ${wait}s..." >&2
			sleep "$wait"
		done

		if [[ "$del_status" == "200" || "$del_status" == "204" ]]; then
			echo "  [DEL]  emoji ${id}"
		else
			echo "  [FAIL] delete emoji ${id} — HTTP ${del_status}" >&2
		fi

		respect_rate_limit /tmp/sk_del_headers.txt
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

declare -A SELECTED_PACKS=()
declare -a DESELECTED_PACKS=()

select_packs

echo
echo "Sharkey emoji uploader"
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
