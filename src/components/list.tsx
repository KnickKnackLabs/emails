/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

export function List({ ordered, children }: { ordered?: boolean; children?: any }) {
  const tag = ordered ? "ol" : "ul";
  return `<${tag} style="margin:8px 0;padding-left:24px;font-size:14px;">\n${flatten(children)}</${tag}>\n`;
}

export function Item({ children }: { children?: any }) {
  return `<li style="margin:4px 0;">${flatten(children)}</li>\n`;
}
