#!/usr/bin/env bats
# Tests for emails template task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
}

@test "template: lists available templates" {
  run emails template
  [ "$status" -eq 0 ]
  [[ "$output" == *"Available email templates"* ]]
  [[ "$output" == *"business-letter"* ]]
  [[ "$output" == *"emails template business-letter > draft.tsx"* ]]
}

@test "template: emits business-letter TSX that composes" {
  run emails template business-letter
  [ "$status" -eq 0 ]
  [[ "$output" == *"Business letter template"* ]]
  [[ "$output" == *"Your Company"* ]]
  [[ "$output" == *"Agent-assisted software and operations"* ]]

  local template_file="$BATS_TEST_TMPDIR/business-letter.tsx"
  printf '%s\n' "$output" > "$template_file"

  run emails compose "$template_file"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<!doctype html>"* ]]
  [[ "$output" == *"width=\"860\""* ]]
  [[ "$output" == *"Your Company"* ]]
  [[ "$output" == *"What I would want to understand next"* ]]
  [[ "$output" == *"&bull;"* ]]
}

@test "template: rejects unknown template" {
  run emails template nope
  [ "$status" -ne 0 ]
  [[ "$output" == *"unknown template: nope"* ]]
  [[ "$output" == *"business-letter"* ]]
}
