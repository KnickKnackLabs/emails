#!/usr/bin/env bats
# Tests for emails sizes task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  setup_agent
  setup_mock_openssl
}

setup_mock_openssl() {
  export MOCK_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"

  cat > "$MOCK_BIN/openssl" <<'MOCK'
#!/usr/bin/env bash
cat >/dev/null

if [ "${MOCK_OPENSSL_SCENARIO:-}" = "many-groups" ]; then
  echo '* 100 EXISTS'
  for i in $(seq 1 100); do
    echo "* $i FETCH (UID $i RFC822.SIZE 1024 BODY[HEADER.FIELDS (FROM SUBJECT)] {80}"
    echo "From: Sender $i <sender$i@example.com>"
    echo "Subject: Topic $i"
    echo ')'
  done
  echo 'a OK SELECT completed'
  exit 0
fi

cat <<'EOF'
* 8 EXISTS
* 1 FETCH (UID 101 RFC822.SIZE 10485760 BODY[HEADER.FIELDS (FROM SUBJECT)] {112}
From: "Alice via groups.io" <alice=gmail.com@groups.io>
Subject: [Triangle Therapists] Office sublet with photos
)
* 2 FETCH (UID 102 RFC822.SIZE 5242880 BODY[HEADER.FIELDS (FROM SUBJECT)] {110}
From: "Bob via groups.io" <bob=gmail.com@groups.io>
Subject: Re: [Triangle Therapists] Another office listing
)
* 3 FETCH (UID 103 RFC822.SIZE 1048576 BODY[HEADER.FIELDS (FROM SUBJECT)] {112}
From: "Carol via groups.io" <carol=gmail.com@groups.io>
Subject: Fwd: Re: [Triangle Therapists] Forwarded listing
)
* 4 FETCH (UID 104 RFC822.SIZE 204800 BODY[HEADER.FIELDS (FROM SUBJECT)] {88}
From: Agent <agent@ricon.family>
Subject: Session: Morning report
)
* 5 FETCH (UID 105 RFC822.SIZE 102400 BODY[HEADER.FIELDS (FROM SUBJECT)] {88}
From: Agent <agent@ricon.family>
Subject: session: Evening report
)
* 6 FETCH (UID 106 RFC822.SIZE 307200 BODY[HEADER.FIELDS (FROM SUBJECT)] {84}
From: GitHub <notifications@github.com>
Subject: FW: [GitHub] Review requested
)
* 7 FETCH (UID 107 RFC822.SIZE 204800 BODY[HEADER.FIELDS (FROM SUBJECT)] {83}
From: Mercury <notifications@mercury.com>
Subject: Invite reminder
)
* 8 FETCH (UID 108 RFC822.SIZE 102400 BODY[HEADER.FIELDS (FROM SUBJECT)] {86}
From: Melissa Cramer <melissa@growheallove.com>
Subject: Website feedback
)
a OK SELECT completed
EOF
MOCK
  chmod +x "$MOCK_BIN/openssl"
  export PATH="$MOCK_BIN:$PATH"
}

@test "sizes: shows largest messages by default" {
  run emails sizes -f INBOX --top 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"INBOX:"* ]]
  [[ "$output" == *"#101"* ]]
  [[ "$output" == *"10MB"* ]]
  [[ "$output" == *"#102"* ]]
  [[ "$output" != *"[Triangle Therapists]"* ]]
}

@test "sizes: all-folder default works under set -u" {
  run emails sizes
  [ "$status" -eq 0 ]
  [[ "$output" == *"INBOX:"* ]]
  [[ "$output" == *"Sent:"* ]]
  [[ "$output" == *"Trash:"* ]]
  [[ "$output" == *"Archive:"* ]]
}

@test "sizes: can group by subject prefix" {
  run emails sizes -f INBOX --group-by subject-prefix --top 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"16MB"* ]]
  [[ "$output" == *"   3  [Triangle Therapists]"* ]]
  [[ "$output" == *"[GitHub]"* ]]
  [[ "$output" != *"Re:"* ]]
  [[ "$output" != *"Fwd:"* ]]
}

@test "sizes: normalizes subject-prefix case without changing display spelling" {
  run emails sizes -f INBOX --group-by subject-prefix --top 5
  [ "$status" -eq 0 ]
  [[ "$output" == *"   2  Session:"* ]]
  [[ "$output" != *"session:"* ]]
}

@test "sizes: can group by sender" {
  run emails sizes -f INBOX --group-by sender --top 4
  [ "$status" -eq 0 ]
  [[ "$output" == *"alice=gmail.com@groups.io"* ]]
  [[ "$output" == *"bob=gmail.com@groups.io"* ]]
  [[ "$output" == *"agent@ricon.family"* ]]
}

@test "sizes: truncates grouped output without BrokenPipeError" {
  MOCK_OPENSSL_SCENARIO=many-groups run emails sizes -f INBOX --group-by sender --top 3
  [ "$status" -eq 0 ]
  [[ "$output" != *"BrokenPipeError"* ]]
  [ "$(printf '%s\n' "$output" | grep -c '^           └')" -eq 3 ]
}

@test "sizes: rejects unsupported group fields" {
  run emails sizes -f INBOX --group-by domain
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported --group-by 'domain'"* ]]
}
