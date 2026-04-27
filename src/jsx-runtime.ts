// Custom JSX runtime that renders to HTML strings (for email).
//
// Same pattern as readme's jsx-runtime, but components produce
// inline-styled HTML instead of Markdown.

export class SafeHtml extends String {
  readonly __safeHtml = true;

  constructor(public readonly html: string) {
    super(html);
  }
}

export function safeHtml(html: string): SafeHtml {
  return new SafeHtml(html);
}

export function escapeHtml(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

export const escapeAttr = escapeHtml;

export function jsx(
  tag: string | Function,
  props: Record<string, any>,
): SafeHtml {
  if (typeof tag === "function") {
    const rendered = tag(props ?? {});
    return rendered instanceof SafeHtml ? rendered : safeHtml(flatten(rendered));
  }
  throw new Error(`Unknown intrinsic element: <${tag}>. Use a component instead.`);
}

export const jsxs = jsx;

export function flatten(c: any): string {
  if (c == null || c === false) return "";
  if (c instanceof SafeHtml) return c.html;
  if (Array.isArray(c)) return c.map(flatten).join("");
  return escapeHtml(String(c));
}

export function flattenRaw(c: any): string {
  if (c == null || c === false) return "";
  if (c instanceof SafeHtml) return c.html;
  if (Array.isArray(c)) return c.map(flattenRaw).join("");
  return String(c);
}

export function Fragment({ children }: { children?: any }): SafeHtml {
  return safeHtml(flatten(children));
}
