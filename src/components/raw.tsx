/** @jsxImportSource emails */
import { flattenRaw, safeHtml } from "../jsx-runtime";

export function Raw({ children }: { children?: any }) {
  return safeHtml(flattenRaw(children));
}
