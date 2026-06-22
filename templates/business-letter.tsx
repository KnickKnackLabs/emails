/** @jsxImportSource emails */
// Business letter template — one-to-one business correspondence.
//
// Usage:
//   emails template business-letter > draft.tsx
//   $EDITOR draft.tsx
//   emails compose draft.tsx > draft.html
//   emails send --account work --to client@example.com --subject "Follow-up" --html -b draft.html
//
// This template uses table-based layout and inline styles for broad email-client
// compatibility. Keep the source TSX as the editable artifact; treat the HTML as
// generated output.

import { flatten, safeHtml } from "emails/src/jsx-runtime";

const subject = "Follow-up";
const organization = "Your Company";
const website = "example.com";
const websiteUrl = "https://example.com";
const descriptor = "Follow-up";
const tagline = "Agent-assisted software and operations";
const date = new Date().toLocaleDateString("en-US", {
  year: "numeric",
  month: "long",
  day: "numeric",
});

const signature = {
  name: "Your Name",
  role: "Your Role, Your Company",
  email: "you@example.com",
  website,
  websiteUrl,
};

const bullets = [
  "the first thing you want to understand;",
  "the second thing you want to clarify;",
  "the concrete next step you think would help.",
];

function P({ children, style = "" }: { children?: any; style?: string }) {
  return safeHtml(`<p style="margin:0 0 18px 0;font-size:16px;line-height:1.62;color:#20262d;${style}">${flatten(children)}</p>`);
}

function Label({ children }: { children?: any }) {
  return safeHtml(`<p style="margin:28px 0 12px 0;font-size:13px;line-height:1.4;font-weight:700;letter-spacing:0.08em;text-transform:uppercase;color:#185d8f;">${flatten(children)}</p>`);
}

function Quote({ children }: { children?: any }) {
  return safeHtml(`
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;margin:23px 0 24px 0;">
  <tr>
    <td width="3" style="width:3px;background:#9fb7cc;font-size:0;line-height:0;">&nbsp;</td>
    <td style="padding:0 0 0 18px;font-size:16px;line-height:1.62;color:#20262d;">${flatten(children)}</td>
  </tr>
</table>`);
}

function BulletList({ items }: { items: string[] }) {
  return safeHtml(`
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;margin:8px 0 22px 0;">
${items.map((item) => `  <tr>
    <td valign="top" width="22" style="padding:0 0 10px 0;font-size:16px;line-height:1.5;color:#185d8f;">&bull;</td>
    <td valign="top" style="padding:0 0 10px 0;font-size:16px;line-height:1.5;color:#20262d;">${flatten(item)}</td>
  </tr>`).join("\n")}
</table>`);
}

function Signature() {
  return safeHtml(`
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;margin-top:30px;border-top:1px solid #d8dee8;">
  <tr>
    <td style="padding-top:18px;font-size:14px;line-height:1.45;color:#53606d;">
      <div style="font-weight:700;font-size:16px;color:#20262d;">${flatten(signature.name)}</div>
      <div>${flatten(signature.role)}</div>
      <div><a href="mailto:${flatten(signature.email)}" style="color:#185d8f;text-decoration:none;">${flatten(signature.email)}</a> · <a href="${flatten(signature.websiteUrl)}" style="color:#185d8f;text-decoration:none;">${flatten(signature.website)}</a></div>
    </td>
  </tr>
</table>`);
}

function BusinessLetter({ children }: { children?: any }) {
  return safeHtml(`<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${flatten(subject)}</title>
</head>
<body style="margin:0;padding:0;background:#ffffff;color:#20262d;-webkit-text-size-adjust:100%;text-size-adjust:100%;">
  <div style="display:none;max-height:0;overflow:hidden;opacity:0;color:transparent;">${flatten(descriptor)}</div>
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;background:#ffffff;">
    <tr>
      <td align="center" style="padding:34px 18px;">
        <table role="presentation" width="860" cellspacing="0" cellpadding="0" border="0" style="width:860px;max-width:860px;border-collapse:collapse;border-top:4px solid #183f5f;">
          <tr>
            <td style="padding-top:24px;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="border-collapse:collapse;margin:0 0 28px 0;font-size:13px;line-height:1.45;color:#607080;">
                <tr>
                  <td align="left" valign="top">
                    <div style="font-weight:700;color:#20262d;letter-spacing:0.03em;">${flatten(organization)} <span style="color:#9aa6b2;font-weight:500;">·</span> <a href="${flatten(websiteUrl)}" style="color:#20262d;text-decoration:none;font-weight:600;">${flatten(website)}</a></div>
                    <div style="color:#607080;">${flatten(tagline)}</div>
                  </td>
                  <td align="right" valign="top" style="color:#607080;white-space:nowrap;padding-left:24px;">
                    <div style="font-weight:700;color:#20262d;">${flatten(descriptor)}</div>
                    <div>${flatten(date)}</div>
                  </td>
                </tr>
              </table>
              ${flatten(children)}
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`);
}

const body = (
  <BusinessLetter>
    <P>Hi Name,</P>

    <P>Use this opening paragraph to connect the email to the conversation or event that prompted it.</P>

    <Quote>
      Put the central read, recommendation, or decision in this emphasized paragraph. Keep it calm and specific.
    </Quote>

    <P>Add the supporting context in normal paragraphs. This should read like a thoughtful business letter, not a marketing newsletter.</P>

    <Label>What I would want to understand next</Label>
    <BulletList items={bullets} />

    <P>Close with the proposed next step and a low-pressure invitation to correct the framing.</P>

    <Signature />
  </BusinessLetter>
);

console.log(flatten(body));
