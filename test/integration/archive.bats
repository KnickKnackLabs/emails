#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load ../integration-helpers
  setup_maildir
}

@test "archive: moves message to Archive folder" {
  deposit_message --subject "Archive me"

  local id
  id=$(latest_envelope_id)

  run emails archive "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Archived"* ]]

  # Gone from INBOX
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [[ "$output" != *"Archive me"* ]]

  # Present in Archive
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" -f Archive --page-size 100 2>/dev/null
  [[ "$output" == *"Archive me"* ]]
}
