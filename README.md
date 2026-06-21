<div align="center">

# emails

**Email tooling for local accounts and personas.**

Wraps [himalaya](https://github.com/pimalaya/himalaya) with account setup, optional GPG signing, and quota management.

![shell: bash](https://img.shields.io/badge/shell-bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![runtime: mise](https://img.shields.io/badge/runtime-mise-7c3aed?style=flat)](https://mise.jdx.dev)
![commands: 23](https://img.shields.io/badge/commands-23-blue?style=flat)
[![tests: 127 passing](https://img.shields.io/badge/tests-127%20passing-brightgreen?style=flat)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

## Install

```bash
shiv install emails
```

First-time setup creates an explicit account in a Himalaya config. Provide the password via stdin; compose with your secret manager outside emails.

```bash
# Optional: choose a repo- or home-local config file
export EMAILS_CONFIG="$PWD/.emails/himalaya.toml"

# Setup one account without making it default
password-manager get mail/personal/password \
  | emails account setup personal \
      --address you@example.com \
      --imap-host imap.example.com \
      --smtp-host smtp.example.com \
      --password-stdin

# Setup a default account with signing enabled
password-manager get mail/work/password \
  | emails account setup work \
      --address you@company.com \
      --imap-host imap.company.com \
      --smtp-host smtp.company.com \
      --password-stdin \
      --set-default \
      --gpg-local-user you@company.com
```

## Quick start

```bash
# Check inbox
emails list

# Read a message
emails read <id>

# Send an email
emails send user@example.com "Subject" "Message body here."

# Use a specific account/persona
emails send --account work user@example.com "Subject" "Message body here."

# Reply to a message
emails reply <id> "Thanks, got it."

# Overview and status
emails welcome
```

## Commands

| Command                      | Description                                                     |
| ---------------------------- | --------------------------------------------------------------- |
| `emails account:default`     | Set or clear the default email account                          |
| `emails account:gpg:disable` | Disable GPG signing for an email account                        |
| `emails account:gpg:enable`  | Enable GPG signing for an email account                         |
| `emails account:gpg:status`  | Show GPG signing status for an email account                    |
| `emails account:list`        | List configured email accounts                                  |
| `emails account:setup`       | Setup an explicit email account in the selected Himalaya config |
| `emails account:show`        | Show one configured email account                               |
| `emails archive`             | Archive email message(s)                                        |
| `emails compose`             | Compose an email from a TSX file                                |
| `emails delete`              | Delete email message(s) (moves to Trash)                        |
| `emails export`              | Export emails to a directory                                    |
| `emails inspect`             | Inspect email message structure and metadata                    |
| `emails list`                | List email messages                                             |
| `emails purge`               | Permanently delete all messages in a folder                     |
| `emails quota`               | Show email storage quota usage                                  |
| `emails read`                | Read an email message                                           |
| `emails reply`               | Reply to an email message                                       |
| `emails send`                | Send an email                                                   |
| `emails setup`               | Deprecated: use emails account setup                            |
| `emails sizes`               | Show per-folder email sizes and largest messages                |
| `emails status`              | Check email account setup status                                |
| `emails wait`                | Wait for new email to arrive                                    |
| `emails welcome`             | Email intro and current status                                  |

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

Signing is an explicit account policy. Accounts with `--gpg-local-user` configured sign by default; unsigned accounts send unsigned by default. Use `--sign` to require signing for one send, or `--no-sign` to suppress account-default signing.

```bash
emails account gpg enable work --local-user you@company.com
emails account gpg status work
emails account gpg disable work
```

Incoming messages show signature status when read:

```
From: signed@example.com (✓ Signed by Person <signed@example.com>)
From: unknown@example.com (⚠ Unsigned)
From: imposter@example.com (✗ Bad signature)
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
