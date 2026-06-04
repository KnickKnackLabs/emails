#!/usr/bin/env bats
# Tests for emails status task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_mock_himalaya
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.or]
default = false
email = "or@ricon.family"

[accounts.junior]
default = true
email = "junior@ricon.family"
EOF
}

@test "status: checks the requested himalaya account" {
  run emails status or

  [ "$status" -eq 0 ]
  [[ "$output" == *"Email status for or (or@ricon.family)"* ]]
  [[ "$output" == *"Connection: ✓"* ]]
  grep -qF -- 'envelope list -a or --max-width 0' "$MOCK_HIMALAYA_CALLS"
}

@test "status: honors HIMALAYA_CONFIG when checking account config" {
  run emails status junior

  [ "$status" -eq 0 ]
  [[ "$output" == *"Account configured: ✓"* ]]
}
