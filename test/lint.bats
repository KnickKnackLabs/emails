#!/usr/bin/env bats
# Repository lint checks

bats_require_minimum_version 1.5.0
load helpers

codebase_lint() {
  cd "$REPO_DIR" && mise exec -- codebase lint "$REPO_DIR"
}
export -f codebase_lint

@test "lint: codebase checks pass" {
  run codebase_lint

  [ "$status" -eq 0 ]
  [[ "$output" =~ codebase:\ all\ [0-9]+\ lint\ rule\(s\)\ passed ]]
}
