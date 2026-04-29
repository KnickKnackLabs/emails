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
cat <<'EOF'
* 4 EXISTS
* 1 FETCH (UID 101 RFC822.SIZE 10485760 BODY[HEADER.FIELDS (FROM SUBJECT)] {112}
From: "Alice via groups.io" <alice=gmail.com@groups.io>
Subject: [Triangle Therapists] Office sublet with photos
)
* 2 FETCH (UID 102 RFC822.SIZE 5242880 BODY[HEADER.FIELDS (FROM SUBJECT)] {106}
From: "Bob via groups.io" <bob=gmail.com@groups.io>
Subject: [Triangle Therapists] Another office listing
)
* 3 FETCH (UID 103 RFC822.SIZE 102400 BODY[HEADER.FIELDS (FROM SUBJECT)] {86}
From: Melissa Cramer <melissa@growheallove.com>
Subject: Website feedback
)
* 4 FETCH (UID 104 RFC822.SIZE 204800 BODY[HEADER.FIELDS (FROM SUBJECT)] {83}
From: Mercury <notifications@mercury.com>
Subject: Invite reminder
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

@test "sizes: can group by subject prefix" {
  run emails sizes -f INBOX --group-by subject-prefix --top 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"15MB"* ]]
  [[ "$output" == *"   2  [Triangle Therapists]"* ]]
  [[ "$output" == *"Invite reminder"* ]]
}

@test "sizes: can group by sender" {
  run emails sizes -f INBOX --group-by sender --top 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"alice=gmail.com@groups.io"* ]]
  [[ "$output" == *"bob=gmail.com@groups.io"* ]]
  [[ "$output" == *"notifications@mercury.com"* ]]
}

@test "sizes: rejects unsupported group fields" {
  run emails sizes -f INBOX --group-by domain
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported --group-by 'domain'"* ]]
}
