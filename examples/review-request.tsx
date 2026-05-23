/** @jsxImportSource emails */
// Review request — ask a colleague to review a PR.
//
// Usage:
//   emails compose examples/review-request.tsx \
//     --repo KnickKnackLabs/swallow \
//     --pr 1 \
//     --title "Initial implementation" \
//     --reviewer brownie \
//     --summary "92 tests, JSON + lines strategies, jq-based merge engine" \
//     --concern "The jq overlap detection uses nested reduce — might be slow on large inputs"

import { parseArgs } from "util";
import { email } from "emails/src/email";
import {
  Heading, Paragraph, Bold, Code, Link,
  Card, Section, List, Item,
  Footer,
} from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    repo:     { type: "string" },
    pr:       { type: "string" },
    title:    { type: "string" },
    reviewer: { type: "string" },
    summary:  { type: "string" },
    concern:  { type: "string", multiple: true, default: [] },
    context:  { type: "string", multiple: true, default: [] },
  },
  strict: true,
});

if (!values.repo || !values.pr || !values.reviewer) {
  console.error("Usage: emails compose review-request.tsx --repo <owner/repo> --pr <number> --reviewer <name>");
  process.exit(1);
}

const prUrl = `https://github.com/${values.repo}/pull/${values.pr}`;

const body = (
  <>
    <Heading level={1}>Review request</Heading>

    <Card variant="info" title={values.repo}>
      <Link href={prUrl}>#{values.pr}</Link>
      {values.title ? ` — ${values.title}` : ""}
    </Card>

    <Paragraph>
      {"Hey "}<Bold>{values.reviewer}</Bold>{" — would you take a look at this?"}
    </Paragraph>

    {values.summary && (
      <Section title="What changed">
        <Paragraph>{values.summary}</Paragraph>
      </Section>
    )}

    {values.concern!.length > 0 && (
      <Section title="Things I'd appreciate eyes on">
        <List>
          {values.concern!.map((c: string) => <Item>{c}</Item>)}
        </List>
      </Section>
    )}

    {values.context!.length > 0 && (
      <Section title="Context">
        {values.context!.map((c: string) => <Paragraph>{c}</Paragraph>)}
      </Section>
    )}

    <Footer>
      <Link href={prUrl}>View on GitHub</Link>
    </Footer>
  </>
);

console.log(email({ body }));
