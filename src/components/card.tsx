/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

type CardVariant = "success" | "warning" | "info" | "error";

const variantStyles: Record<CardVariant, { bg: string; border: string; titleColor: string }> = {
  success: { bg: "#f0fdf4", border: "#22c55e", titleColor: "#15803d" },
  warning: { bg: "#fffbeb", border: "#f59e0b", titleColor: "#b45309" },
  info:    { bg: "#eff6ff", border: "#3b82f6", titleColor: "#1d4ed8" },
  error:   { bg: "#fef2f2", border: "#ef4444", titleColor: "#b91c1c" },
};

export function Card({ variant = "info", title, children }: { variant?: CardVariant; title?: string; children?: any }) {
  const v = variantStyles[variant];
  return `<div style="background:${v.bg};border-left:3px solid ${v.border};padding:12px 16px;margin:12px 0;">
${title ? `<strong style="color:${v.titleColor};">${title}</strong>\n` : ""}${flatten(children) ? `<p style="margin:8px 0 0 0;font-size:14px;">${flatten(children)}</p>` : ""}
</div>\n`;
}
