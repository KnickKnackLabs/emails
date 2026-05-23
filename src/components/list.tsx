/** @jsxImportSource emails */
import { flatten, safeHtml } from "../jsx-runtime";

export function List({ ordered, children }: { ordered?: boolean; children?: any }) {
  const tag = ordered ? "ol" : "ul";
  return safeHtml(`<${tag} style="margin:8px 0;padding-left:24px;font-size:14px;">\n${flatten(children)}</${tag}>\n`);
}

export function Item({ children }: { children?: any }) {
  return safeHtml(`<li style="margin:4px 0;">${flatten(children)}</li>\n`);
}
