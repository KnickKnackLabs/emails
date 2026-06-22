#!/usr/bin/env bats
# Tests for emails example task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
}

@test "example: lists available examples" {
  run emails example
  [ "$status" -eq 0 ]
  [[ "$output" == *"Available email examples"* ]]
  [[ "$output" == *"business-letter"* ]]
  [[ "$output" == *"session-report"* ]]
  [[ "$output" == *"emails example business-letter > draft.tsx"* ]]
}

@test "example: emits business-letter TSX that composes" {
  run emails example business-letter
  [ "$status" -eq 0 ]
  [[ "$output" == *"Business letter example"* ]]
  [[ "$output" == *"Your Company"* ]]
  [[ "$output" == *"Agent-assisted software and operations"* ]]

  local example_file="$BATS_TEST_TMPDIR/business-letter.tsx"
  printf '%s\n' "$output" > "$example_file"

  run emails compose "$example_file"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<!doctype html>"* ]]
  [[ "$output" == *"width=\"860\""* ]]
  [[ "$output" == *"Your Company"* ]]
  [[ "$output" == *"What I would want to understand next"* ]]
  [[ "$output" == *"&bull;"* ]]
}

@test "example: rejects unknown example" {
  run emails example nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown example: nope"* ]]
  [[ "$output" == *"business-letter"* ]]
}
