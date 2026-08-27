#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

load helpers

write_passing_test() {
  local path="$1" name="$2"
  local test_keyword='@test'
  mkdir -p "$(dirname "$path")"
  printf '%s\n' \
    '#!/usr/bin/env bats' \
    "$test_keyword \"$name\" {" \
    '  true' \
    '}' > "$path"
}

@test "options-only calls use the configured unit-test directory" {
  run emails test --jobs 1 --filter '^status: checks the selected account$'

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 status: checks the selected account'* ]]
}

@test "an explicit unit-test target takes precedence over the configured default" {
  local target="$BATS_TEST_TMPDIR/explicit.bats"
  write_passing_test "$target" 'explicit target only'

  run emails test --jobs 1 "$target"

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 explicit target only'* ]]
}

@test "relative unit-test targets resolve from the repository root" {
  run emails test --jobs 1 test/status.bats \
    --filter '^status: checks the selected account$'

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 status: checks the selected account'* ]]
}

@test "whitespace-bearing explicit unit-test targets remain one argument" {
  local target="$BATS_TEST_TMPDIR/explicit target/passing test.bats"
  write_passing_test "$target" 'whitespace target'

  run emails test --jobs 1 "$target"

  [ "$status" -eq 0 ]
  [[ "$output" == *'1..1'* ]]
  [[ "$output" == *'ok 1 whitespace target'* ]]
}

@test "the public unit-test path stays serial by default" {
  local target="$BATS_TEST_TMPDIR/serial.bats"
  export PROBE_DIR="$BATS_TEST_TMPDIR/serial-barrier"
  mkdir -p "$PROBE_DIR"
  local test_keyword='@test'

  cat > "$target" <<BATS
#!/usr/bin/env bats
$test_keyword "first test runs alone" {
  touch "\$PROBE_DIR/one"
  sleep 0.2
  [ ! -e "\$PROBE_DIR/two" ]
  rm "\$PROBE_DIR/one"
}
$test_keyword "second test runs alone" {
  touch "\$PROBE_DIR/two"
  sleep 0.2
  [ ! -e "\$PROBE_DIR/one" ]
  rm "\$PROBE_DIR/two"
}
BATS

  run emails test "$target"

  [ "$status" -eq 0 ]
}
