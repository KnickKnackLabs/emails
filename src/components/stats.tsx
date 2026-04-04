/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

export function Stat({ children }: { children?: any }) {
  return `<span style="display:inline-block;background:#f1f5f9;border-radius:4px;padding:4px 10px;margin:2px 4px;font-size:13px;">${flatten(children)}</span>`;
}

export function Stats({ children }: { children?: any }) {
  return `<p style="margin:8px 0;">${flatten(children)}</p>\n`;
}
