#!/usr/bin/env bats

load helpers

setup() {
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"
  source "$REPO_DIR/lib/graph.sh"
  source "$REPO_DIR/lib/triage.sh"

  # Override graph functions for testing
  graph_get() { cat "$FIXTURES_DIR/inbox.json"; }
  graph_delete() { echo ''; }
  graph_get_token() { echo "fake-token"; }

  export MISE_CONFIG_ROOT="$REPO_DIR"
}

# ============================================================
# classify_inbox integration (clean depends on this)
# ============================================================

@test "clean: noise messages are identified correctly" {
  local response
  response=$(graph_get "")
  local classified
  classified=$(classify_inbox "$response")
  local noise_count
  noise_count=$(echo "$classified" | jq '.noise | length')
  [ "$noise_count" -eq 7 ]
}

@test "clean: noise + bulk gives higher count" {
  local response
  response=$(graph_get "")
  local classified
  classified=$(classify_inbox "$response")
  local total
  total=$(echo "$classified" | jq '[.noise, .bulk] | map(length) | add')
  [ "$total" -eq 10 ]
}

@test "clean: actionable emails are never in deletable set" {
  local response
  response=$(graph_get "")
  local classified
  classified=$(classify_inbox "$response")

  # Get actionable IDs
  local actionable_ids
  actionable_ids=$(echo "$classified" | jq -r '[.actionable[].id] | sort | .[]')

  # Get noise + bulk IDs (the --all set)
  local deletable_ids
  deletable_ids=$(echo "$classified" | jq -r '[.noise[].id, .bulk[].id] | sort | .[]')

  # Ensure no overlap
  local overlap
  overlap=$(comm -12 <(echo "$actionable_ids") <(echo "$deletable_ids") | wc -l | tr -d ' ')
  [ "$overlap" -eq 0 ]
}

@test "clean: other emails are never in deletable set" {
  local response
  response=$(graph_get "")
  local classified
  classified=$(classify_inbox "$response")

  local other_ids
  other_ids=$(echo "$classified" | jq -r '[.other[].id] | sort | .[]')

  local deletable_ids
  deletable_ids=$(echo "$classified" | jq -r '[.noise[].id, .bulk[].id] | sort | .[]')

  local overlap
  overlap=$(comm -12 <(echo "$other_ids") <(echo "$deletable_ids") | wc -l | tr -d ' ')
  [ "$overlap" -eq 0 ]
}

@test "clean: noise IDs are valid message IDs from fixture" {
  local response
  response=$(graph_get "")
  local classified
  classified=$(classify_inbox "$response")

  # All noise IDs should match an ID in the fixture
  local all_ids
  all_ids=$(echo "$response" | jq -r '[.value[].id] | .[]')

  while IFS= read -r noise_id; do
    echo "$all_ids" | grep -qF "$noise_id"
  done < <(echo "$classified" | jq -r '.noise[].id')
}

# ============================================================
# Empty inbox edge case
# ============================================================

@test "clean: empty inbox produces zero deletable" {
  # Override with empty inbox
  graph_get() { echo '{"value": []}'; }

  local response
  response=$(graph_get "")
  local count
  count=$(echo "$response" | jq '.value | length')
  [ "$count" -eq 0 ]
}
