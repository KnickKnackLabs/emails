# Integration test helpers for emails
#
# Uses himalaya's maildir backend + sendmail for a fully local test environment.
# No network daemons needed — all I/O is filesystem-based.
#
# Provides:
#   - setup_maildir()     — creates maildir folders + himalaya config + fake sendmail
#   - deposit_message()   — drops a raw message into a maildir folder
#   - emails()            — runs emails tasks via mise with test config
#   - MAILDIR_ROOT        — path to the test maildir

if [ -z "${REPO_DIR:-}" ]; then
  REPO_DIR="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  export REPO_DIR
fi

emails() {
  cd "$REPO_DIR" && mise run -q "$@"
}
export -f emails

# Create a maildir test environment matching our mxroute folder structure.
# Sets: MAILDIR_ROOT, HIMALAYA_CONFIG, AGENT, GIT_AUTHOR_EMAIL, FAKE_SENDMAIL_MAILDIR
setup_maildir() {
  export MAILDIR_ROOT="$BATS_TEST_TMPDIR/maildir"
  export AGENT="test-agent"
  export GIT_AUTHOR_EMAIL="test-agent@ricon.family"

  # Create maildir folder structure (INBOX, Sent, Trash, Archive)
  for folder in INBOX Sent Trash Archive Drafts; do
    mkdir -p "$MAILDIR_ROOT/$folder"/{cur,new,tmp}
  done

  # Fake sendmail: deposits messages into INBOX/new (simulates delivery)
  local sendmail="$BATS_TEST_TMPDIR/fake-sendmail.sh"
  cat > "$sendmail" << 'SCRIPT'
#!/usr/bin/env bash
DEST="$FAKE_SENDMAIL_MAILDIR/INBOX/new/$(date +%s).${RANDOM}.$$:2,"
cat > "$DEST"
SCRIPT
  chmod +x "$sendmail"
  export FAKE_SENDMAIL_MAILDIR="$MAILDIR_ROOT"

  # Himalaya config: maildir backend + sendmail for sending
  export HIMALAYA_CONFIG="$BATS_TEST_TMPDIR/himalaya-config.toml"
  cat > "$HIMALAYA_CONFIG" << EOF
[accounts.test-agent]
default = true
email = "test-agent@ricon.family"
display-name = "Test Agent"

backend.type = "maildir"
backend.root-dir = "$MAILDIR_ROOT"

message.send.backend.type = "sendmail"
message.send.backend.cmd = "$sendmail"

pgp.type = "commands"
pgp.sign-cmd = "gpg --sign --quiet --armor"
pgp.decrypt-cmd = "gpg --decrypt --quiet"
pgp.verify-cmd = "gpg --verify --quiet"
EOF

  # Agent workspace for attachment downloads
  mkdir -p "$HOME/agents/test-agent/downloads"
}

# Deposit a raw email into a maildir folder.
# Usage: deposit_message [--folder FOLDER] [--from FROM] [--subject SUBJECT] [--body BODY]
# Defaults: folder=INBOX, from=sender@example.com, subject=Test, body=...
deposit_message() {
  local folder="INBOX"
  local from="sender@example.com"
  local to="test-agent@ricon.family"
  local subject="Test message"
  local body="This is a test message with sufficient body content for testing purposes."
  local message_id=""
  local date=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --folder)  folder="$2"; shift 2 ;;
      --from)    from="$2"; shift 2 ;;
      --to)      to="$2"; shift 2 ;;
      --subject) subject="$2"; shift 2 ;;
      --body)    body="$2"; shift 2 ;;
      --message-id) message_id="$2"; shift 2 ;;
      --date)    date="$2"; shift 2 ;;
      *) echo "Unknown arg: $1" >&2; return 1 ;;
    esac
  done

  [ -z "$message_id" ] && message_id="<$(date +%s).$RANDOM@test>"
  [ -z "$date" ] && date="$(date -R 2>/dev/null || date '+%a, %d %b %Y %H:%M:%S %z')"

  local filename
  filename="$(date +%s).${RANDOM}.$$:2,"

  cat > "$MAILDIR_ROOT/$folder/new/$filename" << EOF
From: $from
To: $to
Subject: $subject
Date: $date
Message-ID: $message_id
MIME-Version: 1.0
Content-Type: text/plain; charset=utf-8

$body
EOF

  # Return the filename for reference
  echo "$filename"
}

# Count messages in a maildir folder (cur + new)
maildir_count() {
  local folder="${1:-INBOX}"
  local count=0
  count=$(find "$MAILDIR_ROOT/$folder/cur" "$MAILDIR_ROOT/$folder/new" -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "$count"
}

# Create a mock gpg binary that returns canned output.
# Write the desired gpg stderr output to $GPG_MOCK_RESPONSE_FILE before calling emails read.
# If $GPG_MOCK_RESPONSE_FILE is absent or empty, the mock exits 2 (no OpenPGP data).
setup_mock_gpg() {
  local mock_bin="$BATS_TEST_TMPDIR/mock-bin"
  mkdir -p "$mock_bin"
  export GPG_MOCK_RESPONSE_FILE="$BATS_TEST_TMPDIR/gpg-mock-response"
  cat > "$mock_bin/gpg" << 'MOCK'
#!/usr/bin/env bash
if [ -f "$GPG_MOCK_RESPONSE_FILE" ] && [ -s "$GPG_MOCK_RESPONSE_FILE" ]; then
  cat "$GPG_MOCK_RESPONSE_FILE" >&2
  exit 0
fi
echo "gpg: no valid OpenPGP data found" >&2
exit 2
MOCK
  chmod +x "$mock_bin/gpg"
  export PATH="$mock_bin:$PATH"
}

# Get the envelope ID of the most recent message via himalaya
latest_envelope_id() {
  local folder="${1:-INBOX}"
  himalaya -c "$HIMALAYA_CONFIG" envelope list -a "$AGENT" -f "$folder" --page-size 1 2>/dev/null \
    | tail -n +4 | head -1 | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}'
}
