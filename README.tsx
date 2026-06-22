/** @jsxImportSource jsx-md */

import { readFileSync, readdirSync, existsSync, statSync } from "fs";
import { join, resolve } from "path";

import {
  Heading, Paragraph, CodeBlock, LineBreak,
  Bold, Code, Link,
  Badge, Badges, Center, Section,
  Table, TableHead, TableRow, Cell,
  List, Item, Raw, Sub, HR,
} from "readme/src/components";

// ── Dynamic data ─────────────────────────────────────────────

const REPO_DIR = resolve(import.meta.dirname);
const TASK_DIR = join(REPO_DIR, ".mise/tasks");
const TEST_DIR = join(REPO_DIR, "test");
const MISE_FILE = join(REPO_DIR, "mise.toml");

interface Command {
  name: string;
  cli: string;
  description: string;
}

function collectTaskNames(dir = TASK_DIR, prefix = ""): string[] {
  return readdirSync(dir).flatMap((entry) => {
    if (entry.startsWith("_") || entry.startsWith(".")) return [];
    const fullPath = join(dir, entry);
    const name = prefix ? `${prefix}/${entry}` : entry;
    if (statSync(fullPath).isDirectory()) return collectTaskNames(fullPath, name);
    if (name === "test" || name === "test-integration") return [];
    return [name];
  });
}

function parseTask(name: string): Command {
  const src = readFileSync(join(TASK_DIR, ...name.split("/")), "utf-8");
  const desc = src.match(/#MISE description="(.+)"/)?.[1] ?? "";
  return {
    name,
    cli: `emails ${name.replaceAll("/", " ")}`,
    description: desc,
  };
}

const commands = collectTaskNames()
  .map(parseTask)
  .sort((a, b) => a.cli.localeCompare(b.cli));

function countTests(dir: string): number {
  if (!existsSync(dir)) return 0;
  return readdirSync(dir)
    .filter((f) => f.endsWith(".bats"))
    .reduce((sum, f) => {
      const content = readFileSync(join(dir, f), "utf-8");
      return sum + (content.match(/@test /g)?.length ?? 0);
    }, 0);
}

function parseCodebaseLintRules(): string[] {
  const content = readFileSync(MISE_FILE, "utf-8");
  const lintBlock = content.match(/lint\s*=\s*\[([\s\S]*?)\]/m)?.[1] ?? "";
  return [...lintBlock.matchAll(/"([^"]+)"/g)].map((match) => match[1]);
}

const unitTests = countTests(TEST_DIR);
const integrationTests = countTests(join(TEST_DIR, "integration"));
const totalTests = unitTests + integrationTests;
const lintRules = parseCodebaseLintRules();

const coreCommands = [
  "account setup",
  "account list",
  "account default",
  "account gpg enable",
  "list",
  "read",
  "send",
  "reply",
  "example",
  "compose",
  "doctor",
].map((cliSuffix) => commands.find((cmd) => cmd.cli === `emails ${cliSuffix}`)).filter(Boolean) as Command[];

const resolutionRows = [
  ["One account", "Use it", "A single configured persona is unambiguous."],
  ["`--account work`", "Use `work`", "Explicit command flags beat defaults."],
  ["Multiple accounts, one default", "Use the default", "The config says which persona is normal here."],
  ["Multiple accounts, no default", "Fail", "The tool asks for `--account` or `emails account default`."],
  ["Two defaults", "Fail", "A broken config is safer than a guessed sender."],
];

const signingRows = [
  ["Account has no GPG", "plain send", "Unsigned"],
  ["Account has no GPG", "`--sign`", "Fail; enable signing first"],
  ["Account has GPG", "plain send", "Signed by account policy"],
  ["Account has GPG", "`--no-sign`", "Unsigned for this send"],
];

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Raw>{`<img src="assets/emails-logo.gif" alt="emails logo" width="360">\n\n`}</Raw>

      <Heading level={1}>emails</Heading>

      <Paragraph>
        <Bold>Email accounts, not agent identity.</Bold>
      </Paragraph>

      <Paragraph>
        <Code>emails</Code>
        {" is a small account/persona layer around "}
        <Link href="https://github.com/pimalaya/himalaya">himalaya</Link>
        {". It knows mail config, account names, servers, defaults, and signing policy. "}
        {"It does not know who launched it."}
      </Paragraph>

      <Badges>
        <Badge label="shell" value="bash" color="4EAA25" logo="gnubash" logoColor="white" />
        <Badge label="runtime" value="mise" color="7c3aed" href="https://mise.jdx.dev" />
        <Badge label="commands" value={`${commands.length}`} color="blue" />
        <Badge label="tests" value={`${totalTests} passing`} color="brightgreen" href="test/" />
        <Badge label="lints" value={`${lintRules.length}`} color="blue" />
        <Badge label="License" value="MIT" color="blue" href="LICENSE" />
      </Badges>
    </Center>

    <Section title="The shape">
      <CodeBlock>{`config file
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
read / list / send / reply through exactly one selected account`}</CodeBlock>

      <Paragraph>
        {"The key design decision is the boundary: account selection belongs to mail config, not to agent process state. "}
        {"That makes the same checkout usable for a person, an agent, a repo-local client persona, or a one-off operations mailbox without teaching the tool about any of those identities."}
      </Paragraph>
    </Section>

    <Section title="What it knows">
      <Table>
        <TableHead>
          <Cell>emails knows</Cell>
          <Cell>emails does not know</Cell>
        </TableHead>
        <TableRow>
          <Cell>Config paths</Cell>
          <Cell><Code>AGENT_HOME</Code>, chat identity, or workspace owner</Cell>
        </TableRow>
        <TableRow>
          <Cell>Account names and email addresses</Cell>
          <Cell>Git author, GPG signing identity for commits, or org membership</Cell>
        </TableRow>
        <TableRow>
          <Cell>IMAP/SMTP hosts and ports</Cell>
          <Cell>Where your password came from</Cell>
        </TableRow>
        <TableRow>
          <Cell>Optional default account</Cell>
          <Cell>Which account you "probably meant" when config is ambiguous</Cell>
        </TableRow>
        <TableRow>
          <Cell>Per-account GPG mail signing policy</Cell>
          <Cell>Global rules like "all agents sign" or "all company mail signs"</Cell>
        </TableRow>
      </Table>
    </Section>

    <Section title="Install">
      <CodeBlock lang="bash">{`shiv install emails`}</CodeBlock>

      <Paragraph>
        {"Set up an explicit account. Passwords come from stdin, so your secret manager stays outside the tool."}
      </Paragraph>

      <CodeBlock lang="bash">{`# Optional: keep this repo/home on its own mail config.
export EMAILS_CONFIG="$PWD/.emails/himalaya.toml"

your-secret-manager read mail/personal/password \\
  | emails account setup personal \\
      --address you@example.com \\
      --display-name "Your Name" \\
      --imap-host imap.example.com \\
      --smtp-host smtp.example.com \\
      --password-stdin`}</CodeBlock>

      <Paragraph>
        {"If the config lives in a directory named "}
        <Code>.emails</Code>
        {", setup also writes a protective "}
        <Code>.gitignore</Code>
        {" so the local password-bearing config is not accidentally committed."}
      </Paragraph>
    </Section>

    <Section title="Two personas, no guessing">
      <Paragraph>
        {"Multiple accounts are fine. Ambiguous sending is not."}
      </Paragraph>

      <CodeBlock lang="bash">{`# Add a second persona to the same config.
your-secret-manager read mail/work/password \\
  | emails account setup work \\
      --address you@company.com \\
      --imap-host imap.company.com \\
      --smtp-host smtp.company.com \\
      --password-stdin

emails account list

# Be explicit when there is no default.
emails send --account personal --to friend@example.com --subject "Lunch" -b lunch.txt
emails send --account work --to client@example.com --subject "Update" -b update.html --html

# Or choose a default for this config.
emails account default work
emails account default --clear`}</CodeBlock>

      <Table>
        <TableHead>
          <Cell>Situation</Cell>
          <Cell>Result</Cell>
          <Cell>Why</Cell>
        </TableHead>
        {resolutionRows.map(([situation, result, why]) => (
          <TableRow>
            <Cell><Raw>{situation}</Raw></Cell>
            <Cell><Raw>{result}</Raw></Cell>
            <Cell>{why}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Signing belongs to the account">
      <Paragraph>
        {"Mail signing is opt-in per persona. Configure it on the account that should sign mail; override per send only when you mean it."}
      </Paragraph>

      <CodeBlock lang="bash">{`emails account gpg enable work --local-user you@company.com
emails account gpg status work

# Require signing for one message. Fails if the selected account cannot sign.
emails send --account work --sign --to client@example.com --subject "Signed update" -b update.txt

# Suppress account-default signing for one message.
emails send --account work --no-sign --to robot@example.com --subject "Unsigned log" -b log.txt`}</CodeBlock>

      <Table>
        <TableHead>
          <Cell>Account policy</Cell>
          <Cell>Send mode</Cell>
          <Cell>Outcome</Cell>
        </TableHead>
        {signingRows.map(([policy, mode, outcome]) => (
          <TableRow>
            <Cell>{policy}</Cell>
            <Cell><Raw>{mode}</Raw></Cell>
            <Cell>{outcome}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Everyday mail">
      <CodeBlock lang="bash">{`emails welcome                    # current config, folders, recent messages
emails list                       # inbox table
emails read 42                    # message body, headers, signature status
emails reply 42 -b reply.txt      # reply through the selected account
emails quota                      # storage quota
emails sizes                      # largest folders/messages
emails wait                       # block until new mail arrives`}</CodeBlock>

      <Paragraph>
        {"Send accepts inline text, a body file, stdin, or a JSON envelope. Prefer explicit flags in scripts."}
      </Paragraph>

      <CodeBlock lang="bash">{`emails send --to user@example.com --subject "Plain update" -b body.txt
cat body.html | emails send --account work --to client@example.com --subject "HTML update" --html
emails send --file email.json
emails send --to user@example.com --subject "With attachment" -b body.txt --attach report.pdf`}</CodeBlock>
    </Section>

    <Section title="Business letters from examples">
      <Paragraph>
        {"For polished one-to-one business correspondence, start from a TSX example, edit it as the source artifact, render HTML, then send the generated file."}
      </Paragraph>

      <CodeBlock lang="bash">{`emails example business-letter > bob.tsx
$EDITOR bob.tsx
emails compose bob.tsx > bob.html
emails send --account work --to client@example.com --subject "Follow-up" --html -b bob.html`}</CodeBlock>

      <Paragraph>
        {"The business-letter example uses table-based layout and inline styles for email-client compatibility, including a constrained-width letterhead, date/descriptor area, emphasized recommendation block, bullets, and signature."}
      </Paragraph>
    </Section>

    <Section title="Safety rails">
      <List>
        <Item>Passwords arrive through explicit stdin from the caller's chosen secret manager.</Item>
        <Item>Ambiguous multi-account configs fail with the command to fix them.</Item>
        <Item>Bodies under 50 characters require <Code>--allow-short</Code>.</Item>
        <Item>If a positional subject looks like an email address, send stops and points to <Code>--cc</Code>.</Item>
        <Item>Account GPG policy decides default mail signing.</Item>
      </List>
    </Section>

    <Section title="Core command surface">
      <Paragraph>
        {"The README shows workflows, not a full command catalog. Use "}
        <Code>emails &lt;command&gt; --help</Code>
        {" for exact flags. The central commands are:"}
      </Paragraph>

      <Table>
        <TableHead>
          <Cell>Command</Cell>
          <Cell>Purpose</Cell>
        </TableHead>
        {coreCommands.map((cmd) => (
          <TableRow>
            <Cell><Code>{cmd.cli}</Code></Cell>
            <Cell>{cmd.description}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="Testing">
      <Paragraph>
        {`${totalTests} tests across two suites:`}
      </Paragraph>

      <List>
        <Item>
          <Bold>{`Unit tests (${unitTests})`}</Bold>
          {" — mock himalaya and test task logic in isolation"}
        </Item>
        <Item>
          <Bold>{`Integration tests (${integrationTests})`}</Bold>
          {" — real himalaya against a local maildir backend, full round-trip, no network"}
        </Item>
      </List>

      <CodeBlock lang="bash">{`mise run test
mise run test-integration
mise run doctor
codebase lint "$PWD"
mise exec -- readme build --check`}</CodeBlock>
    </Section>

    <Section title="Development">
      <CodeBlock lang="bash">{`git clone https://github.com/KnickKnackLabs/emails.git
cd emails
mise trust && mise install
mise run test
mise run doctor`}</CodeBlock>

      <Paragraph>
        {"Requires "}
        <Link href="https://github.com/pimalaya/himalaya">himalaya</Link>
        {". For generated docs, edit "}
        <Code>README.tsx</Code>
        {" and run "}
        <Code>mise exec -- readme build</Code>
        {"."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Center>
      <HR />

      <Sub>
        {"Generated from "}
        <Link href="https://github.com/KnickKnackLabs/readme">README.tsx</Link>
        {". Mail is a persona; choose it deliberately."}
      </Sub>
    </Center>
  </>
);

console.log(readme);
