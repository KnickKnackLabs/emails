#!/usr/bin/env bats
# Tests for emails reply task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya
}

@test "reply: ignores inherited usage_body when body is omitted" {
  usage_body="This inherited reply is long enough to pass validation but must not be used" run emails reply 42
  [ "$status" -ne 0 ]
  [[ "$output" == *"Reply body is required"* ]]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "reply: ignores inherited usage_body when only flags are supplied" {
  usage_body="This inherited reply is long enough to pass validation but must not be used" run emails reply 42 --html
  [ "$status" -ne 0 ]
  [[ "$output" == *"Reply body is required"* ]]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "reply: rejects body supplied positionally and with --body" {
  run emails reply 42 "positional reply body that is long enough to pass validation" -b "flag reply body that is long enough to pass validation"
  [ "$status" -ne 0 ]
  [[ "$output" == *"either positionally or with -b/--body"* ]]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}
