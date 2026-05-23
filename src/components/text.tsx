/** @jsxImportSource emails */
import { escapeAttr, flatten, safeHtml } from "../jsx-runtime";

export function Heading({ level = 1, children }: { level?: 1 | 2 | 3; children?: any }) {
  if (level !== 1 && level !== 2 && level !== 3) {
    throw new TypeError("Heading level must be 1, 2, or 3");
  }

  const styles: Record<number, string> = {
    1: "font-size:20px;border-bottom:2px solid #333;padding-bottom:8px;margin:24px 0 12px 0;",
    2: "font-size:16px;color:#555;margin:24px 0 8px 0;",
    3: "font-size:14px;color:#555;margin:16px 0 6px 0;",
  };
  return safeHtml(`<h${level} style="${styles[level]}">${flatten(children)}</h${level}>\n`);
}

export function Paragraph({ style, children }: { style?: string; children?: any }) {
  const s = style ?? "font-size:14px;line-height:1.5;margin:8px 0;";
  return safeHtml(`<p style="${escapeAttr(s)}">${flatten(children)}</p>\n`);
}

export function Code({ children }: { children?: any }) {
  return safeHtml(`<code style="background:#f1f5f9;padding:2px 6px;border-radius:3px;font-size:13px;">${flatten(children)}</code>`);
}

export function Bold({ children }: { children?: any }) {
  return safeHtml(`<strong>${flatten(children)}</strong>`);
}

const ALLOWED_LINK_PROTOCOLS = new Set(["http:", "https:", "mailto:", "tel:"]);

function safeHref(href: string): string {
  const trimmed = href.trim();
  try {
    const url = new URL(trimmed);
    if (ALLOWED_LINK_PROTOCOLS.has(url.protocol)) {
      return trimmed;
    }
  } catch {
    // Relative or malformed URLs are not useful in email; fall through.
  }
  return "#";
}

export function Link({ href, children }: { href: string; children?: any }) {
  return safeHtml(`<a href="${escapeAttr(safeHref(href))}" style="color:#2563eb;text-decoration:none;">${flatten(children)}</a>`);
}

export function HR() {
  return safeHtml(`<hr style="border:none;border-top:1px solid #e2e8f0;margin:24px 0;" />\n`);
}

export function LineBreak() {
  return safeHtml(`<br />\n`);
}

export function Spacer({ height = 16 }: { height?: number }) {
  if (typeof height !== "number" || !Number.isFinite(height) || height < 0) {
    throw new TypeError("Spacer height must be a finite non-negative number");
  }

  return safeHtml(`<div style="height:${height}px;"></div>\n`);
}
