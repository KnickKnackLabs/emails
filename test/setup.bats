#!/usr/bin/env bats
# Tests for explicit account setup and account policy tasks

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_mock_himalaya
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya/config.toml"
  export GIT_AUTHOR_EMAIL="c0da@ricon.family"
  unset AGENT_HOME
  unset EMAIL_PASSWORD
}

setup_account() {
  local name="$1"
  local address="$2"
  shift 2
  printf '%s' "password-$name" | emails account:setup "$name" \
    --address "$address" \
    --display-name "c0da" \
    --imap-host mail.example.test \
    --smtp-host smtp.example.test \
    --password-stdin \
    "$@"
}

@test "setup: deprecated wrapper points to account setup" {
  run emails setup c0da

  [ "$status" -ne 0 ]
  [[ "$output" == *"emails setup is deprecated"* ]]
  [[ "$output" == *"emails account setup personal"* ]]
}

@test "account setup: configures explicit account without implicit default or GPG" {
  run setup_account personal c0da@ricon.family

  [ "$status" -eq 0 ]
  [[ "$output" == *"Email account configured: personal"* ]]
  [[ "$output" == *"Default: no"* ]]
  [[ "$output" == *"GPG:     disabled"* ]]
  grep -qF '[accounts.personal]' "$HIMALAYA_CONFIG"
  grep -qF 'default = false' "$HIMALAYA_CONFIG"
  grep -qF 'email = "c0da@ricon.family"' "$HIMALAYA_CONFIG"
  grep -qF 'backend.auth.raw = "password-personal"' "$HIMALAYA_CONFIG"
  run ! grep -qF 'pgp.sign-cmd' "$HIMALAYA_CONFIG"
}

@test "account setup: can set default and enable account GPG" {
  run setup_account kkl c0da@knacklabs.co --set-default --gpg-local-user c0da@knacklabs.co

  [ "$status" -eq 0 ]
  [[ "$output" == *"Default: yes"* ]]
  [[ "$output" == *"GPG:     enabled (c0da@knacklabs.co)"* ]]
  grep -qF '[accounts.kkl]' "$HIMALAYA_CONFIG"
  grep -qF 'default = true' "$HIMALAYA_CONFIG"
  grep -qF 'email = "c0da@knacklabs.co"' "$HIMALAYA_CONFIG"
  grep -qF 'pgp.sign-cmd = "gpg --local-user '\''<c0da@knacklabs.co>'\'' --sign --quiet --armor"' "$HIMALAYA_CONFIG"
}

@test "account setup: --set-default clears existing defaults" {
  setup_account personal c0da@ricon.family --set-default >/dev/null

  run setup_account kkl c0da@knacklabs.co --set-default

  [ "$status" -eq 0 ]
  awk '
    $0 == "[accounts.personal]" { in_personal = 1; in_kkl = 0 }
    $0 == "[accounts.kkl]" { in_personal = 0; in_kkl = 1 }
    in_personal && $0 == "default = false" { personal = 1 }
    in_kkl && $0 == "default = true" { kkl = 1 }
    END { exit !(personal && kkl) }
  ' "$HIMALAYA_CONFIG"
}

@test "account setup: rejects dotted account names" {
  run setup_account personal.home c0da@ricon.family

  [ "$status" -ne 0 ]
  [[ "$output" == *"account name must contain only letters, numbers, underscore, or dash"* ]]
}

@test "account setup: rejects non-numeric ports" {
  run setup_account personal c0da@ricon.family --imap-port not-a-port

  [ "$status" -ne 0 ]
  [[ "$output" == *"--imap-port must be numeric"* ]]
}

@test "account setup: rejects newline/control characters in generated TOML strings" {
  run bash -c 'printf "line1\nline2" | emails account:setup personal --address c0da@ricon.family --imap-host mail.example.test --smtp-host smtp.example.test --password-stdin'

  [ "$status" -ne 0 ]
  [[ "$output" == *"password must not contain control characters or newlines"* ]]
}

@test "account setup: rejects unsafe GPG local-user selectors" {
  run setup_account personal c0da@ricon.family --gpg-local-user "bad' ; touch /tmp/emails-pwn ; echo '"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--gpg-local-user may contain only"* ]]
}

@test "account setup: rejects missing password stdin" {
  run emails account:setup personal \
    --address c0da@ricon.family \
    --imap-host mail.example.test \
    --smtp-host smtp.example.test

  [ "$status" -ne 0 ]
  [[ "$output" == *"provide the password explicitly with --password-stdin"* ]]
}

@test "account default: ignores nested account tables" {
  mkdir -p "$(dirname "$HIMALAYA_CONFIG")"
  cat > "$HIMALAYA_CONFIG" <<'EOF'
[accounts.personal]
email = "person@example.test"

[accounts.personal.backend]
host = "imap.example.test"

[accounts.kkl]
email = "c0da@knacklabs.co"
EOF

  run emails account:default personal

  [ "$status" -eq 0 ]
  awk '
    $0 == "[accounts.personal]" { section = "personal"; next }
    $0 == "[accounts.personal.backend]" { section = "backend"; next }
    $0 == "[accounts.kkl]" { section = "kkl"; next }
    section == "personal" && $0 == "default = true" { personal = 1 }
    section == "backend" && $0 ~ /^default[[:space:]]*=/ { bad_backend = 1 }
    section == "kkl" && $0 == "default = false" { kkl = 1 }
    END { exit !(personal && kkl && !bad_backend) }
  ' "$HIMALAYA_CONFIG"
}

@test "account default: sets exactly one default" {
  setup_account personal c0da@ricon.family >/dev/null
  setup_account kkl c0da@knacklabs.co >/dev/null

  run emails account:default kkl

  [ "$status" -eq 0 ]
  [[ "$output" == *"Default email account set to: kkl"* ]]
  awk '
    $0 == "[accounts.personal]" { in_personal = 1; in_kkl = 0 }
    $0 == "[accounts.kkl]" { in_personal = 0; in_kkl = 1 }
    in_personal && $0 == "default = false" { personal = 1 }
    in_kkl && $0 == "default = true" { kkl = 1 }
    END { exit !(personal && kkl) }
  ' "$HIMALAYA_CONFIG"
}

@test "account gpg: rejects unsafe local-user selectors" {
  setup_account personal c0da@ricon.family >/dev/null

  run emails account:gpg:enable personal --local-user "bad' ; touch /tmp/emails-pwn ; echo '"

  [ "$status" -ne 0 ]
  [[ "$output" == *"--gpg-local-user may contain only"* ]]
}

@test "account gpg: enable, status, and disable" {
  setup_account personal c0da@ricon.family >/dev/null

  run emails account:gpg:enable personal --local-user c0da@ricon.family
  [ "$status" -eq 0 ]
  [[ "$output" == *"GPG signing enabled for personal"* ]]
  grep -qF 'pgp.sign-cmd = "gpg --local-user '\''<c0da@ricon.family>'\'' --sign --quiet --armor"' "$HIMALAYA_CONFIG"

  run emails account:gpg:status personal
  [ "$status" -eq 0 ]
  [[ "$output" == *"GPG signing: enabled"* ]]

  run emails account:gpg:disable personal
  [ "$status" -eq 0 ]
  [[ "$output" == *"GPG signing disabled for personal"* ]]
  run ! grep -qF 'pgp.sign-cmd' "$HIMALAYA_CONFIG"
}
