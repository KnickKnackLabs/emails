/** @jsxImportSource jsx-md */

import {
  Heading,
  Paragraph,
  Bold,
  Code,
  CodeBlock,
  Link,
  Section,
  Table,
  TableHead,
  TableRow,
  Cell,
  HR,
  Center,
  List,
  Item,
} from "readme/src/components";

const readme = (
  <>
    <Center>
      <Heading level={1}>email</Heading>
      <Paragraph>
        <Bold>CLI for Outlook / Microsoft 365 email.</Bold>
      </Paragraph>
      <Paragraph>
        {"Pure bash + curl + jq — no Node, no Python, no SDK. Read, send, search, and organize mail from the terminal."}
      </Paragraph>
    </Center>

    <HR />

    <Section title="Quick Start">
      <CodeBlock lang="bash">{[
        `# Clone and install`,
        `git clone https://gecgithub01.walmart.com/vn5a6e7/email.git`,
        `cd email && mise trust && mise install`,
        ``,
        `# Login (opens browser for Microsoft OAuth)`,
        `mise run login`,
        ``,
        `# Check your inbox`,
        `mise run inbox`,
      ].join("\n")}</CodeBlock>

      <Heading level={3}>Using with shiv</Heading>
      <Paragraph>
        {"If you have "}
        <Link href="https://github.com/KnickKnackLabs/shiv">shiv</Link>
        {" installed, register as a global command:"}
      </Paragraph>
      <CodeBlock lang="bash">{[
        `shiv install email /path/to/email`,
        ``,
        `# Then use from anywhere:`,
        `email inbox`,
        `email read 1`,
        `email send --to someone@walmart.com --subject "Hello" --body "Hi there"`,
      ].join("\n")}</CodeBlock>
    </Section>

    <Section title="Commands">
      <Table>
        <TableHead>
          <Cell>Command</Cell>
          <Cell>Description</Cell>
        </TableHead>
        <TableRow>
          <Cell><Code>email welcome</Code></Cell>
          <Cell>Quick inbox overview — unread count + 5 most recent messages</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email inbox</Code></Cell>
          <Cell>{"Full inbox listing (with --limit, --unread)"}</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>{"email read <n>"}</Code></Cell>
          <Cell>{"Read a message by inbox number (with --html, --json)"}</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email send</Code></Cell>
          <Cell>{"Compose and send (with --to, --subject, --body, --cc, --confirm)"}</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>{"email reply <n>"}</Code></Cell>
          <Cell>{"Reply to a message (with --all for reply-all)"}</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>{"email search <query>"}</Code></Cell>
          <Cell>Search across all mail</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>{"email archive <n>"}</Code></Cell>
          <Cell>Move message(s) to Archive</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>{"email delete <n>"}</Code></Cell>
          <Cell>Move message(s) to Deleted Items</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email attachments</Code></Cell>
          <Cell>List attachments on a message</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email download</Code></Cell>
          <Cell>Download attachments</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email folders</Code></Cell>
          <Cell>List mail folders with unread counts</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email status</Code></Cell>
          <Cell>Check auth status</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email login</Code></Cell>
          <Cell>Authenticate (opens browser)</Cell>
        </TableRow>
        <TableRow>
          <Cell><Code>email logout</Code></Cell>
          <Cell>Clear stored tokens</Cell>
        </TableRow>
      </Table>
    </Section>

    <Section title="Examples">
      <Paragraph><Bold>Reading mail:</Bold></Paragraph>
      <CodeBlock lang="bash">{[
        `email welcome                   # quick overview (great for session start)`,
        `email inbox --limit 50          # show more messages`,
        `email inbox --unread            # only unread`,
        `email read 1                    # read by inbox number`,
        `email read 1 --html             # raw HTML view`,
      ].join("\n")}</CodeBlock>

      <Paragraph><Bold>Sending mail:</Bold></Paragraph>
      <CodeBlock lang="bash">{[
        `email send --to user@walmart.com --subject "Subject" --body "Message"`,
        `email send --to user@walmart.com --cc other@walmart.com --subject "FYI" --body "..."`,
        `email send --to user@walmart.com --subject "Auto" --body "..." --confirm  # skip prompt`,
        `email reply 3 --body "Thanks!"`,
        `email reply 3 --body "Thanks!" --all    # reply all`,
      ].join("\n")}</CodeBlock>

      <Paragraph><Bold>Organizing:</Bold></Paragraph>
      <CodeBlock lang="bash">{[
        `email archive 5`,
        `email delete 1,2,3 --confirm    # bulk delete`,
        `email search "from:brian subject:release"`,
      ].join("\n")}</CodeBlock>

      <Paragraph><Bold>JSON output</Bold>{" — every command supports "}<Code>--json</Code>{" for machine-readable output:"}</Paragraph>
      <CodeBlock lang="bash">{`email inbox --json | jq '.[0].subject'`}</CodeBlock>
    </Section>

    <Section title="Authentication">
      <Paragraph>
        {"Login uses Microsoft's OAuth2 PKCE flow via a browser redirect. Tokens are stored at "}
        <Code>~/.config/email/tokens.json</Code>
        {" and auto-refresh on each command."}
      </Paragraph>
      <Paragraph>
        <Bold>Known limitation:</Bold>
        {" The current app registration uses an SPA client type, which Microsoft limits to 24-hour refresh token lifetime. You'll need to run "}
        <Code>email login</Code>{" once per day."}
      </Paragraph>
    </Section>

    <Section title="For Agents">
      <Paragraph>
        {"If you're an AI agent setting up email for your human:"}
      </Paragraph>
      <List>
        <Item>{"Clone the repo and run "}<Code>mise trust && mise install</Code></Item>
        <Item>{"Run "}<Code>mise run login</Code>{" — this opens a browser. Tell your human: \"Please sign in with your Walmart credentials.\""}</Item>
        <Item>{"Verify with "}<Code>mise run welcome</Code></Item>
        <Item>{"Tokens expire every 24 hours. When refresh fails, ask your human to run "}<Code>email login</Code>{" again."}</Item>
      </List>
    </Section>

    <Section title="Structure">
      <CodeBlock lang="text">{[
        `email/`,
        `├── .mise/tasks/`,
        `│   ├── inbox        # List messages`,
        `│   ├── read         # Read a message`,
        `│   ├── send         # Compose and send`,
        `│   ├── reply        # Reply / reply-all`,
        `│   ├── search       # Full-text search`,
        `│   ├── archive      # Move to Archive`,
        `│   ├── delete       # Move to Deleted Items`,
        `│   ├── attachments  # List attachments`,
        `│   ├── download     # Download attachments`,
        `│   ├── folders      # List mail folders`,
        `│   ├── welcome      # Inbox overview`,
        `│   ├── status       # Auth status check`,
        `│   ├── login        # OAuth flow`,
        `│   └── logout       # Clear tokens`,
        `├── lib/`,
        `│   └── graph.sh     # MS Graph API client (token mgmt, HTTP helpers)`,
        `├── mise.toml`,
        `└── README.tsx       # This file (generates README.md)`,
      ].join("\n")}</CodeBlock>
    </Section>

    <Section title="Requirements">
      <List>
        <Item><Link href="https://mise.jdx.dev/">mise</Link>{" — task runner and tool manager"}</Item>
        <Item><Code>curl</Code>{" — HTTP requests"}</Item>
        <Item><Code>jq</Code>{" — JSON processing"}</Item>
        <Item>{"A browser — for the initial OAuth login"}</Item>
      </List>
    </Section>
  </>
);

console.log(readme);
