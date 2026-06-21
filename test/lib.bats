#!/usr/bin/env bats
# Tests for lib/email.sh — config and account resolution

bats_require_minimum_version 1.5.0

setup() {
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  unset EMAILS_CONFIG
  unset EMAILS_ACCOUNT
}

write_config() {
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.personal]
default = false
email = "person@example.test"
backend.auth.raw = "personal-pass"
downloads-dir = "/tmp/personal-downloads"

[accounts.kkl]
default = true
email = "c0da@knacklabs.co"
backend.auth.raw = "kkl-pass"
EOF
}

@test "lib: resolves the only configured account without default" {
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.personal]
default = false
email = "person@example.test"
EOF

  run bash -c 'source "$REPO_DIR/lib/email.sh" && printf "%s|%s" "$ACCOUNT" "$ACCOUNT_EMAIL"'
  [ "$status" -eq 0 ]
  [ "$output" = "personal|person@example.test" ]
}

@test "lib: resolves default account when multiple accounts exist" {
  write_config

  run bash -c 'source "$REPO_DIR/lib/email.sh" && printf "%s|%s" "$ACCOUNT" "$ACCOUNT_EMAIL"'
  [ "$status" -eq 0 ]
  [ "$output" = "kkl|c0da@knacklabs.co" ]
}

@test "lib: EMAILS_ACCOUNT selects account" {
  write_config

  run bash -c 'EMAILS_ACCOUNT=personal source "$REPO_DIR/lib/email.sh" && printf "%s|%s|%s" "$ACCOUNT" "$ACCOUNT_EMAIL" "$ACCOUNT_DOWNLOADS_DIR"'
  [ "$status" -eq 0 ]
  [ "$output" = "personal|person@example.test|/tmp/personal-downloads" ]
}

@test "lib: fails when multiple accounts have no default" {
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.personal]
default = false
email = "person@example.test"

[accounts.kkl]
default = false
email = "c0da@knacklabs.co"
EOF

  run bash -c 'source "$REPO_DIR/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Multiple email accounts configured and no default is set"* ]]
}

@test "lib: fails without himalaya config" {
  rm -f "$HIMALAYA_CONFIG"

  run bash -c 'source "$REPO_DIR/lib/email.sh"'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Email config not found"* ]]
}

@test "lib: extracts IMAP password when NEED_IMAP=1" {
  write_config

  run bash -c 'NEED_IMAP=1 source "$REPO_DIR/lib/email.sh" && echo "$PASS"'
  [ "$status" -eq 0 ]
  [ "$output" = "kkl-pass" ]
}

@test "lib: PASS is empty when NEED_IMAP not set" {
  write_config

  run bash -c 'source "$REPO_DIR/lib/email.sh" && echo "PASS=${PASS:-empty}"'
  [ "$status" -eq 0 ]
  [ "$output" = "PASS=empty" ]
}
