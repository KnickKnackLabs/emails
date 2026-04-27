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

const expectHtml = (value: any) => expect(String(value));

// --- Text elements ---

describe("Heading", () => {
  test("renders h1 by default", () => {
    const html = <Heading>Title</Heading>;
    expectHtml(html).toContain("<h1");
    expectHtml(html).toContain("Title");
    expectHtml(html).toContain("</h1>");
  });

  test("renders h2 with level prop", () => {
    const html = <Heading level={2}>Subtitle</Heading>;
    expectHtml(html).toContain("<h2");
    expectHtml(html).toContain("Subtitle");
  });

  test("renders h3 with level prop", () => {
    const html = <Heading level={3}>Small</Heading>;
    expectHtml(html).toContain("<h3");
  });

  test("includes inline styles", () => {
    const html = <Heading>Title</Heading>;
    expectHtml(html).toContain("style=");
    expectHtml(html).toContain("font-size");
  });

  test("rejects invalid level values at runtime", () => {
    expect(() => <Heading level={'1 onclick="alert(1)' as any}>Title</Heading>)
      .toThrow("Heading level must be 1, 2, or 3");
  });
});

describe("Paragraph", () => {
  test("wraps text in p tag", () => {
    const html = <Paragraph>Hello world</Paragraph>;
    expectHtml(html).toContain("<p");
    expectHtml(html).toContain("Hello world");
    expectHtml(html).toContain("</p>");
  });

  test("includes default styles", () => {
    const html = <Paragraph>Text</Paragraph>;
    expectHtml(html).toContain("font-size:14px");
  });

  test("accepts custom style", () => {
    const html = <Paragraph style="color:red;">Red text</Paragraph>;
    expectHtml(html).toContain("color:red;");
  });

  test("escapes text children by default", () => {
    const html = <Paragraph>{'<script>alert("x")</script> & more'}</Paragraph>;
    expectHtml(html).toContain("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; more");
    expectHtml(html).not.toContain("<script>");
  });
});

describe("Code", () => {
  test("renders inline code with background", () => {
    const html = <Code>foo()</Code>;
    expectHtml(html).toContain("<code");
    expectHtml(html).toContain("foo()");
    expectHtml(html).toContain("background");
  });
});

describe("Bold", () => {
  test("wraps in strong tag", () => {
    const html = <Bold>important</Bold>;
    expectHtml(html).toBe("<strong>important</strong>");
  });
});

describe("Link", () => {
  test("renders anchor tag", () => {
    const html = <Link href="https://example.com">click</Link>;
    expectHtml(html).toContain('<a href="https://example.com"');
    expectHtml(html).toContain("click");
    expectHtml(html).toContain("</a>");
  });

  test("includes color style", () => {
    const html = <Link href="https://example.com">click</Link>;
    expectHtml(html).toContain("color:");
  });

  test("escapes href attributes", () => {
    const html = <Link href={'https://example.com/?q="quoted"&ok=1'}>click</Link>;
    expectHtml(html).toContain('href="https://example.com/?q=&quot;quoted&quot;&amp;ok=1"');
  });

  test("rejects unsafe protocols", () => {
    const html = <Link href="javascript:alert(1)">click</Link>;
    expectHtml(html).toContain('href="#"');
    expectHtml(html).not.toContain("javascript:");
  });
});

describe("HR", () => {
  test("renders horizontal rule", () => {
    const html = <HR />;
    expectHtml(html).toContain("<hr");
    expectHtml(html).toContain("border");
  });
});

describe("LineBreak", () => {
  test("renders br tag", () => {
    const html = <LineBreak />;
    expectHtml(html).toContain("<br");
  });
});

describe("Spacer", () => {
  test("renders div with default height", () => {
    const html = <Spacer />;
    expectHtml(html).toContain("height:16px");
  });

  test("accepts custom height", () => {
    const html = <Spacer height={32} />;
    expectHtml(html).toContain("height:32px");
  });

  test("rejects invalid height values at runtime", () => {
    expect(() => <Spacer height={'1" onclick="alert(1)' as any} />)
      .toThrow("Spacer height must be a finite non-negative number");
    expect(() => <Spacer height={-1} />)
      .toThrow("Spacer height must be a finite non-negative number");
  });
});

// --- Card ---

describe("Card", () => {
  test("renders with default info variant", () => {
    const html = <Card>Content</Card>;
    expectHtml(html).toContain("Content");
    expectHtml(html).toContain("border-left");
  });

  test("renders success variant", () => {
    const html = <Card variant="success" title="Shipped">Details</Card>;
    expectHtml(html).toContain("#f0fdf4"); // success bg
    expectHtml(html).toContain("#22c55e"); // success border
    expectHtml(html).toContain("Shipped");
    expectHtml(html).toContain("Details");
  });

  test("renders warning variant", () => {
    const html = <Card variant="warning">Watch out</Card>;
    expectHtml(html).toContain("#fffbeb"); // warning bg
  });

  test("renders error variant", () => {
    const html = <Card variant="error">Failed</Card>;
    expectHtml(html).toContain("#fef2f2"); // error bg
  });

  test("title is optional", () => {
    const html = <Card variant="info">Just body</Card>;
    expectHtml(html).toContain("Just body");
    expectHtml(html).not.toContain("<strong");
  });

  test("body is optional", () => {
    const html = <Card variant="success" title="Title only" />;
    expectHtml(html).toContain("Title only");
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
    expectHtml(html).toContain("<table");
    expectHtml(html).toContain("border-collapse");
    expectHtml(html).toContain("<tr>");
    expectHtml(html).toContain("<td");
    expectHtml(html).toContain("A");
    expectHtml(html).toContain("B");
  });

  test("header cells have background", () => {
    const html = (
      <Row>
        <HeaderCell>Name</HeaderCell>
      </Row>
    );
    expectHtml(html).toContain("<th");
    expectHtml(html).toContain("background");
    expectHtml(html).toContain("Name");
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
    expectHtml(html).toContain("7 PRs");
    expectHtml(html).toContain("3 repos");
    expectHtml(html).toContain("border-radius");
    expectHtml(html).toContain("inline-block");
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
    expectHtml(html).toContain("Overview");
    expectHtml(html).toContain("Content here");
    expectHtml(html).toContain("<h2");
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
    expectHtml(html).toContain("<ul");
    expectHtml(html).toContain("<li");
    expectHtml(html).toContain("First");
    expectHtml(html).toContain("Second");
  });

  test("renders ordered list", () => {
    const html = (
      <List ordered>
        <Item>One</Item>
        <Item>Two</Item>
      </List>
    );
    expectHtml(html).toContain("<ol");
  });
});

// --- Footer ---

describe("Footer", () => {
  test("renders footer with border and muted text", () => {
    const html = <Footer>Built with love</Footer>;
    expectHtml(html).toContain("Built with love");
    expectHtml(html).toContain("border-top");
    expectHtml(html).toContain("color:");
  });
});

// --- Raw ---

describe("Raw", () => {
  test("passes through HTML unchanged", () => {
    const html = <Raw>{"<div class='custom'>hello</div>"}</Raw>;
    expectHtml(html).toBe("<div class='custom'>hello</div>");
  });

  test("keeps nested component output safe", () => {
    const html = <Paragraph><Raw>{"<em>raw</em>"}</Raw>{" & escaped"}</Paragraph>;
    expectHtml(html).toContain("<em>raw</em>");
    expectHtml(html).toContain(" &amp; escaped");
  });
});

// --- Runtime safety ---

describe("Custom components", () => {
  test("escape plain string returns by default", () => {
    function UserText({ value }: { value: string }) {
      return value;
    }

    const html = <Paragraph><UserText value={'<script>alert("x")</script> & ok'} /></Paragraph>;
    expectHtml(html).toContain("&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt; &amp; ok");
    expectHtml(html).not.toContain("<script>");
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
    expectHtml(html).toContain("<h2");
    expectHtml(html).toContain("Report");
    expectHtml(html).toContain("#f0fdf4"); // success card
    expectHtml(html).toContain("<strong>emails</strong>");
    expectHtml(html).toContain("<table");
    expectHtml(html).toContain("#1");
    expectHtml(html).toContain("7 PRs merged");
  });

  test("fragment composes multiple elements", () => {
    const html = (
      <>
        <Heading>Title</Heading>
        <Paragraph>Body</Paragraph>
      </>
    );
    expectHtml(html).toContain("<h1");
    expectHtml(html).toContain("<p");
  });
});
