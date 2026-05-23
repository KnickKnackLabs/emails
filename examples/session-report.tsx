/** @jsxImportSource emails */
// Session report — human-facing end-of-session email.
//
// This is intentionally a polished example, not the smallest possible one.
// A compose file is a TSX program: parse args, compute summaries, fetch data
// if needed, then render structured HTML.
//
// Usage:
//   emails compose examples/session-report.tsx \
//     --agent junior \
//     --shipped "emails: tagged v0.4.0 and sent compose proof" \
//     --shipped "fold: announced HTML email pattern" \
//     --next "shiv#100: make shiv which report active package" \
//     --parked "sms/drugs-coach: intentionally deferred" \
//     --note "Dynamic text is escaped by default" \
//     --link "shiv#100=https://github.com/KnickKnackLabs/shiv/issues/100" \
//     | emails send rikonor@gmail.com "junior session report" --html

import { parseArgs } from "util";
import { email } from "emails/src/email";
import {
  Heading, Paragraph, Bold, Code, Link, HR, LineBreak, Spacer,
  Card, Section, Stats, Stat,
  Table, Row, Cell, HeaderCell,
  List, Item, Footer,
} from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    agent:   { type: "string" },
    shipped: { type: "string", multiple: true, default: [] },
    next:    { type: "string", multiple: true, default: [] },
    parked:  { type: "string", multiple: true, default: [] },
    note:    { type: "string", multiple: true, default: [] },
    link:    { type: "string", multiple: true, default: [] },
  },
  strict: true,
});

if (!values.agent) {
  console.error("Usage: emails compose session-report.tsx --agent <name> [--shipped ...] [--next ...]");
  process.exit(1);
}

function splitLabel(input: string): { title: string; detail: string } {
  const [title, ...rest] = input.split(": ");
  return { title, detail: rest.join(": ") };
}

function parseLink(input: string): { label: string; href: string } {
  const eq = input.indexOf("=");
  if (eq === -1) return { label: input, href: input };
  return { label: input.slice(0, eq), href: input.slice(eq + 1) };
}

const today = new Date().toISOString().slice(0, 10);
const day = new Date().toLocaleDateString("en-US", { weekday: "long" });
const shipped = values.shipped ?? [];
const next = values.next ?? [];
const parked = values.parked ?? [];
const notes = values.note ?? [];
const links = values.link ?? [];

const hasSummary = shipped.length > 0 || next.length > 0 || parked.length > 0;

const body = (
  <>
    <Heading>{values.agent} — session report</Heading>
    <Paragraph style="color:#64748b;font-size:13px;">
      {today}{" · "}{day}{" · composed with "}<Code>emails compose</Code>
    </Paragraph>

    <Stats>
      <Stat>{shipped.length} shipped</Stat>
      <Stat>{next.length} next</Stat>
      <Stat>{parked.length} parked</Stat>
      <Stat>{notes.length} notes</Stat>
    </Stats>

    {hasSummary && (
      <Section title="At a glance">
        <Table>
          <Row>
            <HeaderCell>Bucket</HeaderCell>
            <HeaderCell>Count</HeaderCell>
            <HeaderCell>First item</HeaderCell>
          </Row>
          <Row>
            <Cell><Bold>Shipped</Bold></Cell>
            <Cell>{shipped.length}</Cell>
            <Cell>{shipped[0] ?? "—"}</Cell>
          </Row>
          <Row>
            <Cell><Bold>Next</Bold></Cell>
            <Cell>{next.length}</Cell>
            <Cell>{next[0] ?? "—"}</Cell>
          </Row>
          <Row>
            <Cell><Bold>Parked</Bold></Cell>
            <Cell>{parked.length}</Cell>
            <Cell>{parked[0] ?? "—"}</Cell>
          </Row>
        </Table>
      </Section>
    )}

    {shipped.length > 0 && (
      <Section title="Shipped">
        {shipped.map((item: string) => {
          const { title, detail } = splitLabel(item);
          return (
            <Card variant="success" title={title}>
              {detail || null}
            </Card>
          );
        })}
      </Section>
    )}

    {next.length > 0 && (
      <Section title="Next session">
        <Card variant="info" title="Recommended entry point">
          Start with the first item below. Keep the scope tight; move parked threads only when Or explicitly un-parks them.
        </Card>
        <List>
          {next.map((item: string) => <Item>{item}</Item>)}
        </List>
      </Section>
    )}

    {parked.length > 0 && (
      <Section title="Parked intentionally">
        {parked.map((item: string) => {
          const { title, detail } = splitLabel(item);
          return (
            <Card variant="warning" title={title}>
              {detail || "Deferred by current priority."}
            </Card>
          );
        })}
      </Section>
    )}

    {notes.length > 0 && (
      <Section title="Notes for humans">
        {notes.map((item: string) => (
          <Paragraph>{item}</Paragraph>
        ))}
      </Section>
    )}

    {links.length > 0 && (
      <Section title="Links">
        <List>
          {links.map((item: string) => {
            const { label, href } = parseLink(item);
            return <Item><Link href={href}>{label}</Link></Item>;
          })}
        </List>
      </Section>
    )}

    <HR />
    <Paragraph>
      <Bold>Pattern:</Bold>{" use HTML for human-facing structured updates. "}
      Plain text is fine for quick agent-to-agent coordination, but reports with status, links, and next steps are easier to read as composed HTML.
      <LineBreak />
      Dynamic text is escaped by default; use <Code>Raw</Code> only for trusted static HTML.
    </Paragraph>

    <Spacer height={12} />
    <Footer>
      Generated by <Code>emails compose examples/session-report.tsx</Code>. Copy this template before customizing heavily.
    </Footer>
  </>
);

console.log(email({ body }));
