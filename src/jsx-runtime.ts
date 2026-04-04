// Custom JSX runtime that renders to HTML strings (for email).
//
// Same pattern as readme's jsx-runtime, but components produce
// inline-styled HTML instead of Markdown.

export function jsx(
  tag: string | Function,
  props: Record<string, any>,
): string {
  if (typeof tag === "function") {
    return tag(props);
  }
  throw new Error(`Unknown intrinsic element: <${tag}>. Use a component instead.`);
}

export const jsxs = jsx;

export function flatten(c: any): string {
  if (c == null) return "";
  if (Array.isArray(c)) return c.map(flatten).join("");
  return String(c);
}

export function Fragment({ children }: { children?: any }): string {
  return flatten(children);
}
