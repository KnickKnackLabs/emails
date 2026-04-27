/** @jsxImportSource emails */
import { flattenRaw } from "../jsx-runtime";

export function Raw({ children }: { children?: any }) {
  return flattenRaw(children);
}
