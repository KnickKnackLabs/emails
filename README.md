<div align="center">

# email

**CLI for Outlook / Microsoft 365 email.**

Pure bash + curl + jq — no Node, no Python, no SDK. Read, send, search, and organize mail from the terminal.

</div>

---

## Quick Start

```bash
# Clone and install
git clone https://gecgithub01.walmart.com/vn5a6e7/email.git
cd email && mise trust && mise install

# Login (opens browser for Microsoft OAuth)
mise run login

# Check your inbox
mise run inbox
```

### Using with shiv

If you have [shiv](https://github.com/KnickKnackLabs/shiv) installed, register as a global command:

```bash
shiv install email /path/to/email

# Then use from anywhere:
email inbox
email read 1
email send --to someone@walmart.com --subject "Hello" --body "Hi there"
```

## Commands

| Command | Description |
| --- | --- |
| `email welcome` | Quick inbox overview — unread count + 5 most recent messages |
| `email inbox` | Full inbox listing (with --limit, --unread) |
| `email read <n>` | Read a message by inbox number (with --html, --json) |
| `email send` | Compose and send (with --to, --subject, --body, --cc, --confirm) |
| `email reply <n>` | Reply to a message (with --all for reply-all) |
| `email search <query>` | Search across all mail |
| `email archive <n>` | Move message(s) to Archive |
| `email delete <n>` | Move message(s) to Deleted Items |
| `email attachments` | List attachments on a message |
| `email download` | Download attachments |
| `email folders` | List mail folders with unread counts |
| `email status` | Check auth status |
| `email login` | Authenticate (opens browser) |
| `email logout` | Clear stored tokens |

## Examples

**Reading mail:**

```bash
email welcome                   # quick overview (great for session start)
email inbox --limit 50          # show more messages
email inbox --unread            # only unread
email read 1                    # read by inbox number
email read 1 --html             # raw HTML view
```

**Sending mail:**

```bash
email send --to user@walmart.com --subject "Subject" --body "Message"
email send --to user@walmart.com --cc other@walmart.com --subject "FYI" --body "..."
email send --to user@walmart.com --subject "Auto" --body "..." --confirm  # skip prompt
email reply 3 --body "Thanks!"
email reply 3 --body "Thanks!" --all    # reply all
```

**Organizing:**

```bash
email archive 5
email delete 1,2,3 --confirm    # bulk delete
email search "from:brian subject:release"
```

**JSON output** — every command supports `--json` for machine-readable output:

```bash
email inbox --json | jq '.[0].subject'
```

## Authentication

Login uses Microsoft's OAuth2 PKCE flow via a browser redirect. Tokens are stored at `~/.config/email/tokens.json` and auto-refresh on each command.

**Known limitation:** The current app registration uses an SPA client type, which Microsoft limits to 24-hour refresh token lifetime. You'll need to run `email login` once per day.

## For Agents

If you're an AI agent setting up email for your human:

- Clone the repo and run `mise trust && mise install`
- Run `mise run login` — this opens a browser. Tell your human: "Please sign in with your Walmart credentials."
- Verify with `mise run welcome`
- Tokens expire every 24 hours. When refresh fails, ask your human to run `email login` again.

## Structure

```text
email/
├── .mise/tasks/
│   ├── inbox        # List messages
│   ├── read         # Read a message
│   ├── send         # Compose and send
│   ├── reply        # Reply / reply-all
│   ├── search       # Full-text search
│   ├── archive      # Move to Archive
│   ├── delete       # Move to Deleted Items
│   ├── attachments  # List attachments
│   ├── download     # Download attachments
│   ├── folders      # List mail folders
│   ├── welcome      # Inbox overview
│   ├── status       # Auth status check
│   ├── login        # OAuth flow
│   └── logout       # Clear tokens
├── lib/
│   └── graph.sh     # MS Graph API client (token mgmt, HTTP helpers)
├── mise.toml
└── README.tsx       # This file (generates README.md)
```

## Requirements

- [mise](https://mise.jdx.dev/) — task runner and tool manager
- `curl` — HTTP requests
- `jq` — JSON processing
- A browser — for the initial OAuth login
