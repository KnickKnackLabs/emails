#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load ../integration-helpers
  setup_maildir
}

@test "delete: moves message to Trash" {
  deposit_message --subject "Delete me"

  local id
  id=$(latest_envelope_id)

  run emails delete "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Moved"* ]]
  [[ "$output" == *"Trash"* ]]

  # Gone from INBOX
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [[ "$output" != *"Delete me"* ]]

  # Present in Trash
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" -f Trash --page-size 100 2>/dev/null
  [[ "$output" == *"Delete me"* ]]
}

@test "delete: permanent delete removes message entirely" {
  deposit_message --subject "Destroy me"

  local id
  id=$(latest_envelope_id)

  run emails delete --permanent "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Permanently deleted"* ]]

  # Gone from INBOX
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [[ "$output" != *"Destroy me"* ]]

  # Not in Trash either
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" -f Trash --page-size 100 2>/dev/null
  [[ "$output" != *"Destroy me"* ]]
}

@test "delete: refuses to move Trash messages to Trash" {
  deposit_message --folder Trash --subject "Already trashed"

  local id
  id=$(latest_envelope_id Trash)

  run emails delete -f Trash "$id"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Cannot move Trash"* ]]
}

@test "delete: --all deletes all messages in folder" {
  deposit_message --subject "Bulk one"
  deposit_message --subject "Bulk two"
  deposit_message --subject "Bulk three"

  run emails delete --all
  [ "$status" -eq 0 ]

  # INBOX should be empty
  [ "$(maildir_count INBOX)" -eq 0 ]

  # All three should be in Trash
  [ "$(maildir_count Trash)" -eq 3 ]
}
