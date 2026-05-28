#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  load ../integration-helpers
  setup_maildir
}

@test "send: delivers message to recipient inbox" {
  emails send test-agent@ricon.family "Integration test" \
    "This is a test message sent through the integration test suite for validation." \
    --allow-short

  # Message should appear in INBOX (delivered by fake sendmail)
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"Integration test"* ]]
}

@test "send: saves copy to Sent folder" {
  emails send test-agent@ricon.family "Sent copy test" \
    "Verifying that a copy of the sent message appears in the Sent folder automatically."

  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" -f Sent --page-size 100 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"Sent copy test"* ]]
}

@test "send: GPG-signs messages" {
  emails send test-agent@ricon.family "Signed message test" \
    "This message should be GPG-signed automatically by the send task in the emails package."

  # GPG-signed messages show @ flag (signature is a MIME attachment)
  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" -f Sent --page-size 100 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"@"* ]]
}

@test "send: rejects empty body" {
  run emails send test-agent@ricon.family "Empty body test" </dev/null
  [ "$status" -ne 0 ]
}

@test "send: rejects short body without --allow-short" {
  run emails send test-agent@ricon.family "Short body test" "too short"
  [ "$status" -ne 0 ]
  [[ "$output" == *"too short"* ]]
}

@test "send: accepts short body with --allow-short" {
  run emails send test-agent@ricon.family "Short allowed" "short body" --allow-short
  [ "$status" -eq 0 ]
  [[ "$output" == *"Sent to"* ]]
}

@test "send: reads body from stdin" {
  echo "This is a message body piped through stdin for the integration test suite to verify." \
    | emails send test-agent@ricon.family "Stdin test"

  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"Stdin test"* ]]
}

@test "send: reads body from file via -b flag" {
  local bodyfile="$BATS_TEST_TMPDIR/body.txt"
  echo "This is the message body loaded from a file path passed via the -b flag for testing." > "$bodyfile"

  emails send test-agent@ricon.family "File body test" -b "$bodyfile"

  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"File body test"* ]]
}

@test "send: html flag sends as html content type" {
  local htmlfile="$BATS_TEST_TMPDIR/email.html"
  cat > "$htmlfile" << 'HTML'
<html><body><h1>Hello</h1><p>This is an HTML email sent through the integration test suite.</p></body></html>
HTML

  emails send test-agent@ricon.family "HTML test" --html -b "$htmlfile"

  # Verify the raw message in Sent has text/html
  local sent_msg
  sent_msg=$(find "$MAILDIR_ROOT/Sent" -type f | head -1)
  run cat "$sent_msg"
  [[ "$output" == *"text/html"* ]]
}

@test "send: cc flag adds Cc header" {
  emails send test-agent@ricon.family "CC test" \
    "This message tests that the CC flag adds a proper Cc header to the sent email." \
    -c alice@example.com -c bob@example.com

  local sent_msg
  sent_msg=$(find "$MAILDIR_ROOT/Sent" -type f | head -1)
  run cat "$sent_msg"
  [[ "$output" == *"Cc:"* ]]
  [[ "$output" == *"alice@example.com"* ]]
  [[ "$output" == *"bob@example.com"* ]]
}

@test "send: --to and --subject flags deliver message" {
  local body_file="$BATS_TEST_TMPDIR/body.txt"
  echo "This message uses explicit --to and --subject flags instead of positional arguments for safety." > "$body_file"

  emails send \
    --to test-agent@ricon.family \
    --subject "Explicit flags integration test" \
    -b "$body_file"

  run himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" --page-size 100 2>/dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"Explicit flags integration test"* ]]
}

@test "send: rejects two recipient-looking positional args (GHL shape)" {
  run emails send alice@example.com candi@example.com \
    "This body is long enough but should never be sent because the subject is an email."
  [ "$status" -ne 0 ]
  [[ "$output" == *"subject looks like an email address"* ]]
}

@test "send: --file JSON delivers message with correct headers" {
  local spec="$BATS_TEST_TMPDIR/email.json"
  cat > "$spec" <<'JSON'
{
  "to": "test-agent@ricon.family",
  "subject": "File spec integration test",
  "body": "This message was composed from a JSON file spec to test the structured input path end to end.",
  "cc": ["cc-recipient@example.com"]
}
JSON

  emails send --file "$spec"

  local sent_msg
  sent_msg=$(find "$MAILDIR_ROOT/Sent" -type f | head -1)
  run cat "$sent_msg"
  [[ "$output" == *"File spec integration test"* ]]
  [[ "$output" == *"cc-recipient@example.com"* ]]
}
