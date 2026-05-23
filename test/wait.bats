#!/usr/bin/env bats
# Tests for emails wait task — specifically the variadic-query arg handling.
#
# wait's query is passed through to `himalaya envelope list <QUERY...>` and
# needs to preserve multi-word quoted values as single arguments. Under the
# old read -ra pattern, `emails wait --query "from groups.io"` would split
# into ["from", "groups.io"] — two args, not one phrase query.

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya
  # Mock himalaya to return empty "-o json" output immediately, so wait's
  # initial snapshot is stable and the task has something to exit from
  # cleanly on --timeout 0.
  set_mock_response '[]'
}

# wait's contract: --timeout 0 means "poll forever", --timeout 1 + --interval 1
# yields one snapshot+poll cycle then exit (~1s wall time).
#
# We can't pass --timeout / --interval on the CLI here — mise has its own
# --timeout flag and intercepts it before the task sees it. So we set the
# usage_* env vars directly; mise propagates them through to the script.

@test "wait: quoted multi-word --query is passed as a single himalaya arg" {
  usage_timeout=1 usage_interval=1 run emails wait "from groups.io"
  [ "$status" -eq 0 ]
  # The mock logs each invocation's args, space-joined, on its own line.
  # 'from groups.io' should appear together as one phrase — not split by a
  # newline (which would mean read -ra fragmented it into two args).
  run cat "$MOCK_HIMALAYA_CALLS"
  [[ "$output" == *"from groups.io"* ]]
}

@test "wait: empty --query omits query args from himalaya call" {
  usage_timeout=1 usage_interval=1 run emails wait
  [ "$status" -eq 0 ]
  run grep -c "from " "$MOCK_HIMALAYA_CALLS"
  [ "$output" = "0" ]
}
