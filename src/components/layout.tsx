/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

export function Section({ title, children }: { title: string; children?: any }) {
  return `<h2 style="font-size:16px;color:#555;margin:24px 0 8px 0;">${flatten(title)}</h2>\n${flatten(children)}`;
}
