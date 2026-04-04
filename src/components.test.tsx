/** @jsxImportSource emails */
import { expect, test, describe } from "bun:test";
import {
  Heading, Paragraph, Code, Bold, Link, HR, LineBreak, Spacer,
  Card,
  Table, Row, Cell, HeaderCell,
  Stat, Stats,
  Section,
  List, Item,
  Footer,
  Raw,
} from "./components";

// --- Text elements ---

describe("Heading", () => {
  test("renders h1 by default", () => {
    const html = <Heading>Title</Heading>;
    expect(html).toContain("<h1");
    expect(html).toContain("Title");
    expect(html).toContain("</h1>");
  });

  test("renders h2 with level prop", () => {
    const html = <Heading level={2}>Subtitle</Heading>;
    expect(html).toContain("<h2");
    expect(html).toContain("Subtitle");
  });

  test("renders h3 with level prop", () => {
    const html = <Heading level={3}>Small</Heading>;
    expect(html).toContain("<h3");
  });

  test("includes inline styles", () => {
    const html = <Heading>Title</Heading>;
    expect(html).toContain("style=");
    expect(html).toContain("font-size");
  });
});

describe("Paragraph", () => {
  test("wraps text in p tag", () => {
    const html = <Paragraph>Hello world</Paragraph>;
    expect(html).toContain("<p");
    expect(html).toContain("Hello world");
    expect(html).toContain("</p>");
  });

  test("includes default styles", () => {
    const html = <Paragraph>Text</Paragraph>;
    expect(html).toContain("font-size:14px");
  });

  test("accepts custom style", () => {
    const html = <Paragraph style="color:red;">Red text</Paragraph>;
    expect(html).toContain("color:red;");
  });
});

describe("Code", () => {
  test("renders inline code with background", () => {
    const html = <Code>foo()</Code>;
    expect(html).toContain("<code");
    expect(html).toContain("foo()");
    expect(html).toContain("background");
  });
});

describe("Bold", () => {
  test("wraps in strong tag", () => {
    const html = <Bold>important</Bold>;
    expect(html).toBe("<strong>important</strong>");
  });
});

describe("Link", () => {
  test("renders anchor tag", () => {
    const html = <Link href="https://example.com">click</Link>;
    expect(html).toContain('<a href="https://example.com"');
    expect(html).toContain("click");
    expect(html).toContain("</a>");
  });

  test("includes color style", () => {
    const html = <Link href="https://example.com">click</Link>;
    expect(html).toContain("color:");
  });
});

describe("HR", () => {
  test("renders horizontal rule", () => {
    const html = <HR />;
    expect(html).toContain("<hr");
    expect(html).toContain("border");
  });
});

describe("LineBreak", () => {
  test("renders br tag", () => {
    const html = <LineBreak />;
    expect(html).toContain("<br");
  });
});

describe("Spacer", () => {
  test("renders div with default height", () => {
    const html = <Spacer />;
    expect(html).toContain("height:16px");
  });

  test("accepts custom height", () => {
    const html = <Spacer height={32} />;
    expect(html).toContain("height:32px");
  });
});

// --- Card ---

describe("Card", () => {
  test("renders with default info variant", () => {
    const html = <Card>Content</Card>;
    expect(html).toContain("Content");
    expect(html).toContain("border-left");
  });

  test("renders success variant", () => {
    const html = <Card variant="success" title="Shipped">Details</Card>;
    expect(html).toContain("#f0fdf4"); // success bg
    expect(html).toContain("#22c55e"); // success border
    expect(html).toContain("Shipped");
    expect(html).toContain("Details");
  });

  test("renders warning variant", () => {
    const html = <Card variant="warning">Watch out</Card>;
    expect(html).toContain("#fffbeb"); // warning bg
  });

  test("renders error variant", () => {
    const html = <Card variant="error">Failed</Card>;
    expect(html).toContain("#fef2f2"); // error bg
  });

  test("title is optional", () => {
    const html = <Card variant="info">Just body</Card>;
    expect(html).toContain("Just body");
    expect(html).not.toContain("<strong");
  });

  test("body is optional", () => {
    const html = <Card variant="success" title="Title only" />;
    expect(html).toContain("Title only");
  });
});

// --- Table ---

describe("Table", () => {
  test("renders table with border-collapse", () => {
    const html = (
      <Table>
        <Row>
          <Cell>A</Cell>
          <Cell>B</Cell>
        </Row>
      </Table>
    );
    expect(html).toContain("<table");
    expect(html).toContain("border-collapse");
    expect(html).toContain("<tr>");
    expect(html).toContain("<td");
    expect(html).toContain("A");
    expect(html).toContain("B");
  });

  test("header cells have background", () => {
    const html = (
      <Row>
        <HeaderCell>Name</HeaderCell>
      </Row>
    );
    expect(html).toContain("<th");
    expect(html).toContain("background");
    expect(html).toContain("Name");
  });
});

// --- Stats ---

describe("Stats", () => {
  test("renders stat pills", () => {
    const html = (
      <Stats>
        <Stat>7 PRs</Stat>
        <Stat>3 repos</Stat>
      </Stats>
    );
    expect(html).toContain("7 PRs");
    expect(html).toContain("3 repos");
    expect(html).toContain("border-radius");
    expect(html).toContain("inline-block");
  });
});

// --- Layout ---

describe("Section", () => {
  test("renders heading and children", () => {
    const html = (
      <Section title="Overview">
        <Paragraph>Content here</Paragraph>
      </Section>
    );
    expect(html).toContain("Overview");
    expect(html).toContain("Content here");
    expect(html).toContain("<h2");
  });
});

// --- List ---

describe("List", () => {
  test("renders unordered list", () => {
    const html = (
      <List>
        <Item>First</Item>
        <Item>Second</Item>
      </List>
    );
    expect(html).toContain("<ul");
    expect(html).toContain("<li");
    expect(html).toContain("First");
    expect(html).toContain("Second");
  });

  test("renders ordered list", () => {
    const html = (
      <List ordered>
        <Item>One</Item>
        <Item>Two</Item>
      </List>
    );
    expect(html).toContain("<ol");
  });
});

// --- Footer ---

describe("Footer", () => {
  test("renders footer with border and muted text", () => {
    const html = <Footer>Built with love</Footer>;
    expect(html).toContain("Built with love");
    expect(html).toContain("border-top");
    expect(html).toContain("color:");
  });
});

// --- Raw ---

describe("Raw", () => {
  test("passes through HTML unchanged", () => {
    const html = <Raw>{"<div class='custom'>hello</div>"}</Raw>;
    expect(html).toBe("<div class='custom'>hello</div>");
  });
});

// --- Composition ---

describe("Composition", () => {
  test("components nest correctly", () => {
    const html = (
      <Section title="Report">
        <Card variant="success" title="Shipped">
          <Bold>emails</Bold>{" — extraction complete"}
        </Card>
        <Table>
          <Row>
            <HeaderCell>Repo</HeaderCell>
            <HeaderCell>PR</HeaderCell>
          </Row>
          <Row>
            <Cell><Link href="https://github.com/KnickKnackLabs/emails/pull/1">#1</Link></Cell>
            <Cell>Integration tests</Cell>
          </Row>
        </Table>
        <Stats>
          <Stat>7 PRs merged</Stat>
          <Stat>6 repos touched</Stat>
        </Stats>
      </Section>
    );
    expect(html).toContain("<h2");
    expect(html).toContain("Report");
    expect(html).toContain("#f0fdf4"); // success card
    expect(html).toContain("<strong>emails</strong>");
    expect(html).toContain("<table");
    expect(html).toContain("#1");
    expect(html).toContain("7 PRs merged");
  });

  test("fragment composes multiple elements", () => {
    const html = (
      <>
        <Heading>Title</Heading>
        <Paragraph>Body</Paragraph>
      </>
    );
    expect(html).toContain("<h1");
    expect(html).toContain("<p");
  });
});
