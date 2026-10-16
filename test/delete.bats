#!/usr/bin/env bats
# Tests for emails delete task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya
}

@test "delete: fails without arguments" {
  run emails delete
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
}

@test "delete: rejects non-numeric IDs" {
  run emails delete abc
  [ "$status" -ne 0 ]
  [[ "$output" == *"IDs must be numeric"* ]]
}

@test "delete: ignores inherited usage vars when args are omitted" {
  usage_ids=42 usage_all=true run emails delete
  [ "$status" -ne 0 ]
  [[ "$output" == *"Usage"* ]]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "delete: moves message to Trash by default" {
  run emails delete 42
  [ "$status" -eq 0 ]
  assert_himalaya_called "message delete"
  assert_himalaya_called "42"
  [[ "$output" == *"Moved 1 message(s) to Trash"* ]]
}

@test "delete: --permanent flags and expunges" {
  run emails delete --permanent 42
  [ "$status" -eq 0 ]
  assert_himalaya_called "flag add"
  assert_himalaya_called "deleted"
  assert_himalaya_called "folder expunge"
}

@test "delete: rejects non-permanent delete from Trash" {
  run emails delete -f Trash 42
  [ "$status" -ne 0 ]
  [[ "$output" == *"Cannot move Trash messages to Trash"* ]]
}

@test "delete: allows --permanent from Trash" {
  run emails delete --permanent -f Trash 42
  [ "$status" -eq 0 ]
  assert_himalaya_called "flag add"
}

@test "delete: failed listing cannot trigger deletion from partial output" {
  cat > "$MOCK_BIN/himalaya" <<'MOCK'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_HIMALAYA_CALLS"
printf 'header\nseparator\nseparator\n| 42 | partial |\n'
exit 42
MOCK

  run emails delete --all --permanent

  [ "$status" -ne 0 ]
  [[ "$output" != *"empty"* ]]
  ! grep -Eq 'message delete|flag add|folder expunge' "$MOCK_HIMALAYA_CALLS"
}

@test "delete: successful empty listing is not an error" {
  run emails delete --all

  [ "$status" -eq 0 ]
  [[ "$output" == *"INBOX is empty"* ]]
  ! grep -Eq 'message delete|flag add' "$MOCK_HIMALAYA_CALLS"
}

@test "delete: multiple IDs" {
  run emails delete 10 20 30
  [ "$status" -eq 0 ]
  assert_himalaya_called "message delete"
  [[ "$output" == *"Moved 3 message(s) to Trash"* ]]
}
