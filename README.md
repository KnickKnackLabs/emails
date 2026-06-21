<div align="center">

<img src="assets/emails-logo.gif" alt="emails logo" width="360">

# emails

**Email accounts, not agent identity.**

`emails` is a small account/persona layer around [himalaya](https://github.com/pimalaya/himalaya). It knows mail config, account names, servers, defaults, and signing policy. It does not know who launched it.

![shell: bash](https://img.shields.io/badge/shell-bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
[![runtime: mise](https://img.shields.io/badge/runtime-mise-7c3aed?style=flat)](https://mise.jdx.dev)
![commands: 23](https://img.shields.io/badge/commands-23-blue?style=flat)
[![tests: 127 passing](https://img.shields.io/badge/tests-127%20passing-brightgreen?style=flat)](test/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=flat)](LICENSE)

</div>

## The shape

```
config file
  EMAILS_CONFIG
  HIMALAYA_CONFIG
  .emails/himalaya.toml       # found by walking upward from $PWD
  ~/.config/emails/himalaya.toml
        │
        ▼
accounts / personas
  [accounts.personal]  [accounts.kkl]  [accounts.client]
        │                    │                  │
        │ default?           │ gpg policy?      │ downloads dir?
        ▼                    ▼                  ▼
read / list / send / reply through exactly one selected account
```

The key design decision is the boundary: account selection belongs to mail config, not to agent process state. That makes the same checkout usable for a person, an agent, a repo-local client persona, or a one-off operations mailbox without teaching the tool about any of those identities.

## What it knows

| emails knows                        | emails does not know                                            |
| ----------------------------------- | --------------------------------------------------------------- |
| Config paths                        | `AGENT_HOME`, chat identity, or workspace owner                 |
| Account names and email addresses   | Git author, GPG signing identity for commits, or org membership |
| IMAP/SMTP hosts and ports           | Where your password came from                                   |
| Optional default account            | Which account you "probably meant" when config is ambiguous     |
| Per-account GPG mail signing policy | Global rules like "all agents sign" or "all company mail signs" |

## Install

```bash
shiv install emails
```

Set up an explicit account. Passwords come from stdin, so your secret manager stays outside the tool.

```bash
# Optional: keep this repo/home on its own mail config.
export EMAILS_CONFIG="$PWD/.emails/himalaya.toml"

your-secret-manager read mail/personal/password \
  | emails account setup personal \
      --address you@example.com \
      --display-name "Your Name" \
      --imap-host imap.example.com \
      --smtp-host smtp.example.com \
      --password-stdin
```

If the config lives in a directory named `.emails`, setup also writes a protective `.gitignore` so the local password-bearing config is not accidentally committed.

## Two personas, no guessing

Multiple accounts are fine. Ambiguous sending is not.

```bash
# Add a second persona to the same config.
your-secret-manager read mail/work/password \
  | emails account setup work \
      --address you@company.com \
      --imap-host imap.company.com \
      --smtp-host smtp.company.com \
      --password-stdin

emails account list

# Be explicit when there is no default.
emails send --account personal --to friend@example.com --subject "Lunch" -b lunch.txt
emails send --account work --to client@example.com --subject "Update" -b update.html --html

# Or choose a default for this config.
emails account default work
emails account default --clear
```

| Situation                      | Result          | Why                                                        |
| ------------------------------ | --------------- | ---------------------------------------------------------- |
| One account                    | Use it          | A single configured persona is unambiguous.                |
| `--account work`               | Use `work`      | Explicit command flags beat defaults.                      |
| Multiple accounts, one default | Use the default | The config says which persona is normal here.              |
| Multiple accounts, no default  | Fail            | The tool asks for `--account` or `emails account default`. |
| Two defaults                   | Fail            | A broken config is safer than a guessed sender.            |

## Signing belongs to the account

Mail signing is opt-in per persona. Configure it on the account that should sign mail; override per send only when you mean it.

```bash
emails account gpg enable work --local-user you@company.com
emails account gpg status work

# Require signing for one message. Fails if the selected account cannot sign.
emails send --account work --sign --to client@example.com --subject "Signed update" -b update.txt

# Suppress account-default signing for one message.
emails send --account work --no-sign --to robot@example.com --subject "Unsigned log" -b log.txt
```

| Account policy     | Send mode   | Outcome                    |
| ------------------ | ----------- | -------------------------- |
| Account has no GPG | plain send  | Unsigned                   |
| Account has no GPG | `--sign`    | Fail; enable signing first |
| Account has GPG    | plain send  | Signed by account policy   |
| Account has GPG    | `--no-sign` | Unsigned for this send     |

## Everyday mail

```bash
emails welcome                    # current config, folders, recent messages
emails list                       # inbox table
emails read 42                    # message body, headers, signature status
emails reply 42 -b reply.txt      # reply through the selected account
emails quota                      # storage quota
emails sizes                      # largest folders/messages
emails wait                       # block until new mail arrives
```

Send accepts inline text, a body file, stdin, or a JSON envelope. Prefer explicit flags in scripts.

```bash
emails send --to user@example.com --subject "Plain update" -b body.txt
cat body.html | emails send --account work --to client@example.com --subject "HTML update" --html
emails send --file email.json
emails send --to user@example.com --subject "With attachment" -b body.txt --attach report.pdf
```

## Safety rails

- Passwords arrive through explicit stdin from the caller's chosen secret manager.
- Ambiguous multi-account configs fail with the command to fix them.
- Bodies under 50 characters require `--allow-short`.
- If a positional subject looks like an email address, send stops and points to `--cc`.
- Account GPG policy decides default mail signing.

## Core command surface

The README shows workflows, not a full command catalog. Use `emails <command> --help` for exact flags. The central commands are:

| Command                     | Purpose                                                         |
| --------------------------- | --------------------------------------------------------------- |
| `emails account setup`      | Setup an explicit email account in the selected Himalaya config |
| `emails account list`       | List configured email accounts                                  |
| `emails account default`    | Set or clear the default email account                          |
| `emails account gpg enable` | Enable GPG signing for an email account                         |
| `emails list`               | List email messages                                             |
| `emails read`               | Read an email message                                           |
| `emails send`               | Send an email                                                   |
| `emails reply`              | Reply to an email message                                       |

## Testing

127 tests across two suites:

- **Unit tests (92)** — mock himalaya and test task logic in isolation
- **Integration tests (35)** — real himalaya against a local maildir backend, full round-trip, no network

```bash
mise run test
mise run test-integration
mise exec -- readme build --check
```

## Development

```bash
git clone https://github.com/KnickKnackLabs/emails.git
cd emails
mise trust && mise install
mise run test
```

Requires [himalaya](https://github.com/pimalaya/himalaya). For generated docs, edit `README.tsx` and run `mise exec -- readme build`.

<br />

<div align="center">

---

<sub>
Generated from [README.tsx](https://github.com/KnickKnackLabs/readme). Mail is a persona; choose it deliberately.
</sub></div>
