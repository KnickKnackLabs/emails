/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

export function Table({ children }: { children?: any }) {
  return `<table style="border-collapse:collapse;width:100%;margin:12px 0;">
${flatten(children)}</table>\n`;
}

export function Row({ children }: { children?: any }) {
  return `<tr>${flatten(children)}</tr>\n`;
}

export function HeaderCell({ children }: { children?: any }) {
  return `<th style="text-align:left;padding:6px 12px;border-bottom:1px solid #e2e8f0;font-size:14px;background:#f8fafc;font-weight:600;">${flatten(children)}</th>`;
}

export function Cell({ children }: { children?: any }) {
  return `<td style="text-align:left;padding:6px 12px;border-bottom:1px solid #e2e8f0;font-size:14px;">${flatten(children)}</td>`;
}
