# emails

Email tooling for agents. Wraps [himalaya](https://github.com/pimalaya/himalaya) with agent identity, GPG signing, and quota management.

## Install

```bash
shiv install KnickKnackLabs/emails
```

## Commands

| Command | Description |
|---------|-------------|
| `emails send` | Send a GPG-signed email (supports `--html`) |
| `emails read` | Read a message (with GPG signature verification) |
| `emails list` | List messages (with unread filter, pagination) |
| `emails reply` | Reply to a message (supports `--html`) |
| `emails delete` | Delete message(s) (move to Trash or `--permanent`) |
| `emails archive` | Move message(s) to Archive |
| `emails wait` | Wait for new email to arrive (polling) |
| `emails inspect` | Show MIME structure and metadata |
| `emails export` | Export messages to a directory |
| `emails purge` | Permanently delete all messages in a folder |
| `emails sizes` | Per-folder sizes and largest messages |
| `emails quota` | Storage quota usage |
| `emails status` | Check setup status for an agent |
| `emails setup` | One-time himalaya configuration |
| `emails welcome` | Overview and current status |

## HTML Email

Send and reply support `--html` for HTML content:

```bash
# Send HTML email
emails send user@example.com "Subject" --html -b /path/to/email.html

# Pipe HTML
cat email.html | emails send user@example.com "Subject" --html

# Reply with HTML
emails reply 42 --html -b '<h1>Thanks!</h1><p>Got it.</p>'
```

## Setup

Requires:
- [himalaya](https://github.com/pimalaya/himalaya) — IMAP/SMTP client
- GPG key configured for the agent
- Agent identity set via `shimmer as <agent>` (sets `GIT_AUTHOR_EMAIL`)

First-time setup:
```bash
emails setup <agent-name>
```

This creates `~/.config/himalaya/config.toml` with IMAP/SMTP credentials pulled from `secrets`.

## Architecture

Extracted from `shimmer email:*` tasks ([shimmer#707](https://github.com/KnickKnackLabs/shimmer/issues/707)). Follows the same pattern as `chat`, `notes`, `sessions` — tool-per-concern, shiv-installable.

All tasks use `lib/email.sh` for shared agent identity detection and himalaya config validation.
