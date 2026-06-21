#!/usr/bin/env bats
# Tests for emails status task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_mock_himalaya
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.personal]
default = false
email = "person@example.test"
backend.host = "imap.example.test"
backend.port = 993
backend.auth.raw = "personal-pass"

[accounts.kkl]
default = true
email = "c0da@knacklabs.co"
backend.host = "imap.knacklabs.test"
backend.port = 993
backend.auth.raw = "kkl-pass"
EOF
}

@test "status: checks the selected account" {
  run emails status --account personal

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resolved account: personal <person@example.test>"* ]]
  [[ "$output" == *"Connection: ✓"* ]]
  grep -qF -- 'envelope list -a personal --max-width 0' "$MOCK_HIMALAYA_CALLS"
}

@test "status: uses default account when no account is supplied" {
  run emails status

  [ "$status" -eq 0 ]
  [[ "$output" == *"Resolved account: kkl <c0da@knacklabs.co>"* ]]
  [[ "$output" == *"Connection: ✓"* ]]
}
