#!/usr/bin/env bats
# Tests for emails export task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya
}

@test "export: writes requested message under strict shell" {
  set_mock_response "raw exported message"

  run emails export 42 -d "$BATS_TEST_TMPDIR/exported"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Exported 1 message(s)"* ]]
  [ "$(cat "$BATS_TEST_TMPDIR/exported/42.eml")" = "raw exported message" ]
  assert_himalaya_called "message read -a test-agent -f INBOX 42"
}

@test "export: counts failed reads under strict shell" {
  cat > "$MOCK_BIN/himalaya" <<'MOCK'
#!/usr/bin/env bash
echo "$@" >> "$MOCK_HIMALAYA_CALLS"
if [ "$1 $2" = "message read" ]; then
  exit 1
fi
MOCK
  chmod +x "$MOCK_BIN/himalaya"

  run emails export 42 -d "$BATS_TEST_TMPDIR/exported"

  [ "$status" -eq 0 ]
  [[ "$output" == *"Failed: 42"* ]]
  [[ "$output" == *"Exported 0 message(s)"* ]]
  [[ "$output" == *"Failed to export 1 message(s)"* ]]
  [ ! -e "$BATS_TEST_TMPDIR/exported/42.eml" ]
}
