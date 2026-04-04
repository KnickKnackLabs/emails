#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load ../integration-helpers
  setup_maildir
}

@test "list: shows deposited messages" {
  deposit_message --subject "First message"
  deposit_message --subject "Second message"

  run emails list
  [ "$status" -eq 0 ]
  [[ "$output" == *"First message"* ]]
  [[ "$output" == *"Second message"* ]]
}

@test "list: respects --limit flag" {
  for i in 1 2 3 4 5; do
    deposit_message --subject "Message $i"
  done

  run emails list -n 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"more available"* ]]
}

@test "list: shows different folders" {
  deposit_message --folder INBOX --subject "Inbox msg"
  deposit_message --folder Trash --subject "Trash msg"

  run emails list -f INBOX
  [ "$status" -eq 0 ]
  [[ "$output" == *"Inbox msg"* ]]
  [[ "$output" != *"Trash msg"* ]]

  run emails list -f Trash
  [ "$status" -eq 0 ]
  [[ "$output" == *"Trash msg"* ]]
  [[ "$output" != *"Inbox msg"* ]]
}

@test "list: --count returns message count" {
  deposit_message --subject "One"
  deposit_message --subject "Two"
  deposit_message --subject "Three"

  run emails list --count
  [ "$status" -eq 0 ]
  [[ "$output" == *"3"* ]]
}

@test "list: empty folder shows no messages" {
  run emails list
  [ "$status" -eq 0 ]
  [[ "$output" == *"SUBJECT"* ]]
}
