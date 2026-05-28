// email() — wraps email body content in HTML boilerplate.
//
// Usage in a .tsx file:
//   import { email } from "emails/src/email";
//   const output = email({ body: <Section title="Report">...</Section> });
//   console.log(output);

import { flatten } from "./jsx-runtime";

export interface EmailOptions {
  body: any;
  format?: "html" | "text";
}

export function email({ body, format = "html" }: EmailOptions): string {
  if (format === "text") {
    return String(body);
  }

  const renderedBody = flatten(body);

  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
</head>
<body style="margin:0; padding:0;">
<div style="max-width:640px; margin:0 auto; padding:20px; font-family:-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color:#1a1a1a; line-height:1.5;">
${renderedBody}
</div>
</body>
</html>`;
}
