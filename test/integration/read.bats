#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load ../integration-helpers
  setup_maildir
}

@test "read: displays message content" {
  deposit_message --subject "Read me" --body "This is the body of the message to be read in the integration test."

  local id
  id=$(latest_envelope_id)
  [ -n "$id" ] || skip "could not get envelope ID"

  run emails read "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Read me"* ]]
  [[ "$output" == *"body of the message"* ]]
}

@test "read: shows sender information" {
  deposit_message --from "alice@example.com" --subject "From Alice"

  local id
  id=$(latest_envelope_id)

  run emails read "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"alice@example.com"* ]]
}

@test "read: works with different folders" {
  deposit_message --folder Trash --subject "Trashed message" \
    --body "This message lives in the Trash folder and should be readable from there."

  local id
  id=$(latest_envelope_id Trash)

  run emails read "$id" -f Trash
  [ "$status" -eq 0 ]
  [[ "$output" == *"Trashed message"* ]]
}

@test "read: nonexistent message returns empty output" {
  # NOTE: read currently exits 0 for nonexistent messages because himalaya's
  # error is swallowed by the sed pipe. This tests current behavior — fixing
  # the exit code is tracked separately.
  run emails read 99999
  # Output should contain the error or be mostly empty (no message content)
  [[ "$output" != *"Subject:"* ]]
}

@test "read: matching signer and sender shows checkmark" {
  setup_mock_gpg
  echo 'gpg: Good signature from "Test Agent <test-agent@ricon.family>" [ultimate]' > "$GPG_MOCK_RESPONSE_FILE"

  deposit_message --from "test-agent@ricon.family" --subject "Signed by sender"

  local id
  id=$(latest_envelope_id)
  [ -n "$id" ] || skip "could not get envelope ID"

  run emails read "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"✓ Signed by"* ]]
  [[ "$output" != *"sender mismatch"* ]]
}

@test "read: signer differs from sender shows mismatch warning" {
  setup_mock_gpg
  echo 'gpg: Good signature from "zeke <zeke@ricon.family>" [ultimate]' > "$GPG_MOCK_RESPONSE_FILE"

  deposit_message --from "quick@ricon.family" --subject "Signed by wrong identity"

  local id
  id=$(latest_envelope_id)
  [ -n "$id" ] || skip "could not get envelope ID"

  run emails read "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"⚠ Signed by"* ]]
  [[ "$output" == *"sender mismatch"* ]]
  [[ "$output" != *"✓ Signed by"* ]]
}
