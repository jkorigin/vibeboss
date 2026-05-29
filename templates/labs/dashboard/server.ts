// server.ts — Bun HTTP server for the Vibeboss labs dashboard.
//
// Reads findings from ${WORKSPACE}/labs/research/<project>/findings/*.md and
// writes status + comments back into those files. Files-as-canon: no DB.
//
// Routes:
//   GET  /                              -> public/index.html
//   GET  /style.css, /app.js            -> static
//   GET  /api/findings[?status=...]     -> list of findings (metadata)
//   GET  /api/findings/:id              -> single finding (metadata + body)
//   POST /api/findings/:id/status       -> { status } -> rewrite frontmatter
//   POST /api/findings/:id/comment      -> { author, text } -> append to ## Comments

import { readdir, readFile, writeFile, rename, mkdir } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join, basename, dirname } from "node:path";

const WORKSPACE = process.env.WORKSPACE ?? join(import.meta.dir, "..", "..");
const RESEARCH_ROOT = join(WORKSPACE, "labs", "research");
const PUBLIC_DIR = join(import.meta.dir, "public");
const RUNTIME_DIR = join(import.meta.dir, ".runtime");
const PORT_FILE = join(RUNTIME_DIR, "port");

const PORT_MIN = 3101;
const PORT_MAX = 3110;

const VALID_STATUSES = new Set([
  "pending-pickup",
  "applied",
  "revise-requested",
  "rejected",
]);

type Finding = {
  id: string;
  path: string;
  project: string;
  frontmatter: Record<string, string>;
  body: string;
};

// ─── Frontmatter parse / serialize ───────────────────────────────────────────

function parseFrontmatter(raw: string): { fm: Record<string, string>; body: string } {
  if (!raw.startsWith("---\n")) return { fm: {}, body: raw };
  const end = raw.indexOf("\n---\n", 4);
  if (end === -1) return { fm: {}, body: raw };
  const fmRaw = raw.slice(4, end);
  const body = raw.slice(end + 5);
  const fm: Record<string, string> = {};
  for (const line of fmRaw.split("\n")) {
    const idx = line.indexOf(":");
    if (idx === -1) continue;
    const key = line.slice(0, idx).trim();
    const value = line.slice(idx + 1).trim();
    if (key) fm[key] = value;
  }
  return { fm, body };
}

function serializeFrontmatter(fm: Record<string, string>, body: string): string {
  const lines = Object.entries(fm).map(([k, v]) => `${k}: ${v}`);
  return `---\n${lines.join("\n")}\n---\n${body}`;
}

// ─── Discovery ───────────────────────────────────────────────────────────────

async function listFindings(): Promise<Finding[]> {
  if (!existsSync(RESEARCH_ROOT)) return [];
  const out: Finding[] = [];
  const projects = await readdir(RESEARCH_ROOT, { withFileTypes: true });
  for (const proj of projects) {
    if (!proj.isDirectory() || proj.name.startsWith("_") || proj.name.startsWith(".")) continue;
    const findingsDir = join(RESEARCH_ROOT, proj.name, "findings");
    if (!existsSync(findingsDir)) continue;
    const files = await readdir(findingsDir);
    for (const f of files) {
      if (!f.endsWith(".md") || f === "README.md") continue;
      const path = join(findingsDir, f);
      try {
        const raw = await readFile(path, "utf-8");
        const { fm, body } = parseFrontmatter(raw);
        out.push({
          id: f.replace(/\.md$/, ""),
          path,
          project: proj.name,
          frontmatter: fm,
          body,
        });
      } catch {
        // skip unreadable files
      }
    }
  }
  return out;
}

async function findById(id: string): Promise<Finding | null> {
  const all = await listFindings();
  return all.find((f) => f.id === id) ?? null;
}

// ─── Mutations ───────────────────────────────────────────────────────────────

async function writeFileAtomic(path: string, content: string): Promise<void> {
  const tmp = path + ".tmp";
  await writeFile(tmp, content, "utf-8");
  await rename(tmp, path);
}

async function updateStatus(f: Finding, status: string): Promise<void> {
  const next = { ...f.frontmatter, status };
  await writeFileAtomic(f.path, serializeFrontmatter(next, f.body));
}

function ts(): string {
  const d = new Date();
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())} ${p(d.getHours())}:${p(d.getMinutes())}`;
}

async function appendComment(f: Finding, author: string, text: string): Promise<void> {
  const block = `\n### ${ts()} — ${author}\n\n${text.trimEnd()}\n`;
  let body = f.body;
  if (/^## Comments\b/m.test(body)) {
    body = body.trimEnd() + "\n" + block;
  } else {
    body = body.trimEnd() + "\n\n## Comments\n" + block;
  }
  await writeFileAtomic(f.path, serializeFrontmatter(f.frontmatter, body));
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "content-type": "application/json" },
  });
}

function notFound(): Response {
  return new Response("not found", { status: 404 });
}

async function serveStatic(file: string, type: string): Promise<Response> {
  const path = join(PUBLIC_DIR, file);
  if (!existsSync(path)) return notFound();
  return new Response(Bun.file(path), { headers: { "content-type": type } });
}

function findingMeta(f: Finding) {
  return {
    id: f.id,
    project: f.project,
    topic: f.frontmatter.topic ?? f.id,
    status: f.frontmatter.status ?? "pending-pickup",
    confidence: f.frontmatter.confidence ?? "",
    risk: f.frontmatter.risk ?? "",
    date: f.frontmatter.date ?? "",
    researcher: f.frontmatter.researcher ?? "",
  };
}

// ─── Router ──────────────────────────────────────────────────────────────────

async function handle(req: Request): Promise<Response> {
  const url = new URL(req.url);
  const p = url.pathname;

  if (req.method === "GET" && (p === "/" || p === "/index.html")) {
    return serveStatic("index.html", "text/html; charset=utf-8");
  }
  if (req.method === "GET" && p === "/style.css") return serveStatic("style.css", "text/css");
  if (req.method === "GET" && p === "/app.js") return serveStatic("app.js", "application/javascript");

  if (req.method === "GET" && p === "/api/findings") {
    const filter = url.searchParams.get("status");
    const all = await listFindings();
    const list = all
      .filter((f) => !filter || (f.frontmatter.status ?? "pending-pickup") === filter)
      .map(findingMeta)
      .sort((a, b) => (b.date ?? "").localeCompare(a.date ?? ""));
    return json({ findings: list, workspace: basename(WORKSPACE) });
  }

  const match = p.match(/^\/api\/findings\/([^/]+)(\/status|\/comment)?$/);
  if (match) {
    const id = decodeURIComponent(match[1]);
    const sub = match[2];
    const f = await findById(id);
    if (!f) return json({ error: "finding not found" }, 404);

    if (req.method === "GET" && !sub) {
      return json({ ...findingMeta(f), body: f.body });
    }
    if (req.method === "POST" && sub === "/status") {
      const { status } = (await req.json().catch(() => ({}))) as { status?: string };
      if (!status || !VALID_STATUSES.has(status)) {
        return json({ error: `status must be one of: ${[...VALID_STATUSES].join(", ")}` }, 400);
      }
      await updateStatus(f, status);
      return json({ ok: true, id, status });
    }
    if (req.method === "POST" && sub === "/comment") {
      const { author, text } = (await req.json().catch(() => ({}))) as {
        author?: string;
        text?: string;
      };
      if (!author || !text) return json({ error: "author and text required" }, 400);
      await appendComment(f, author.trim(), text);
      return json({ ok: true, id });
    }
  }

  return notFound();
}

// ─── Startup ─────────────────────────────────────────────────────────────────

async function bind(): Promise<{ server: ReturnType<typeof Bun.serve>; port: number }> {
  for (let port = PORT_MIN; port <= PORT_MAX; port++) {
    try {
      const server = Bun.serve({ hostname: "127.0.0.1", port, fetch: handle });
      return { server, port };
    } catch {
      // port in use; try next
    }
  }
  throw new Error(`no free port in ${PORT_MIN}-${PORT_MAX}`);
}

if (!existsSync(RUNTIME_DIR)) await mkdir(RUNTIME_DIR, { recursive: true });

const { server, port } = await bind();
await writeFile(PORT_FILE, String(port), "utf-8");

console.log(`labs dashboard: http://127.0.0.1:${port}`);
console.log(`  workspace:    ${WORKSPACE}`);
console.log(`  research:     ${RESEARCH_ROOT}`);
console.log(`  port file:    ${PORT_FILE}`);

const shutdown = async () => {
  try {
    await Bun.write(PORT_FILE + ".closing", "");
    const { unlink } = await import("node:fs/promises");
    await unlink(PORT_FILE).catch(() => {});
    await unlink(PORT_FILE + ".closing").catch(() => {});
  } catch {
    // best effort
  }
  server.stop();
  process.exit(0);
};

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
