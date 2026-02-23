#!/usr/bin/env bash
# graph.sh — shared Graph API client for email tasks
#
# Provides:
#   graph_get_token    — returns a valid access token (refreshing if needed)
#   graph_request      — authenticated GET/POST/PATCH/DELETE to Graph API
#   graph_get          — shorthand for GET
#   graph_post         — shorthand for POST
#   graph_patch        — shorthand for PATCH
#   graph_delete       — shorthand for DELETE
#
# All functions output JSON. Callers parse with jq.

set -eo pipefail

GRAPH_API="https://graph.microsoft.com/v1.0"
AZURE_AD_TOKEN_URL="https://login.microsoftonline.com/common/oauth2/v2.0/token"
GRAPH_EXPLORER_CLIENT_ID="de8bc8b5-d9f9-48b1-a8ad-b748da725064"

# Token storage
AUTH_DIR="${EMAIL_AUTH_DIR:-$HOME/.config/email}"
TOKEN_FILE="$AUTH_DIR/tokens.json"

# ─── Token management ────────────────────────────────────────────────────────

_ensure_auth_dir() {
  mkdir -p "$AUTH_DIR"
  chmod 700 "$AUTH_DIR"
}

_load_tokens() {
  if [ ! -f "$TOKEN_FILE" ]; then
    echo '{"error": "not_authenticated", "message": "Run: email login"}' >&2
    return 1
  fi
  cat "$TOKEN_FILE"
}

_save_tokens() {
  _ensure_auth_dir
  local tokens="$1"
  # Add timestamp
  tokens=$(echo "$tokens" | jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {timestamp: $ts}')
  echo "$tokens" > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
}

_is_expired() {
  local tokens="$1"
  local expires_at
  # Truncate to integer (token file may have fractional seconds)
  expires_at=$(echo "$tokens" | jq -r '.expires_at // 0 | floor')
  local now
  now=$(date +%s)
  # 60-second buffer
  [ "$now" -ge "$((expires_at - 60))" ]
}

_refresh_token() {
  local tokens="$1"
  local refresh_token
  refresh_token=$(echo "$tokens" | jq -r '.refresh_token // empty')

  if [ -z "$refresh_token" ]; then
    echo "No refresh token available. Run: email login" >&2
    return 1
  fi

  local response
  response=$(curl -s --max-time 15 \
    -X POST "$AZURE_AD_TOKEN_URL" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=$GRAPH_EXPLORER_CLIENT_ID&grant_type=refresh_token&refresh_token=$refresh_token")

  # Check for error
  if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
    local err
    err=$(echo "$response" | jq -r '.error_description // .error')
    echo "Token refresh failed: $err" >&2
    echo "Run: email login" >&2
    return 1
  fi

  # Calculate expires_at and merge
  local expires_in
  expires_in=$(echo "$response" | jq -r '.expires_in // 3600')
  local now
  now=$(date +%s)
  local new_tokens
  new_tokens=$(echo "$response" | jq \
    --argjson expires_at "$((now + expires_in))" \
    --arg old_refresh "$refresh_token" \
    '{
      access_token: .access_token,
      refresh_token: (.refresh_token // $old_refresh),
      expires_at: $expires_at,
      expires_in: .expires_in,
      scope: .scope
    }')

  _save_tokens "$new_tokens"
  echo "$new_tokens"
}

graph_get_token() {
  local tokens
  tokens=$(_load_tokens) || return 1

  if _is_expired "$tokens"; then
    tokens=$(_refresh_token "$tokens") || return 1
  fi

  echo "$tokens" | jq -r '.access_token'
}

# ─── HTTP requests ────────────────────────────────────────────────────────────

graph_request() {
  local method="$1" endpoint="$2"
  shift 2
  local body="${1:-}"

  local token
  token=$(graph_get_token) || return 1

  # Support both relative endpoints and absolute URLs
  local url
  if [[ "$endpoint" == http* ]]; then
    url="$endpoint"
  else
    url="${GRAPH_API}${endpoint}"
  fi

  local curl_args=(
    -s --max-time 30
    -H "Authorization: Bearer $token"
    -H "Content-Type: application/json"
    -X "$method"
  )

  if [ -n "$body" ]; then
    curl_args+=(-d "$body")
  fi

  curl "${curl_args[@]}" "$url"
}

graph_get()    { graph_request GET    "$@"; }
graph_post()   { graph_request POST   "$@"; }
graph_patch()  { graph_request PATCH  "$@"; }
graph_delete() { graph_request DELETE "$@"; }

# ─── Output helpers ───────────────────────────────────────────────────────────

# Format a UTC ISO timestamp to local human-readable
format_date() {
  local utc_date="$1"
  # macOS date
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$utc_date" "+%b %d, %I:%M %p" 2>/dev/null; then
    return
  fi
  # Try with fractional seconds
  local trimmed="${utc_date%%.*}Z"
  if date -j -f "%Y-%m-%dT%H:%M:%SZ" "$trimmed" "+%b %d, %I:%M %p" 2>/dev/null; then
    return
  fi
  # Fallback: just print as-is
  echo "$utc_date"
}

# Truncate a string to N chars with ellipsis
truncate() {
  local str="$1" max="${2:-60}"
  if [ "${#str}" -gt "$max" ]; then
    echo "${str:0:$((max-1))}..."
  else
    echo "$str"
  fi
}
