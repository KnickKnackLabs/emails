#!/usr/bin/env bats
# Tests for emails compose task

bats_require_minimum_version 1.5.0
load helpers

setup() {
  export MISE_CONFIG_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  setup_agent
}

# ============================================================================
# Basic compose
# ============================================================================

@test "compose: renders a simple TSX file to HTML" {
  cat > "$BATS_TEST_TMPDIR/simple.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";
import { Heading, Paragraph } from "emails";

const body = (
  <>
    <Heading>Hello</Heading>
    <Paragraph>World</Paragraph>
  </>
);
console.log(email({ body }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/simple.tsx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<!DOCTYPE html>"* ]]
  [[ "$output" == *"<h1"* ]]
  [[ "$output" == *"Hello"* ]]
  [[ "$output" == *"World"* ]]
}

@test "compose: passes arguments to TSX file" {
  cat > "$BATS_TEST_TMPDIR/args.tsx" <<'TSX'
/** @jsxImportSource emails */
import { parseArgs } from "util";
import { email } from "emails/src/email";
import { Heading } from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: { name: { type: "string" } },
  strict: true,
});

console.log(email({ body: <Heading>{values.name}</Heading> }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/args.tsx" --name "Alice"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Alice"* ]]
}

@test "compose: supports multiple repeated args" {
  cat > "$BATS_TEST_TMPDIR/multi.tsx" <<'TSX'
/** @jsxImportSource emails */
import { parseArgs } from "util";
import { email } from "emails/src/email";
import { List, Item } from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: { item: { type: "string", multiple: true, default: [] } },
  strict: true,
});

const body = <List>{values.item!.map((i: string) => <Item>{i}</Item>)}</List>;
console.log(email({ body }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/multi.tsx" --item "one" --item "two" --item "three"
  [ "$status" -eq 0 ]
  [[ "$output" == *"one"* ]]
  [[ "$output" == *"two"* ]]
  [[ "$output" == *"three"* ]]
}

@test "compose: text format skips HTML boilerplate" {
  cat > "$BATS_TEST_TMPDIR/text.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";

console.log(email({ body: "Just plain text.", format: "text" }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/text.tsx"
  [ "$status" -eq 0 ]
  [[ "$output" == "Just plain text." ]]
}

@test "compose: escapes dynamic text by default" {
  cat > "$BATS_TEST_TMPDIR/escape.tsx" <<'TSX'
/** @jsxImportSource emails */
import { parseArgs } from "util";
import { email } from "emails/src/email";
import { Paragraph, Raw } from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: { title: { type: "string" } },
  strict: true,
});

const body = (
  <>
    <Paragraph>{values.title}</Paragraph>
    <Raw>{"<strong>trusted</strong>"}</Raw>
  </>
);
console.log(email({ body }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/escape.tsx" --title '<script>alert("x")</script> & ok'
  [ "$status" -eq 0 ]
  [[ "$output" == *"&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; ok"* ]]
  [[ "$output" != *"<script>"* ]]
  [[ "$output" == *"<strong>trusted</strong>"* ]]
}

@test "compose: rejects unsafe link protocols" {
  cat > "$BATS_TEST_TMPDIR/link.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";
import { Link } from "emails";

console.log(email({ body: <Link href={'javascript:alert(1)'}>click</Link> }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/link.tsx"
  [ "$status" -eq 0 ]
  [[ "$output" == *'href="#"'* ]]
  [[ "$output" != *"javascript:"* ]]
}

@test "compose: custom component string returns are escaped" {
  cat > "$BATS_TEST_TMPDIR/custom.tsx" <<'TSX'
/** @jsxImportSource emails */
import { parseArgs } from "util";
import { email } from "emails/src/email";
import { Paragraph } from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: { title: { type: "string" } },
  strict: true,
});

function UserText({ value }: { value: string }) {
  return value;
}

console.log(email({ body: <Paragraph><UserText value={values.title!} /></Paragraph> }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/custom.tsx" --title '<script>alert("x")</script> & ok'
  [ "$status" -eq 0 ]
  [[ "$output" == *"&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; ok"* ]]
  [[ "$output" != *"<script>"* ]]
}

# ============================================================================
# Components available
# ============================================================================

@test "compose: Card component renders" {
  cat > "$BATS_TEST_TMPDIR/card.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";
import { Card } from "emails";

console.log(email({ body: <Card variant="success" title="Done">Details</Card> }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/card.tsx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"#f0fdf4"* ]]
  [[ "$output" == *"Done"* ]]
  [[ "$output" == *"Details"* ]]
}

@test "compose: Table component renders" {
  cat > "$BATS_TEST_TMPDIR/table.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";
import { Table, Row, Cell, HeaderCell } from "emails";

const body = (
  <Table>
    <Row><HeaderCell>Name</HeaderCell></Row>
    <Row><Cell>Alice</Cell></Row>
  </Table>
);
console.log(email({ body }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/table.tsx"
  [ "$status" -eq 0 ]
  [[ "$output" == *"<table"* ]]
  [[ "$output" == *"Alice"* ]]
}

# ============================================================================
# Error handling
# ============================================================================

@test "compose: fails on missing file" {
  run emails compose /nonexistent/file.tsx
  [ "$status" -ne 0 ]
  [[ "$output" == *"not found"* ]]
}

@test "compose: rejects invalid Heading level at runtime" {
  cat > "$BATS_TEST_TMPDIR/bad-heading.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";
import { Heading } from "emails";

console.log(email({ body: <Heading level={'1 onclick="alert(1)' as any}>Bad</Heading> }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/bad-heading.tsx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Heading level must be 1, 2, or 3"* ]]
}

@test "compose: rejects invalid Spacer height at runtime" {
  cat > "$BATS_TEST_TMPDIR/bad-spacer.tsx" <<'TSX'
/** @jsxImportSource emails */
import { email } from "emails/src/email";
import { Spacer } from "emails";

console.log(email({ body: <Spacer height={'1" onclick="alert(1)' as any} /> }));
TSX

  run emails compose "$BATS_TEST_TMPDIR/bad-spacer.tsx"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Spacer height must be a finite non-negative number"* ]]
}

@test "compose: fails without arguments" {
  run emails compose
  [ "$status" -ne 0 ]
}

# ============================================================================
# Example templates
# ============================================================================

@test "compose: session-report example runs" {
  run emails compose "$MISE_CONFIG_ROOT/examples/session-report.tsx" \
    --agent test-agent \
    --shipped "feature: details here" \
    --next "do more stuff"
  [ "$status" -eq 0 ]
  [[ "$output" == *"test-agent"* ]]
  [[ "$output" == *"feature"* ]]
  [[ "$output" == *"do more stuff"* ]]
}

@test "compose: alert example runs" {
  run emails compose "$MISE_CONFIG_ROOT/examples/alert.tsx" \
    --severity warning \
    --title "Disk almost full" \
    --detail "92% used on /dev/sda1"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Disk almost full"* ]]
  [[ "$output" == *"🟡"* ]]
}

@test "compose: review-request example runs" {
  run emails compose "$MISE_CONFIG_ROOT/examples/review-request.tsx" \
    --repo test/repo \
    --pr 42 \
    --reviewer alice \
    --summary "big change"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Review request"* ]]
  [[ "$output" == *"alice"* ]]
  [[ "$output" == *"#42"* ]]
}
