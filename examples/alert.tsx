/** @jsxImportSource emails */
// Alert — something broke, someone needs to know.
//
// Usage:
//   emails compose examples/alert.tsx \
//     --severity error \
//     --title "CI failed on shimmer main" \
//     --detail "GPG key expired for x1f9 — signing step fails" \
//     --detail "Last successful run: 2026-04-03 08:30 UTC" \
//     --action "Rotate GPG key: shimmer gpg:rotate x1f9" \
//     --link "https://github.com/KnickKnackLabs/shimmer/actions/runs/12345"

import { parseArgs } from "util";
import { email } from "emails/src/email";
import {
  Heading, Paragraph, Bold, Code, Link,
  Card, Section, List, Item,
  Table, Row, Cell, HeaderCell,
  Footer,
} from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    severity: { type: "string", default: "warning" },
    title:    { type: "string" },
    detail:   { type: "string", multiple: true, default: [] },
    action:   { type: "string", multiple: true, default: [] },
    link:     { type: "string" },
  },
  strict: true,
});

if (!values.title) {
  console.error("Usage: emails compose alert.tsx --title <message> [--severity error|warning|info] [--detail ...] [--action ...]");
  process.exit(1);
}

const variant = (values.severity === "error" ? "error"
  : values.severity === "info" ? "info"
  : "warning") as "error" | "warning" | "info";

const emoji = { error: "🔴", warning: "🟡", info: "🔵" }[variant];

const body = (
  <>
    <Heading>{emoji} {values.title}</Heading>

    <Card variant={variant} title={`Severity: ${values.severity}`}>
      {values.detail!.length > 0 ? values.detail![0] : null}
    </Card>

    {values.detail!.length > 1 && (
      <Section title="Details">
        <List>
          {values.detail!.slice(1).map((d: string) => <Item>{d}</Item>)}
        </List>
      </Section>
    )}

    {values.action!.length > 0 && (
      <Section title="Suggested actions">
        <List>
          {values.action!.map((a: string) => (
            <Item><Code>{a}</Code></Item>
          ))}
        </List>
      </Section>
    )}

    {values.link && (
      <Paragraph>
        <Link href={values.link}>View details →</Link>
      </Paragraph>
    )}

    <Footer>
      {"Automated alert via "}<Code>emails compose</Code>
    </Footer>
  </>
);

console.log(email({ body }));
