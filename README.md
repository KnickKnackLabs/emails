# email

A mise-based CLI for Outlook/Microsoft 365 email via the MS Graph API. Pure bash + curl + jq.

## Setup

```bash
# 1. Clone and trust
git clone https://gecgithub01.walmart.com/vn5a6e7/email.git
cd email && mise trust && mise install

# 2. Install the shim (requires https://github.com/KnickKnackLabs/shiv)
shiv install email /path/to/email

# 3. Authenticate (requires Wibey's msgraph skill — see issue #1)
email login
```

## Commands

```
email inbox              List inbox (--limit N, --unread, --json)
email read <n>           Read message by number or ID (--html, --json)
email send               Send (--to, --subject, --body, --cc, --confirm)
email reply <n>          Reply (--body, --all, --confirm)
email archive <n>        Move to Archive (comma-separated for bulk)
email delete <n>         Move to Deleted Items (comma-separated for bulk)
email search <query>     Search (--limit N, --json)
email folders            List folders with unread counts (--json)
email status             Check auth status (--json)
email login              Authenticate (opens browser)
email logout             Clear stored tokens
```

## How it works

Auth tokens live at `~/.config/email/tokens.json`. The initial login uses Wibey's Playwright-based OAuth flow (Graph Explorer's public client ID with PKCE). After that, token refresh is pure curl — no browser needed.

All Graph API calls go through `lib/graph.sh`, which handles token refresh, request construction, and output helpers.
