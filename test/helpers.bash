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

# Remove ambient Emails selectors before installing per-test fixtures.
isolate_emails_env() {
  unset EMAILS_CONFIG
  unset EMAILS_ACCOUNT
  unset EMAILS_CALLER_PWD
  unset EMAILS_NO_ACCOUNT_RESOLUTION
}

# Set up a fake agent identity and himalaya config
# Uses HIMALAYA_CONFIG env var to avoid touching real HOME
setup_agent() {
  isolate_emails_env
  export BATS_ACCOUNT="test-agent"

  # Create himalaya config in test tmpdir
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.test-agent]
default = true
email = "test-agent@ricon.family"
display-name = "test-agent"
downloads-dir = "$BATS_TEST_TMPDIR/downloads"
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
pgp.sign-cmd = "gpg --local-user '<test-agent@ricon.family>' --sign --quiet --armor"
pgp.decrypt-cmd = "gpg --decrypt --quiet"
pgp.verify-cmd = "gpg --verify --quiet"
EOF

  # Keep attachment downloads inside this test's fixture root.
  mkdir -p "$BATS_TEST_TMPDIR/downloads"
}

# Create a mock himalaya that returns canned responses
setup_mock_himalaya() {
  isolate_emails_env
  export MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"

  # Track calls for assertions
  export MOCK_HIMALAYA_CALLS="$BATS_TEST_TMPDIR/himalaya-calls.log"
  export MOCK_HIMALAYA_ARGV_CALLS="$BATS_TEST_TMPDIR/himalaya-argv-calls.log"
  export MOCK_HIMALAYA_STDIN="$BATS_TEST_TMPDIR/himalaya-stdin.log"
  : > "$MOCK_HIMALAYA_CALLS"
  : > "$MOCK_HIMALAYA_ARGV_CALLS"
  : > "$MOCK_HIMALAYA_STDIN"

  cat > "$MOCK_BIN/himalaya" <<'MOCK'
#!/usr/bin/env bash
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

args=("$@")
if [ "${args[0]:-}" = "-c" ]; then
  args=("${args[@]:2}")
fi

if [ "${args[0]:-} ${args[1]:-}" = "template send" ]; then
  cat >> "$MOCK_HIMALAYA_STDIN"
fi

# Read canned response if set
if [ -n "${MOCK_HIMALAYA_RESPONSE:-}" ] && [ -f "$MOCK_HIMALAYA_RESPONSE" ]; then
  cat "$MOCK_HIMALAYA_RESPONSE"
fi
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

# Count himalaya calls matching a pattern
count_himalaya_calls() {
  grep -c "$1" "$MOCK_HIMALAYA_CALLS" || echo "0"
}
