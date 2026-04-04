/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

export function Footer({ children }: { children?: any }) {
  return `<div style="margin-top:32px;padding-top:12px;border-top:1px solid #e2e8f0;color:#94a3b8;font-size:12px;">${flatten(children)}</div>\n`;
}
