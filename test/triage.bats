#!/usr/bin/env bats

load helpers

setup() {
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"
  source "$REPO_DIR/lib/graph.sh"
  source "$REPO_DIR/lib/triage.sh"
  export MISE_CONFIG_ROOT="$REPO_DIR"
}

# ============================================================
# classify_message — individual message classification
# ============================================================

@test "classify: review comment is actionable" {
  local msg
  msg=$(jq '.value[0]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "actionable" ]
}

@test "classify: approval is actionable" {
  local msg
  msg=$(jq '.value[1]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "actionable" ]
}

@test "classify: requested changes is actionable" {
  local msg
  msg=$(jq '.value[11]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "actionable" ]
}

@test "classify: merge notification is noise" {
  local msg
  msg=$(jq '.value[2]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "noise" ]
}

@test "classify: push notification is noise" {
  local msg
  msg=$(jq '.value[4]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "noise" ]
}

@test "classify: review request ping is noise" {
  local msg
  msg=$(jq '.value[5]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "noise" ]
}

@test "classify: sonarqube bot is noise" {
  local msg
  msg=$(jq '.value[6]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "noise" ]
}

@test "classify: qodo-merge bot is noise" {
  local msg
  msg=$(jq '.value[7]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "noise" ]
}

@test "classify: Team Productivity is bulk" {
  local msg
  msg=$(jq '.value[8]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "bulk" ]
}

@test "classify: Global Tech newsletter is bulk" {
  local msg
  msg=$(jq '.value[9]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "bulk" ]
}

@test "classify: real person email is other" {
  local msg
  msg=$(jq '.value[12]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "other" ]
}

@test "classify: high-importance email is other" {
  local msg
  msg=$(jq '.value[14]' "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_message "$msg")
  [ "$result" = "other" ]
}

# ============================================================
# classify_inbox — full inbox classification
# ============================================================

@test "classify_inbox: returns all four categories" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  echo "$result" | jq -e 'has("actionable")' >/dev/null
  echo "$result" | jq -e 'has("noise")' >/dev/null
  echo "$result" | jq -e 'has("bulk")' >/dev/null
  echo "$result" | jq -e 'has("other")' >/dev/null
}

@test "classify_inbox: correct actionable count" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  local count
  count=$(echo "$result" | jq '.actionable | length')
  [ "$count" -eq 3 ]
}

@test "classify_inbox: correct noise count" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  local count
  count=$(echo "$result" | jq '.noise | length')
  [ "$count" -eq 7 ]
}

@test "classify_inbox: correct bulk count" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  local count
  count=$(echo "$result" | jq '.bulk | length')
  [ "$count" -eq 3 ]
}

@test "classify_inbox: correct other count" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  local count
  count=$(echo "$result" | jq '.other | length')
  [ "$count" -eq 2 ]
}

@test "classify_inbox: items have required fields" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  local first
  first=$(echo "$result" | jq '.actionable[0]')
  echo "$first" | jq -e 'has("id")' >/dev/null
  echo "$first" | jq -e 'has("num")' >/dev/null
  echo "$first" | jq -e 'has("subject")' >/dev/null
  echo "$first" | jq -e 'has("from")' >/dev/null
  echo "$first" | jq -e 'has("category")' >/dev/null
}

@test "classify_inbox: noise message nums are correct for delete command" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  # Noise nums should be comma-joinable for email delete
  local nums
  nums=$(echo "$result" | jq -r '[.noise[].num] | map(tostring) | join(",")')
  [ -n "$nums" ]
  # Should contain multiple numbers
  [[ "$nums" == *","* ]]
}

@test "classify_inbox: total classified equals total messages" {
  local response
  response=$(cat "$FIXTURES_DIR/inbox.json")
  local result
  result=$(classify_inbox "$response")
  local total
  total=$(echo "$result" | jq '[.actionable, .noise, .bulk, .other] | map(length) | add')
  [ "$total" -eq 15 ]
}
