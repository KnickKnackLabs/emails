/** @jsxImportSource emails */
// Digest — pull live data and summarize it.
//
// This one's interesting because it fetches data at compose time.
// The TSX file is a program — it can do anything before rendering.
//
// Usage:
//   emails compose examples/digest.tsx --org KnickKnackLabs --days 7

import { parseArgs } from "util";
import { email } from "emails/src/email";
import {
  Heading, Paragraph, Bold, Code, Link,
  Section, Stats, Stat,
  Table, Row, Cell, HeaderCell,
  List, Item,
  Footer, HR,
} from "emails";

const { values } = parseArgs({
  args: Bun.argv.slice(2),
  options: {
    org:  { type: "string", default: "KnickKnackLabs" },
    days: { type: "string", default: "7" },
  },
  strict: true,
});

const days = parseInt(values.days!, 10);
const since = new Date(Date.now() - days * 86400000).toISOString().slice(0, 10);
const until = new Date().toISOString().slice(0, 10);

// --- Fetch data at compose time ---

interface PRData {
  repo: string;
  number: number;
  title: string;
  author: string;
  mergedAt: string;
  url: string;
}

let prs: PRData[] = [];
let fetchError: string | null = null;

try {
  // Use gh CLI to get recently merged PRs
  const result = Bun.spawnSync([
    "gh", "search", "prs",
    "--owner", values.org!,
    "--merged-at", `>${since}`,
    "--sort", "updated",
    "--limit", "20",
    "--json", "repository,number,title,author,updatedAt,url",
  ]);

  if (result.exitCode === 0) {
    const raw = JSON.parse(result.stdout.toString());
    prs = raw.map((pr: any) => ({
      repo: pr.repository.name,
      number: pr.number,
      title: pr.title,
      author: pr.author.login,
      mergedAt: pr.updatedAt.slice(0, 10),
      url: pr.url,
    }));
  } else {
    fetchError = result.stderr.toString().trim();
  }
} catch (e: any) {
  fetchError = e.message;
}

// --- Aggregate ---

const repoSet = new Set(prs.map(pr => pr.repo));
const authorSet = new Set(prs.map(pr => pr.author));
const byRepo = new Map<string, PRData[]>();
for (const pr of prs) {
  if (!byRepo.has(pr.repo)) byRepo.set(pr.repo, []);
  byRepo.get(pr.repo)!.push(pr);
}

// --- Render ---

const body = (
  <>
    <Heading>{values.org} — weekly digest</Heading>
    <Paragraph style="color:#64748b;font-size:13px;">
      {since} → {until} ({days} days)
    </Paragraph>

    {fetchError && (
      <Paragraph style="color:#b91c1c;font-size:13px;">
        {"⚠ Could not fetch PR data: "}{fetchError}
      </Paragraph>
    )}

    <Stats>
      <Stat>{prs.length} PRs merged</Stat>
      <Stat>{repoSet.size} repos active</Stat>
      <Stat>{authorSet.size} contributors</Stat>
    </Stats>

    {[...byRepo.entries()].map(([repo, repoPrs]) => (
      <Section title={repo}>
        <Table>
          <Row>
            <HeaderCell>PR</HeaderCell>
            <HeaderCell>Title</HeaderCell>
            <HeaderCell>Author</HeaderCell>
          </Row>
          {repoPrs.map(pr => (
            <Row>
              <Cell><Link href={pr.url}>#{pr.number}</Link></Cell>
              <Cell>{pr.title}</Cell>
              <Cell>{pr.author}</Cell>
            </Row>
          ))}
        </Table>
      </Section>
    ))}

    <Footer>
      {"Generated "}{until}{" via "}<Code>emails compose</Code>
    </Footer>
  </>
);

console.log(email({ body }));
