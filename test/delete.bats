#!/usr/bin/env bats
# Tests for emails delete task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  export MISE_CONFIG_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
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

@test "delete: multiple IDs" {
  run emails delete 10 20 30
  [ "$status" -eq 0 ]
  assert_himalaya_called "message delete"
  [[ "$output" == *"Moved 3 message(s) to Trash"* ]]
}
