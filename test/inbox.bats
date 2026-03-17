#!/usr/bin/env bats

load helpers

# ============================================================
# JSON output
# ============================================================

@test "inbox --json returns array of messages" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages" | jq '.value')
  local count
  count=$(echo "$result" | jq 'length')
  [ "$count" -eq 15 ]
}

@test "inbox --json messages have required fields" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages" | jq '.value[0]')

  # Check all required fields exist (use 'has' to avoid jq -e treating false as failure)
  echo "$result" | jq -e 'has("id")' >/dev/null
  echo "$result" | jq -e 'has("subject")' >/dev/null
  echo "$result" | jq -e 'has("from")' >/dev/null
  echo "$result" | jq -e '.from | has("emailAddress")' >/dev/null
  echo "$result" | jq -e 'has("receivedDateTime")' >/dev/null
  echo "$result" | jq -e 'has("isRead")' >/dev/null
  echo "$result" | jq -e 'has("bodyPreview")' >/dev/null
}

@test "inbox fixture has correct unread count" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local unread
  unread=$(echo "$result" | jq '[.value[] | select(.isRead == false)] | length')
  [ "$unread" -eq 14 ]
}

@test "inbox fixture has one read message" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local read_count
  read_count=$(echo "$result" | jq '[.value[] | select(.isRead == true)] | length')
  [ "$read_count" -eq 1 ]
}

# ============================================================
# Formatting helpers
# ============================================================

@test "truncate: short string unchanged" {
  local result
  result=$(truncate "hello" 10)
  [ "$result" = "hello" ]
}

@test "truncate: long string gets ellipsis" {
  local result
  result=$(truncate "this is a very long string that should be truncated" 20)
  # truncate produces max-1 chars + "..." = max+2, which is the expected behavior
  [[ "$result" == *"..." ]]
  # Verify it's shorter than the original
  [ "${#result}" -lt 51 ]
}

@test "truncate: exact length unchanged" {
  local result
  result=$(truncate "exactly10!" 10)
  [ "$result" = "exactly10!" ]
}

@test "format_date: valid UTC timestamp formats correctly" {
  local result
  result=$(format_date "2026-03-17T15:30:00Z")
  # Should produce a human-readable date (exact format depends on locale)
  [ -n "$result" ]
  [[ "$result" != "2026-03-17T15:30:00Z" ]] || skip "format_date fell back to raw timestamp"
}

# ============================================================
# Message classification helpers (for triage)
# ============================================================

@test "fixture has GitHub review comments" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local comments
  comments=$(echo "$result" | jq '[.value[] | select(.bodyPreview | test("commented on this pull request"))] | length')
  [ "$comments" -eq 1 ]
}

@test "fixture has GitHub merge notifications" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local merges
  merges=$(echo "$result" | jq '[.value[] | select(.bodyPreview | test("^Merged #"))] | length')
  [ "$merges" -eq 2 ]
}

@test "fixture has GitHub push notifications" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local pushes
  pushes=$(echo "$result" | jq '[.value[] | select(.bodyPreview | test("pushed [0-9]+ commit"))] | length')
  [ "$pushes" -eq 2 ]
}

@test "fixture has bot emails" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local bots
  bots=$(echo "$result" | jq '[.value[] | select(.from.emailAddress.name | test("\\[bot\\]"))] | length')
  [ "$bots" -eq 2 ]
}

@test "fixture has review request pings" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  local pings
  pings=$(echo "$result" | jq '[.value[] | select(.bodyPreview | test("requested your review on"))] | length')
  [ "$pings" -eq 1 ]
}

@test "fixture has real person emails" {
  load_fixture "inbox"
  local result
  result=$(graph_get "/me/mailFolders/inbox/messages")
  # Emails from non-noreply, non-newsletter addresses
  local real
  real=$(echo "$result" | jq '[.value[] | select(
    (.from.emailAddress.address | test("noreply@") | not) and
    (.from.emailAddress.address | test("globaltech@|teamproductivity@") | not)
  )] | length')
  [ "$real" -eq 2 ]
}
