<div align="center">

# emails

**Email tooling for agents.**

Wraps [himalaya](https://github.com/pimalaya/himalaya) with agent identity, GPG signing, and quota management.

![shell: bash](https://img.shields.io/badge/shell-bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![runtime: mise](https://img.shields.io/badge/runtime-mise-7c3aed?style=flat)](https://mise.jdx.dev)
![commands: 16](https://img.shields.io/badge/commands-16-blue?style=flat)
[![tests: 127 passing](https://img.shields.io/badge/tests-127%20passing-brightgreen?style=flat)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

## Install

```bash
shiv install emails
```

First-time setup for an agent. Provide the password explicitly via environment or stdin; compose with your secret manager outside emails.

```bash
# Environment variable
EMAIL_PASSWORD="..." emails setup <agent-name>

# Or stdin, usually from a password manager command
password-manager get <agent-name>/email-password | emails setup <agent-name> --password-stdin
```

## Quick start

```bash
# Check inbox
emails list

# Read a message
emails read <id>

# Send a GPG-signed email
emails send user@example.com "Subject" "Message body here."

# Reply to a message
emails reply <id> "Thanks, got it."

# Overview and status
emails welcome
```

## Commands

| Command          | Description                                                |
| ---------------- | ---------------------------------------------------------- |
| `emails archive` | Archive email message(s)                                   |
| `emails compose` | Compose an email from a TSX file                           |
| `emails delete`  | Delete email message(s) (moves to Trash)                   |
| `emails export`  | Export emails to a directory                               |
| `emails inspect` | Inspect email message structure and metadata               |
| `emails list`    | List email messages                                        |
| `emails purge`   | Permanently delete all messages in a folder                |
| `emails quota`   | Show email storage quota usage                             |
| `emails read`    | Read an email message                                      |
| `emails reply`   | Reply to an email message                                  |
| `emails send`    | Send a GPG-signed email                                    |
| `emails setup`   | Setup email (himalaya) for an agent (one-time local setup) |
| `emails sizes`   | Show per-folder email sizes and largest messages           |
| `emails status`  | Check email (himalaya) setup status for an agent           |
| `emails wait`    | Wait for new email to arrive                               |
| `emails welcome` | Email intro and current status                             |

## HTML email

Send and reply support `--html` for HTML content:

```bash
# Send HTML email
emails send user@example.com "Subject" --html -b /path/to/email.html

# Pipe HTML
cat email.html | emails send user@example.com "Subject" --html

# Reply with HTML
emails reply 42 --html -b '<h1>Thanks!</h1><p>Got it.</p>'
```

## GPG signing

All outgoing messages are GPG-signed automatically using the exact account email key. This provides a unified cryptographic identity — the same key signs git commits and emails, and a missing exact key fails instead of falling back to another agent's key.

Incoming messages show signature status when read:

```
From: brownie@ricon.family (✓ Signed by brownie <brownie@ricon.family>)
From: unknown@example.com (⚠ Unsigned)
From: imposter@ricon.family (✗ Bad signature)
```

## Body input

Messages accept body content three ways:

```bash
# Positional argument
emails send user@example.com "Subject" "Inline body text."

# Flag (or file path)
emails send user@example.com "Subject" -b "Flag body text."
emails send user@example.com "Subject" -b /path/to/body.txt

# Stdin
echo "Piped body." | emails send user@example.com "Subject"
```

A minimum body length of 50 characters guards against accidental sends. Override with `--allow-short`.

## Testing

127 tests across two suites:

- **Unit tests (92)** — mock himalaya, test task logic in isolation
- **Integration tests (35)** — real himalaya against a local maildir backend, full round-trip

```bash
mise run test              # unit tests
mise run test-integration  # integration tests (maildir-backed, no network)
```

## Development

```bash
git clone https://github.com/KnickKnackLabs/emails.git
cd emails && mise trust && mise install
mise run test
```

Requires [himalaya](https://github.com/pimalaya/himalaya) and a GPG key configured for the agent.

<br />

<div align="center">

---

<sub>
This README was generated from [README.tsx](https://github.com/KnickKnackLabs/readme).
</sub></div>
