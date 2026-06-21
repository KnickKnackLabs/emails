# Sourceable helper for email tasks.
#
# Sets:
#   CONFIG_FILE        Himalaya config path
#   ACCOUNT            Resolved email account name
#   ACCOUNT_EMAIL      Resolved account email address
#   ACCOUNT_DOWNLOADS_DIR  Downloads dir for the resolved account
#
# When sourced with NEED_IMAP=1, also sets: PASS
#
# Usage: source "$MISE_CONFIG_ROOT/lib/email.sh"

export RUST_LOG=error
HIMALAYA_BIN="${HIMALAYA:-himalaya}"

email_fail() {
  echo "$*" >&2
  return 1 2>/dev/null || exit 1
}

find_upward_email_config() {
  local dir="$PWD"
  while [ -n "$dir" ] && [ "$dir" != "/" ]; do
    if [ -f "$dir/.emails/himalaya.toml" ]; then
      printf '%s\n' "$dir/.emails/himalaya.toml"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

if [ -n "${EMAILS_CONFIG:-}" ]; then
  CONFIG_FILE="$EMAILS_CONFIG"
elif [ -n "${HIMALAYA_CONFIG:-}" ]; then
  CONFIG_FILE="$HIMALAYA_CONFIG"
elif CONFIG_FILE="$(find_upward_email_config)"; then
  :
else
  CONFIG_FILE="$HOME/.config/emails/himalaya.toml"
fi

CONFIG_DIR="$(dirname "$CONFIG_FILE")"

email_account_names() {
  [ -f "$CONFIG_FILE" ] || return 0
  grep -E '^\[accounts\.[^]]+\]$' "$CONFIG_FILE" 2>/dev/null \
    | sed 's/^\[accounts\.//; s/\]$//'
}

email_account_exists() {
  local account="$1"
  grep -qF "[accounts.$account]" "$CONFIG_FILE" 2>/dev/null
}

email_account_field() {
  local account="$1"
  local field="$2"
  awk -v section="[accounts.$account]" -v field="$field" '
    $0 ~ /^\[/ { in_section = ($0 == section); next }
    in_section && index($0, "=") {
      line = $0
      sub(/[[:space:]]+#.*/, "", line)
      key = line
      sub(/=.*/, "", key)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
      if (key == field) {
        value = line
        sub(/^[^=]*=/, "", value)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
        gsub(/^\"|\"$/, "", value)
        print value
        exit
      }
    }
  ' "$CONFIG_FILE"
}

email_default_accounts() {
  local account
  while IFS= read -r account; do
    [ -n "$account" ] || continue
    if [ "$(email_account_field "$account" default)" = "true" ]; then
      printf '%s\n' "$account"
    fi
  done < <(email_account_names)
}

email_choose_account() {
  local requested="${usage_account:-${EMAILS_ACCOUNT:-}}"
  local accounts defaults account_count default_count first_account

  if [ ! -f "$CONFIG_FILE" ]; then
    cat >&2 <<EOF
Email config not found.
Expected: $CONFIG_FILE

Create an account explicitly, for example:
  printf '%s' '<password>' | emails account setup personal --address you@example.com --imap-host imap.example.com --smtp-host smtp.example.com --password-stdin
EOF
    return 1
  fi

  accounts="$(email_account_names)"
  if [ -z "$accounts" ]; then
    cat >&2 <<EOF
No email accounts configured in $CONFIG_FILE.

Create one explicitly, for example:
  printf '%s' '<password>' | emails account setup personal --address you@example.com --imap-host imap.example.com --smtp-host smtp.example.com --password-stdin
EOF
    return 1
  fi

  if [ -n "$requested" ]; then
    if email_account_exists "$requested"; then
      printf '%s\n' "$requested"
      return 0
    fi
    cat >&2 <<EOF
Email account not configured: $requested
Configured accounts:
$(printf '%s\n' "$accounts" | sed 's/^/  - /')
EOF
    return 1
  fi

  account_count=$(printf '%s\n' "$accounts" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$account_count" -eq 1 ]; then
    printf '%s\n' "$accounts" | sed -n '1p'
    return 0
  fi

  defaults="$(email_default_accounts)"
  default_count=$(printf '%s\n' "$defaults" | sed '/^$/d' | wc -l | tr -d ' ')
  if [ "$default_count" -eq 1 ]; then
    printf '%s\n' "$defaults" | sed -n '1p'
    return 0
  fi

  if [ "$default_count" -gt 1 ]; then
    cat >&2 <<EOF
Multiple email accounts are marked default in $CONFIG_FILE:
$(printf '%s\n' "$defaults" | sed 's/^/  - /')

Clear/fix the defaults with:
  emails account default <account>
EOF
    return 1
  fi

  first_account=$(printf '%s\n' "$accounts" | sed -n '1p')
  cat >&2 <<EOF
Multiple email accounts configured and no default is set:
$(printf '%s\n' "$accounts" | sed 's/^/  - /')

Choose one with the command's --account flag, for example:
  emails send --account <account> ...
or set a default:
  emails account default $first_account
EOF
  return 1
}

if [ "${EMAILS_NO_ACCOUNT_RESOLUTION:-0}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

ACCOUNT="$(email_choose_account)" || return 1 2>/dev/null || exit 1
ACCOUNT_EMAIL="$(email_account_field "$ACCOUNT" email)"
if [ -z "$ACCOUNT_EMAIL" ]; then
  email_fail "Email account '$ACCOUNT' is missing an email field in $CONFIG_FILE"
fi
ACCOUNT_DOWNLOADS_DIR="$(email_account_field "$ACCOUNT" downloads-dir)"
if [ -z "$ACCOUNT_DOWNLOADS_DIR" ]; then
  ACCOUNT_DOWNLOADS_DIR="$CONFIG_DIR/downloads/$ACCOUNT"
fi

emails_himalaya() {
  "$HIMALAYA_BIN" -c "$CONFIG_FILE" "$@"
}

# IMAP password — only extracted when caller needs direct IMAP access.
if [ "${NEED_IMAP:-0}" = "1" ]; then
  PASS="$(email_account_field "$ACCOUNT" backend.auth.raw)"
  if [ -z "$PASS" ]; then
    echo "Could not read email password for account '$ACCOUNT' from config" >&2
    return 1 2>/dev/null || exit 1
  fi
fi
