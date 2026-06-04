# Shared test helpers for emails BATS tests
#
# Provides:
#   - emails() wrapper that calls tasks through mise
#   - Mock himalaya for test isolation (no real IMAP/SMTP)
#   - Agent identity setup via HIMALAYA_CONFIG override

if [ -z "${REPO_DIR:-}" ]; then
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export REPO_DIR
fi

emails() {
  cd "$REPO_DIR" && mise run -q "$@"
}
export -f emails

# Set up a fake agent identity and himalaya config
# Uses HIMALAYA_CONFIG env var to avoid touching real HOME
setup_agent() {
  export GIT_AUTHOR_EMAIL="test-agent@ricon.family"
  export BATS_AGENT="test-agent"

  # Create himalaya config in test tmpdir
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.test-agent]
default = true
email = "test-agent@ricon.family"
display-name = "test-agent"
backend.type = "imap"
backend.host = "mail.ricon.family"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "test-agent@ricon.family"
backend.auth.type = "password"
backend.auth.raw = "fake-password"
message.send.backend.type = "smtp"
message.send.backend.host = "mail.ricon.family"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
message.send.backend.login = "test-agent@ricon.family"
message.send.backend.auth.type = "password"
message.send.backend.auth.raw = "fake-password"
pgp.type = "commands"
pgp.sign-cmd = "gpg --local-user test-agent@ricon.family --sign --quiet --armor"
pgp.decrypt-cmd = "gpg --decrypt --quiet"
pgp.verify-cmd = "gpg --verify --quiet"
EOF

  # Create agent workspace
  mkdir -p "$HOME/agents/test-agent/downloads"
}

# Create a mock himalaya that returns canned responses
setup_mock_himalaya() {
  export MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"

  # Track calls for assertions
  export MOCK_HIMALAYA_CALLS="$BATS_TEST_TMPDIR/himalaya-calls.log"
  export MOCK_HIMALAYA_ARGV_CALLS="$BATS_TEST_TMPDIR/himalaya-argv-calls.log"
  export MOCK_HIMALAYA_STDIN="$BATS_TEST_TMPDIR/himalaya-stdin.log"
  # Raw message captured by `message send` (the named-signature send path).
  export MOCK_HIMALAYA_SEND_RAW="$BATS_TEST_TMPDIR/himalaya-send-raw.log"
  # Simulated Drafts folder state (one envelope id per line).
  export MOCK_DRAFTS_STATE="$BATS_TEST_TMPDIR/himalaya-drafts.state"
  # Draft ids flagged \Deleted, awaiting `folder expunge`.
  export MOCK_DRAFTS_DELETED="$BATS_TEST_TMPDIR/himalaya-drafts.deleted"
  # Canned signed .eml that `message export --full` returns (a multipart/signed
  # message with an unnamed application/pgp-signature part, like real himalaya).
  export MOCK_SIGNED_EML="$BATS_TEST_TMPDIR/himalaya-signed.eml"
  : > "$MOCK_HIMALAYA_CALLS"
  : > "$MOCK_HIMALAYA_ARGV_CALLS"
  : > "$MOCK_HIMALAYA_STDIN"
  : > "$MOCK_HIMALAYA_SEND_RAW"
  : > "$MOCK_DRAFTS_STATE"
  : > "$MOCK_DRAFTS_DELETED"
  printf 'From: test-agent@ricon.family\r\nTo: user@example.com\r\nSubject: Mock signed\r\nMIME-Version: 1.0\r\nContent-Type: multipart/signed; boundary="bnd"; protocol="application/pgp-signature"; micalg="pgp-sha256"\r\n\r\n--bnd\r\nContent-Type: text/plain; charset=utf-8\r\n\r\nmock signed body content\r\n--bnd\r\nContent-Type: application/pgp-signature\r\nContent-Transfer-Encoding: 7bit\r\n\r\n-----BEGIN PGP SIGNATURE-----\r\n\r\nmQ==mocksignaturebytes\r\n-----END PGP SIGNATURE-----\r\n--bnd--\r\n' > "$MOCK_SIGNED_EML"

  cat > "$MOCK_BIN/himalaya" <<'MOCK'
#!/usr/bin/env bash
HIMALAYA_ARGV=("$@")

# Log the call (space-joined for existing substring assertions, and
# length-prefixed argv for tests that need argument-boundary checks).
echo "$@" >> "$MOCK_HIMALAYA_CALLS"
{
  printf 'argc=%s' "$#"
  for arg in "$@"; do
    printf '\t%s:%s' "${#arg}" "$arg"
  done
  printf '\n'
} >> "$MOCK_HIMALAYA_ARGV_CALLS"

# Value following a flag in argv (e.g. flag_value -d -> the export destination).
flag_value() {
  local want="$1" i
  for ((i = 0; i < ${#HIMALAYA_ARGV[@]}; i++)); do
    if [ "${HIMALAYA_ARGV[i]}" = "$want" ]; then
      echo "${HIMALAYA_ARGV[i + 1]:-}"
      return 0
    fi
  done
  return 1
}

# Subcommand pair, skipping a leading global `-o <fmt>` / `--output <fmt>`.
args=("$@")
if [ "${args[0]:-}" = "-o" ] || [ "${args[0]:-}" = "--output" ]; then
  args=("${args[@]:2}")
fi
sub="${args[0]:-} ${args[1]:-}"

case "$sub" in
  "template send" | "template save")
    # Capture the MML body for content assertions.
    cat >> "$MOCK_HIMALAYA_STDIN"
    # himalaya v1.2.0 `template save` writes the draft twice; mirror that so the
    # send task's before/after diff + multi-id cleanup is exercised.
    if [ "$sub" = "template save" ]; then
      printf 'draft-%s\ndraft-%s\n' "$RANDOM$RANDOM" "$RANDOM$RANDOM" >> "$MOCK_DRAFTS_STATE"
    fi
    ;;
  "envelope list")
    if printf ' %s ' "${HIMALAYA_ARGV[@]}" | grep -q -- ' Drafts '; then
      printf '['
      first=1
      while IFS= read -r id; do
        [ -n "$id" ] || continue
        [ "$first" = 1 ] || printf ','
        printf '{"id":"%s"}' "$id"
        first=0
      done < "$MOCK_DRAFTS_STATE"
      printf ']\n'
    elif [ -n "${MOCK_HIMALAYA_RESPONSE:-}" ] && [ -f "$MOCK_HIMALAYA_RESPONSE" ]; then
      cat "$MOCK_HIMALAYA_RESPONSE"
    fi
    ;;
  "message export")
    dest=$(flag_value -d || flag_value --destination)
    if [ -n "$dest" ]; then
      cp "$MOCK_SIGNED_EML" "$dest"
    else
      cat "$MOCK_SIGNED_EML"
    fi
    ;;
  "message send")
    cat >> "$MOCK_HIMALAYA_SEND_RAW"
    ;;
  "flag add")
    # Record draft ids flagged for deletion (mock ids look like draft-NNNN).
    for a in "${HIMALAYA_ARGV[@]}"; do
      case "$a" in draft-*) echo "$a" >> "$MOCK_DRAFTS_DELETED" ;; esac
    done
    ;;
  "folder expunge")
    # Permanently drop the flagged ids from the simulated Drafts folder.
    if printf ' %s ' "${HIMALAYA_ARGV[@]}" | grep -q -- ' Drafts ' && [ -s "$MOCK_DRAFTS_DELETED" ]; then
      tmp=$(mktemp)
      # grep exits 1 when no draft ids remain; the (possibly empty) output is what
      # we want either way, and this mock does not run under `set -e`.
      if ! grep -vxF -f "$MOCK_DRAFTS_DELETED" "$MOCK_DRAFTS_STATE" > "$tmp" 2>/dev/null; then
        : # all drafts removed -> $tmp is empty
      fi
      mv "$tmp" "$MOCK_DRAFTS_STATE"
      : > "$MOCK_DRAFTS_DELETED"
    fi
    ;;
  *)
    if [ -n "${MOCK_HIMALAYA_RESPONSE:-}" ] && [ -f "$MOCK_HIMALAYA_RESPONSE" ]; then
      cat "$MOCK_HIMALAYA_RESPONSE"
    fi
    ;;
esac
MOCK
  chmod +x "$MOCK_BIN/himalaya"

  export HIMALAYA="$MOCK_BIN/himalaya"
  export PATH="$MOCK_BIN:$PATH"
}

# Set up canned response for mock himalaya
set_mock_response() {
  export MOCK_HIMALAYA_RESPONSE="$BATS_TEST_TMPDIR/mock-response.txt"
  echo "$1" > "$MOCK_HIMALAYA_RESPONSE"
}

# Assert himalaya was called with specific args
assert_himalaya_called() {
  grep -qF -- "$1" "$MOCK_HIMALAYA_CALLS"
}

himalaya_stdin() {
  cat "$MOCK_HIMALAYA_STDIN"
}

# Raw message handed to `message send` (the named-signature send path).
himalaya_send_raw() {
  cat "$MOCK_HIMALAYA_SEND_RAW"
}

# Remaining simulated Drafts ids (empty when cleanup succeeded).
drafts_state() {
  cat "$MOCK_DRAFTS_STATE" 2>/dev/null
}

# Count himalaya calls matching a pattern
count_himalaya_calls() {
  grep -c "$1" "$MOCK_HIMALAYA_CALLS" || echo "0"
}
