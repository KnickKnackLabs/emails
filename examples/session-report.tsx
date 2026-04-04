/** @jsxImportSource emails */
// Session report — the end-of-session email to Or.
//
// Usage:
//   emails compose examples/session-report.tsx \
//     --agent x1f9 \
//     --shipped "swallow: 92 tests, README, shiv registered" \
//     --shipped "fold: creating-a-codebase hub note" \
//     --next "emails compose pipeline" \
//     --next "or#76 filename obfuscation"

import { parseArgs } from "util";
import { email } from "emails/src/email";
import {
  Heading, Paragraph, Bold, Code, Link,
  Card, Section, Stats, Stat, List, Item,
  Footer,
} from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    agent:   { type: "string" },
    shipped: { type: "string", multiple: true, default: [] },
    next:    { type: "string", multiple: true, default: [] },
    note:    { type: "string", multiple: true, default: [] },
  },
  strict: true,
});

if (!values.agent) {
  console.error("Usage: emails compose session-report.tsx --agent <name> [--shipped ...] [--next ...]");
  process.exit(1);
}

const today = new Date().toISOString().slice(0, 10);
const day = new Date().toLocaleDateString("en-US", { weekday: "long" });

const body = (
  <>
    <Heading>{values.agent} — session report</Heading>
    <Paragraph style="color:#64748b;font-size:13px;">
      {today} · {day}
    </Paragraph>

    {values.shipped!.length > 0 && (
      <Section title="Shipped">
        {values.shipped!.map((item: string) => {
          const [title, ...rest] = item.split(": ");
          return (
            <Card variant="success" title={title}>
              {rest.join(": ") || null}
            </Card>
          );
        })}
      </Section>
    )}

    {values.next!.length > 0 && (
      <Section title="Next session">
        <List>
          {values.next!.map((item: string) => <Item>{item}</Item>)}
        </List>
      </Section>
    )}

    {values.note!.length > 0 && (
      <Section title="Notes">
        {values.note!.map((item: string) => (
          <Paragraph>{item}</Paragraph>
        ))}
      </Section>
    )}

    <Footer>
      {"Composed with "}<Code>emails compose</Code>
    </Footer>
  </>
);

console.log(email({ body }));
