/** @jsxImportSource emails */
import { flatten } from "../jsx-runtime";

export function Raw({ children }: { children?: any }) {
  return flatten(children);
}
