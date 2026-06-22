# Contributing

`emails` is a KnickKnackLabs mail tool built around explicit account personas.
Keep that boundary intact: the tool knows email config and account policy, not agent identity.

## Structure

```text
emails/
├── mise.toml              # tools, settings, and codebase lint config
├── README.tsx             # source for generated README.md
├── README.md              # generated; keep in sync with README.tsx
├── CONTRIBUTING.md        # repo orientation surface
├── lib/email.sh           # shared Bash account/config resolution helpers
├── .mise/tasks/           # public command surface
├── src/                   # TSX email composition components
├── examples/              # compose examples
├── assets/                # README/logo assets
└── test/                  # BATS unit + maildir integration tests
```

## Local setup

```bash
mise trust
mise install
mise run test
mise run test-integration
mise run doctor
```

`doctor` reports README freshness, configured codebase lints, himalaya availability,
and whether the optional local `codebase pre-commit` hook is installed.
Install it in your clone when you want convention lints to run before every commit:

```bash
codebase pre-commit
```

The hook lives under `.git/hooks/`, so it is intentionally not tracked by the repo.

## Design boundary

Do not add agent-specific behavior to `emails`.

Good inputs:

- `EMAILS_CONFIG` / `HIMALAYA_CONFIG`;
- upward `.emails/himalaya.toml`;
- `EMAILS_ACCOUNT` or `--account`;
- per-account GPG policy in config;
- password provided explicitly through stdin during setup.

Avoid:

- `AGENT`, `AGENT_HOME`, `CHAT_IDENTITY`, or Git identity;
- organization-specific domains or secret names;
- silent password lookup;
- guessing when multiple accounts have no default.

## README workflow

Edit `README.tsx`, then regenerate and check the output:

```bash
mise exec -- readme build
mise exec -- readme build --check
```

The animated logo source lives at `assets/emails-logo-frames.txt`.
The rendered GIF lives at `assets/emails-logo.gif`.
If frames change, regenerate the GIF before committing the README.

## Testing and validation before merge

```bash
mise exec -- readme build --check
mise run test
mise run test-integration
git diff --check
codebase lint "$PWD"
```

CI runs the same core checks on Ubuntu and macOS.
