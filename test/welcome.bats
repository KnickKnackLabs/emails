#!/usr/bin/env bats
# Tests for emails welcome task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya

  # Make quota fail before network; welcome should honor HIMALAYA_CONFIG.
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.test-agent]
default = true
EOF
}

@test "welcome: failed recent fetch uses fallback without printing himalaya stderr" {
  cat > "$HIMALAYA" <<'MOCK'
#!/usr/bin/env bash
echo "mock himalaya failure: $*" >&2
exit 42
MOCK
  chmod +x "$HIMALAYA"

  run emails welcome

  [ "$status" -eq 0 ]
  [[ "$output" == *"Status: ✓ configured"* ]]
  [[ "$output" == *"(could not fetch - check connection)"* ]]
  [[ "$output" != *"mock himalaya failure"* ]]
}
