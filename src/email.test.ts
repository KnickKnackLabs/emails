import { expect, test, describe } from "bun:test";
import { email } from "./email";
import { safeHtml } from "./jsx-runtime";

describe("email()", () => {
  test("wraps body in inner div with max-width", () => {
    const out = email({ body: safeHtml("<p>Hello</p>") });
    expect(out).toContain('<div style="max-width:640px;');
    expect(out).toContain("</div>");
    expect(out).toContain("<p>Hello</p>");
  });

  test("inner div carries all layout styles inline", () => {
    const out = email({ body: "" });
    expect(out).toContain("margin:0 auto");
    expect(out).toContain("padding:20px");
    expect(out).toContain("font-family:-apple-system");
    expect(out).toContain("color:#1a1a1a");
    expect(out).toContain("line-height:1.5");
  });

  test("body element has no layout styles", () => {
    const out = email({ body: "" });
    expect(out).toContain('<body style="margin:0; padding:0;">');
  });

  test("does not use a style block for max-width", () => {
    const out = email({ body: "" });
    expect(out).not.toContain("max-width: 640px");
  });

  test("text format returns body as-is", () => {
    const out = email({ body: "plain text", format: "text" });
    expect(out).toBe("plain text");
  });

  test("html format includes DOCTYPE and html tags", () => {
    const out = email({ body: "" });
    expect(out).toContain("<!DOCTYPE html>");
    expect(out).toContain("<html>");
    expect(out).toContain("</html>");
  });
});
