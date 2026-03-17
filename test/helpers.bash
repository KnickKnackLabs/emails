# helpers.bash — shared setup for email BATS tests

REPO_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
FIXTURES_DIR="$BATS_TEST_DIRNAME/fixtures"

setup() {
  # Source the real graph.sh for its helper functions (format_date, truncate)
  source "$REPO_DIR/lib/graph.sh"

  # Override graph_get to return fixture data instead of hitting the API
  # Tests set FIXTURE_FILE before calling functions that use graph_get
  graph_get() {
    local endpoint="$1"
    if [ -n "${FIXTURE_FILE:-}" ]; then
      cat "$FIXTURE_FILE"
    else
      echo '{"value": []}'
    fi
  }

  # Override graph_post/graph_patch/graph_delete to no-op
  graph_post()   { echo '{}'; }
  graph_patch()  { echo '{}'; }
  graph_delete() { echo ''; }

  # Override graph_get_token to skip auth
  graph_get_token() { echo "fake-token-for-testing"; }

  # Set MISE_CONFIG_ROOT so tasks can source lib/graph.sh
  export MISE_CONFIG_ROOT="$REPO_DIR"
}

# Helper: load a fixture file by name (from test/fixtures/)
load_fixture() {
  local name="$1"
  FIXTURE_FILE="$FIXTURES_DIR/${name}.json"
  export FIXTURE_FILE
}

# Helper: get fixture JSON directly
fixture_json() {
  local name="$1"
  cat "$FIXTURES_DIR/${name}.json"
}

# Helper: count items in a JSON array fixture
fixture_count() {
  local name="$1"
  jq '.value | length' "$FIXTURES_DIR/${name}.json"
}
