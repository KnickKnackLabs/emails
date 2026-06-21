#!/usr/bin/env bats
# Tests for emails list task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya
}

@test "list: calls himalaya envelope list with selected account" {
  set_mock_response "
| ID  | FLAGS | SUBJECT    | FROM              | DATE       |
|-----|-------|------------|-------------------|------------|
| 1   |  *    | Test email | bob@ricon.family  | 2026-04-04 |
"
  run emails list
  [ "$status" -eq 0 ]
  assert_himalaya_called "envelope list"
  assert_himalaya_called "-a test-agent"
}

@test "list: respects --limit flag" {
  set_mock_response ""
  run emails list -n 5
  [ "$status" -eq 0 ]
  assert_himalaya_called "--page-size 6"
}

@test "list: respects --folder flag" {
  set_mock_response ""
  run emails list -f Sent
  [ "$status" -eq 0 ]
  assert_himalaya_called "-f Sent"
}

@test "list: --unread adds query filter" {
  set_mock_response ""
  run emails list --unread
  [ "$status" -eq 0 ]
  assert_himalaya_called "not flag seen"
}

@test "list: --count mode calls himalaya with large page size" {
  set_mock_response "
| ID  | FLAGS | SUBJECT    | FROM              | DATE       |
|-----|-------|------------|-------------------|------------|
| 1   |  *    | Test email | bob@ricon.family  | 2026-04-04 |
"
  run emails list --count
  [ "$status" -eq 0 ]
  assert_himalaya_called "--page-size 10000"
}

@test "list: fails without email config" {
  rm -f "$HIMALAYA_CONFIG"

  run emails list

  [ "$status" -ne 0 ]
  [[ "$output" == *"Email config not found"* ]]
}
