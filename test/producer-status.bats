#!/usr/bin/env bats
# Public task parsing must stop before using partial producer output.

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_himalaya
  export REAL_XARGS
  REAL_XARGS=$(command -v xargs)
  cat > "$MOCK_BIN/xargs" <<'SH'
#!/usr/bin/env bash
if [ ! -e "$BATS_TEST_TMPDIR/parser-failed" ]; then
  : > "$BATS_TEST_TMPDIR/parser-failed"
  printf '%s\n' "${PARTIAL_ARGUMENT-42}"
  exit 41
fi
exec "$REAL_XARGS" "$@"
SH
  chmod +x "$MOCK_BIN/xargs"
}

@test "send: argument parser failure cannot send a partial recipient list" {
  export PARTIAL_ARGUMENT=partial@example.test

  run emails send --to person@example.test --subject Test --body 'This is a sufficiently long synthetic body for testing only.'

  [ "$status" -ne 0 ]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "reply: argument parser failure cannot send without intended attachments" {
  export PARTIAL_ARGUMENT=''
  set_mock_response $'To: person@example.test\nSubject: Re: Test\n\n'
  printf 'synthetic attachment\n' > "$BATS_TEST_TMPDIR/attachment.txt"

  run emails reply 42 --body 'This is a sufficiently long synthetic reply for testing only.' --attach "$BATS_TEST_TMPDIR/attachment.txt"

  [ "$status" -ne 0 ]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "delete: argument parser failure cannot delete partial IDs" {
  run emails delete 42

  [ "$status" -ne 0 ]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "export: argument parser failure cannot export partial IDs" {
  run emails export 42 -d "$BATS_TEST_TMPDIR/exported"

  [ "$status" -ne 0 ]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "wait: query parser failure cannot start an unfiltered watch" {
  run emails wait --timeout 1 --interval 1 from example.test

  [ "$status" -ne 0 ]
  [ ! -s "$MOCK_HIMALAYA_CALLS" ]
}

@test "read: attachment snapshot failure stops before downloading" {
  cat > "$MOCK_BIN/himalaya" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$MOCK_HIMALAYA_CALLS"
case "$*" in
  *'message export'*)
    while [ "$#" -gt 1 ]; do
      if [ "$1" = -d ]; then
        printf 'Content-Disposition: attachment\n' > "$2"
        break
      fi
      shift
    done ;;
  *'message read'*) printf 'From: sender@example.test\n\nSynthetic message\n' ;;
esac
SH
  printf '#!/bin/sh\nexit 1\n' > "$MOCK_BIN/gpg"
  printf '#!/bin/sh\nexit 43\n' > "$MOCK_BIN/sort"
  chmod +x "$MOCK_BIN/gpg" "$MOCK_BIN/sort"

  run emails read 42 --save-attachments

  [ "$status" -ne 0 ]
  ! grep -q 'attachment download' "$MOCK_HIMALAYA_CALLS"
}

@test "compose: argument parser failure cannot render with partial options" {
  printf 'console.log("must not run");\n' > "$BATS_TEST_TMPDIR/draft.tsx"

  run emails compose "$BATS_TEST_TMPDIR/draft.tsx" --title Example

  [ "$status" -ne 0 ]
  [[ "$output" != *"must not run"* ]]
}
