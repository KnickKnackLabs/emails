#!/usr/bin/env bats
# Tests for find_upward_email_config() and the config resolution chain

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_mock_himalaya
  unset EMAILS_CONFIG
  unset HIMALAYA_CONFIG
  unset EMAILS_CALLER_PWD
  unset EMAILS_ACCOUNT
}

# Create a minimal .emails/himalaya.toml in the given directory.
setup_caller_config() {
  local caller_dir="$1"
  mkdir -p "$caller_dir/.emails"
  cat > "$caller_dir/.emails/himalaya.toml" <<'EOF'
[accounts.test-agent]
default = true
email = "test-agent@ricon.family"
display-name = "Test Agent"
backend.type = "imap"
backend.host = "mail.ricon.family"
backend.port = 993
backend.encryption.type = "tls"
backend.login = "test-agent@ricon.family"
backend.auth.type = "password"
backend.auth.raw = "test-pass"
message.send.backend.type = "smtp"
message.send.backend.host = "mail.ricon.family"
message.send.backend.port = 465
message.send.backend.encryption.type = "tls"
message.send.backend.login = "test-agent@ricon.family"
message.send.backend.auth.type = "password"
message.send.backend.auth.raw = "test-pass"
EOF
}

@test "config-discovery: EMAILS_CALLER_PWD finds .emails/himalaya.toml upward" {
  local caller_dir="$BATS_TEST_TMPDIR/caller"
  setup_caller_config "$caller_dir"

  run bash -c 'EMAILS_CALLER_PWD="'"$caller_dir"'" source "$REPO_DIR/lib/email.sh" && printf "%s|%s|%s" "$CONFIG_FILE" "$ACCOUNT" "$ACCOUNT_EMAIL"'
  [ "$status" -eq 0 ]
  [ "$output" = "$caller_dir/.emails/himalaya.toml|test-agent|test-agent@ricon.family" ]
}

@test "config-discovery: public status task uses EMAILS_CALLER_PWD" {
  local caller_dir="$BATS_TEST_TMPDIR/caller"
  setup_caller_config "$caller_dir"

  run bash -c 'EMAILS_CALLER_PWD="$1" EMAILS_CONFIG= HIMALAYA_CONFIG= emails status' _ "$caller_dir"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Config: $caller_dir/.emails/himalaya.toml"* ]]
  [[ "$output" == *"Resolved account: test-agent <test-agent@ricon.family>"* ]]
  [[ "$output" == *"Connection: ✓"* ]]
}

@test "config-discovery: explicit EMAILS_CONFIG missing path does not fall back" {
  local caller_dir="$BATS_TEST_TMPDIR/caller"
  local missing_config="$BATS_TEST_TMPDIR/missing/himalaya.toml"
  setup_caller_config "$caller_dir"

  run bash -c 'EMAILS_CALLER_PWD="$1" EMAILS_CONFIG="$2" HIMALAYA_CONFIG= emails status' _ "$caller_dir" "$missing_config"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Config: $missing_config"* ]]
  [[ "$output" == *"Config exists: ✗"* ]]
  [[ "$output" != *"$caller_dir/.emails/himalaya.toml"* ]]
}

@test "config-discovery: explicit HIMALAYA_CONFIG missing path does not fall back" {
  local caller_dir="$BATS_TEST_TMPDIR/caller"
  local missing_config="$BATS_TEST_TMPDIR/missing/himalaya.toml"
  setup_caller_config "$caller_dir"

  run bash -c 'EMAILS_CALLER_PWD="$1" EMAILS_CONFIG= HIMALAYA_CONFIG="$2" emails status' _ "$caller_dir" "$missing_config"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Config: $missing_config"* ]]
  [[ "$output" == *"Config exists: ✗"* ]]
  [[ "$output" != *"$caller_dir/.emails/himalaya.toml"* ]]
}

@test "config-discovery: PWD fallback when EMAILS_CALLER_PWD is unset" {
  local caller_dir="$BATS_TEST_TMPDIR/pwd-caller"
  setup_caller_config "$caller_dir"

  run bash -c 'cd "'"$caller_dir"'" && source "$REPO_DIR/lib/email.sh" && printf "%s|%s|%s" "$CONFIG_FILE" "$ACCOUNT" "$ACCOUNT_EMAIL"'
  [ "$status" -eq 0 ]
  [ "$output" = "$caller_dir/.emails/himalaya.toml|test-agent|test-agent@ricon.family" ]
}

@test "config-discovery: falls through to HOME/.config/emails/himalaya.toml when nothing found upward" {
  local caller_dir="$BATS_TEST_TMPDIR/empty-caller"
  mkdir -p "$caller_dir"
  local expected="$HOME/.config/emails/himalaya.toml"

  # Use EMAILS_NO_ACCOUNT_RESOLUTION=1 to stop after config resolution,
  # since the global fallback path likely doesn't exist as a real file.
  run bash -c 'EMAILS_CALLER_PWD="'"$caller_dir"'" EMAILS_NO_ACCOUNT_RESOLUTION=1 source "$REPO_DIR/lib/email.sh" && printf "%s" "$CONFIG_FILE"'
  [ "$status" -eq 0 ]
  [ "$output" = "$expected" ]
}