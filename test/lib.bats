#!/usr/bin/env bats
# Tests for lib/email.sh — agent identity detection and config validation

bats_require_minimum_version 1.5.0

setup() {
  export MISE_CONFIG_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

  # Use HIMALAYA_CONFIG to isolate from real config
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
}

# ============================================================================
# Identity detection
# ============================================================================

@test "lib: detects agent from GIT_AUTHOR_EMAIL" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
EOF

  # Source the lib and check AGENT is set
  run bash -c 'source "$MISE_CONFIG_ROOT/lib/email.sh" && echo "$AGENT"'
  [ "$status" -eq 0 ]
  [ "$output" = "myagent" ]
}

@test "lib: fails without identity" {
  unset GIT_AUTHOR_EMAIL
  # Ensure git config doesn't have a ricon email
  export GIT_CONFIG_GLOBAL="$BATS_TEST_TMPDIR/gitconfig"
  echo "" > "$GIT_CONFIG_GLOBAL"

  run bash -c 'source "$MISE_CONFIG_ROOT/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"No agent identity"* ]]
}

@test "lib: fails without himalaya config" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  rm -f "$HIMALAYA_CONFIG"

  run bash -c 'source "$MISE_CONFIG_ROOT/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"not configured"* ]]
}

@test "lib: fails when agent account missing from config" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  # Config exists but has a different account
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.otheragent]
default = true
EOF

  run bash -c 'source "$MISE_CONFIG_ROOT/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"not configured"* ]]
}

# ============================================================================
# IMAP password extraction
# ============================================================================

@test "lib: extracts IMAP password when NEED_IMAP=1" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
backend.auth.type = "password"
backend.auth.raw = "s3cret-pass"
EOF

  run bash -c 'NEED_IMAP=1 source "$MISE_CONFIG_ROOT/lib/email.sh" && echo "$PASS"'
  [ "$status" -eq 0 ]
  [ "$output" = "s3cret-pass" ]
}

@test "lib: PASS is empty when NEED_IMAP not set" {
  export GIT_AUTHOR_EMAIL="myagent@ricon.family"
  cat > "$HIMALAYA_CONFIG" <<EOF
[accounts.myagent]
default = true
backend.auth.type = "password"
backend.auth.raw = "s3cret-pass"
EOF

  run bash -c 'source "$MISE_CONFIG_ROOT/lib/email.sh" && echo "PASS=${PASS:-empty}"'
  [ "$status" -eq 0 ]
  [ "$output" = "PASS=empty" ]
}
