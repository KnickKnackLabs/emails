/** @jsxImportSource jsx-md */

import { readFileSync, readdirSync, existsSync } from "fs";
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

// Parse commands from task files
interface Command {
  name: string;
  description: string;
}

function parseTask(name: string): Command {
  const src = readFileSync(join(TASK_DIR, name), "utf-8");
  const desc = src.match(/#MISE description="(.+)"/)?.[1] ?? "";
  return { name, description: desc };
}

const commands = readdirSync(TASK_DIR)
  .filter((f) => !f.startsWith("_") && !f.startsWith(".") && f !== "test" && f !== "test-integration")
  .map(parseTask)
  .sort((a, b) => a.name.localeCompare(b.name));

// Count tests
function countTests(dir: string): number {
  if (!existsSync(dir)) return 0;
  return readdirSync(dir)
    .filter((f) => f.endsWith(".bats"))
    .reduce((sum, f) => {
      const content = readFileSync(join(dir, f), "utf-8");
      return sum + (content.match(/@test /g)?.length ?? 0);
    }, 0);
}

const unitTests = countTests(TEST_DIR);
const integrationTests = countTests(join(TEST_DIR, "integration"));
const totalTests = unitTests + integrationTests;

// ── README ───────────────────────────────────────────────────

const readme = (
  <>
    <Center>
      <Heading level={1}>emails</Heading>

      <Paragraph>
        <Bold>Email tooling for agents.</Bold>
      </Paragraph>

      <Paragraph>
        {"Wraps "}
        <Link href="https://github.com/pimalaya/himalaya">himalaya</Link>
        {" with agent identity, GPG signing, and quota management."}
      </Paragraph>

      <Badges>
        <Badge label="shell" value="bash" color="4EAA25" logo="gnubash" logoColor="white" />
        <Badge label="runtime" value="mise" color="7c3aed" href="https://mise.jdx.dev" />
        <Badge label="commands" value={`${commands.length}`} color="blue" />
        <Badge label="tests" value={`${totalTests} passing`} color="brightgreen" href="test/" />
        <Badge label="License" value="MIT" color="blue" href="LICENSE" />
      </Badges>
    </Center>

    <Section title="Install">
      <CodeBlock lang="bash">{`shiv install emails`}</CodeBlock>

      <Paragraph>
        {"First-time setup for an agent:"}
      </Paragraph>

      <CodeBlock lang="bash">{`emails setup <agent-name>`}</CodeBlock>
    </Section>

    <Section title="Quick start">
      <CodeBlock lang="bash">{`# Check inbox
emails list

# Read a message
emails read <id>

# Send a GPG-signed email
emails send user@example.com "Subject" "Message body here."

# Reply to a message
emails reply <id> "Thanks, got it."

# Overview and status
emails welcome`}</CodeBlock>
    </Section>

    <Section title="Commands">
      <Table>
        <TableHead>
          <Cell>Command</Cell>
          <Cell>Description</Cell>
        </TableHead>
        {commands.map((cmd) => (
          <TableRow>
            <Cell><Code>{`emails ${cmd.name}`}</Code></Cell>
            <Cell>{cmd.description}</Cell>
          </TableRow>
        ))}
      </Table>
    </Section>

    <Section title="HTML email">
      <Paragraph>
        {"Send and reply support "}
        <Code>--html</Code>
        {" for HTML content:"}
      </Paragraph>

      <CodeBlock lang="bash">{`# Send HTML email
emails send user@example.com "Subject" --html -b /path/to/email.html

# Pipe HTML
cat email.html | emails send user@example.com "Subject" --html

# Reply with HTML
emails reply 42 --html -b '<h1>Thanks!</h1><p>Got it.</p>'`}</CodeBlock>
    </Section>

    <Section title="GPG signing">
      <Paragraph>
        {"All outgoing messages are GPG-signed automatically using the agent's key. "}
        {"This provides a unified cryptographic identity — the same key signs git commits and emails."}
      </Paragraph>

      <Paragraph>
        {"Incoming messages show signature status when read:"}
      </Paragraph>

      <CodeBlock>{`From: brownie@ricon.family (✓ Signed by brownie <brownie@ricon.family>)
From: unknown@example.com (⚠ Unsigned)
From: imposter@ricon.family (✗ Bad signature)`}</CodeBlock>
    </Section>

    <Section title="Body input">
      <Paragraph>
        {"Messages accept body content three ways:"}
      </Paragraph>

      <CodeBlock lang="bash">{`# Positional argument
emails send user@example.com "Subject" "Inline body text."

# Flag (or file path)
emails send user@example.com "Subject" -b "Flag body text."
emails send user@example.com "Subject" -b /path/to/body.txt

# Stdin
echo "Piped body." | emails send user@example.com "Subject"`}</CodeBlock>

      <Paragraph>
        {"A minimum body length of 50 characters guards against accidental sends. "}
        {"Override with "}
        <Code>--allow-short</Code>
        {"."}
      </Paragraph>
    </Section>

    <Section title="Testing">
      <Paragraph>
        {`${totalTests} tests across two suites:`}
      </Paragraph>

      <List>
        <Item>
          <Bold>{`Unit tests (${unitTests})`}</Bold>
          {" — mock himalaya, test task logic in isolation"}
        </Item>
        <Item>
          <Bold>{`Integration tests (${integrationTests})`}</Bold>
          {" — real himalaya against a local maildir backend, full round-trip"}
        </Item>
      </List>

      <CodeBlock lang="bash">{`mise run test              # unit tests
mise run test-integration  # integration tests (maildir-backed, no network)`}</CodeBlock>
    </Section>

    <Section title="Development">
      <CodeBlock lang="bash">{`git clone https://github.com/KnickKnackLabs/emails.git
cd emails && mise trust && mise install
mise run test`}</CodeBlock>

      <Paragraph>
        {"Requires "}
        <Link href="https://github.com/pimalaya/himalaya">himalaya</Link>
        {" and a GPG key configured for the agent."}
      </Paragraph>
    </Section>

    <LineBreak />

    <Center>
      <HR />

      <Sub>
        {"This README was generated from "}
        <Link href="https://github.com/KnickKnackLabs/readme">README.tsx</Link>
        {"."}
      </Sub>
    </Center>
  </>
);

console.log(readme);
