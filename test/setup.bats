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

@test "account setup: rejects missing password stdin" {
  run emails account:setup personal \
    --address c0da@ricon.family \
    --imap-host mail.example.test \
    --smtp-host smtp.example.test

  [ "$status" -ne 0 ]
  [[ "$output" == *"provide the password explicitly with --password-stdin"* ]]
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
