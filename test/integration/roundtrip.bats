#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load ../integration-helpers
  setup_maildir
}

@test "roundtrip: send → list → read → delete → verify" {
  # Send
  emails send test-agent@ricon.family "Round trip test" \
    "This message exercises the full lifecycle: send, list, read, and delete."

  # List — message appears in INBOX (via fake sendmail delivery)
  run emails list
  [ "$status" -eq 0 ]
  [[ "$output" == *"Round trip test"* ]]

  # Get the ID
  local id
  id=$(latest_envelope_id)
  [ -n "$id" ] || fail "no message found after send"

  # Read
  run emails read "$id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"full lifecycle"* ]]

  # Delete (move to Trash)
  run emails delete "$id"
  [ "$status" -eq 0 ]

  # Verify: gone from INBOX
  run emails list
  [[ "$output" != *"Round trip test"* ]]

  # Verify: in Trash
  run emails list -f Trash
  [[ "$output" == *"Round trip test"* ]]
}

@test "roundtrip: send → archive" {
  emails send test-agent@ricon.family "Archive after send" \
    "This message will be archived immediately after being received in the inbox."

  local id
  id=$(latest_envelope_id)

  emails archive "$id"

  # Gone from INBOX
  run emails list
  [[ "$output" != *"Archive after send"* ]]

  # In Archive
  run emails list -f Archive
  [[ "$output" == *"Archive after send"* ]]
}

@test "roundtrip: multiple messages maintain isolation" {
  deposit_message --subject "Message A" --from "alice@example.com"
  deposit_message --subject "Message B" --from "bob@example.com"

  # Both visible
  run emails list
  [[ "$output" == *"Message A"* ]]
  [[ "$output" == *"Message B"* ]]

  # Delete just the first one
  local ids
  ids=$(himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null \
    | tail -n +4 | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}' | grep -E '^[0-9]+$')

  local first_id
  first_id=$(echo "$ids" | head -1)

  emails delete "$first_id"

  # One remains in INBOX
  [ "$(maildir_count INBOX)" -ge 1 ]
}
