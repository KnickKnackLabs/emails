# email

A mise-based CLI for Outlook/Microsoft 365 email. Pure bash + curl + jq — no Node, no Python, no SDK.

## Quick Start

```bash
# 1. Clone
git clone https://gecgithub01.walmart.com/vn5a6e7/email.git
cd email

# 2. Trust and install dependencies
mise trust && mise install

# 3. Login (opens browser for Microsoft OAuth)
mise run login

# 4. Check your inbox
mise run inbox
```

### Using with shiv (optional)

If you have [shiv](https://github.com/KnickKnackLabs/shiv) installed, you can register `email` as a global command:

```bash
shiv install email /path/to/email

# Then use from anywhere:
email inbox
email read 1
email send --to someone@walmart.com --subject "Hello" --body "Hi there"
```

Without shiv, use `mise run <command>` from inside the repo directory.

## Commands

### Overview

| Command | Description |
|---------|-------------|
| `email welcome` | Quick inbox overview — unread count + 5 most recent messages |
| `email inbox` | Full inbox listing |
| `email read <n>` | Read a message by its inbox number |
| `email send` | Compose and send an email |
| `email reply <n>` | Reply to a message |
| `email search <query>` | Search across all mail |
| `email archive <n>` | Move message(s) to Archive |
| `email delete <n>` | Move message(s) to Deleted Items |
| `email folders` | List mail folders with unread counts |
| `email status` | Check auth status |
| `email login` | Authenticate (opens browser) |
| `email logout` | Clear stored tokens |

### Reading mail

```bash
# Quick overview (great for session start)
email welcome

# List inbox (default: 15 messages)
email inbox

# Show more messages
email inbox --limit 50

# Only unread
email inbox --unread

# Read a specific message (by inbox number)
email read 1

# Read as raw HTML
email read 1 --html
```

### Sending mail

```bash
# Send (will prompt for confirmation)
email send --to user@walmart.com --subject "Subject" --body "Message body"

# Send with CC
email send --to user@walmart.com --cc other@walmart.com --subject "Subject" --body "Body"

# Skip confirmation (for scripts/agents)
email send --to user@walmart.com --subject "Subject" --body "Body" --confirm

# Reply to message #3
email reply 3 --body "Thanks!"

# Reply all
email reply 3 --body "Thanks!" --all
```

### Organizing mail

```bash
# Delete a single message
email delete 5

# Bulk delete (comma-separated)
email delete 1,2,3 --confirm

# Archive
email archive 5
email archive 1,2,3 --confirm
```

### Search

```bash
email search "from:brian subject:release"
email search "okwai" --limit 20
```

### JSON output

Every command supports `--json` for machine-readable output:

```bash
email inbox --json
email read 1 --json
email folders --json
email status --json
```

## How It Works

### Authentication

Login uses Microsoft's OAuth2 PKCE flow via a browser redirect. Tokens are stored at `~/.config/email/tokens.json` and auto-refresh on each command.

**Known limitation:** The current app registration uses a Single-Page Application (SPA) client type, which Microsoft limits to 24-hour refresh token lifetime. You'll need to run `email login` once per day. See [issue #2](https://gecgithub01.walmart.com/vn5a6e7/email/issues/2) for the fix plan.

### Architecture

```
.mise/tasks/       # Each command is a standalone bash script
  inbox            # Uses #USAGE specs for argument parsing
  read
  send
  ...
lib/
  graph.sh         # Shared library: token management, Graph API calls, output helpers
```

All Microsoft Graph API calls go through `lib/graph.sh`, which handles:
- Token loading, expiry detection, and refresh
- HTTP request construction (`graph_get`, `graph_post`, `graph_patch`, `graph_delete`)
- Date formatting and text truncation helpers

### Requirements

- [mise](https://mise.jdx.dev/) — task runner and tool manager
- `curl` — HTTP requests
- `jq` — JSON processing
- A browser — for the initial OAuth login

All of these are available on standard Walmart dev machines.

## For Agents

If you're an AI agent setting up email for your human:

1. Clone the repo to your workspace or a standard location
2. Run `mise trust && mise install`
3. Run `mise run login` — this opens a browser. Your human needs to complete the Microsoft sign-in. Tell them: "Please sign in with your Walmart credentials in the browser window that just opened."
4. Once authenticated, verify with `mise run welcome`
5. Tokens expire every 24 hours. When you see "Token refresh failed", ask your human to run `email login` again.
