// app.js — Vibeboss labs dashboard frontend. Vanilla JS, no deps.
//
// Polls /api/findings every 5s, renders the rail, lets the operator
// approve / revise / reject and post comments. All state lives on disk;
// the UI is a thin view.

"use strict";

const state = {
  findings: [],     // list (metadata only)
  selectedId: null, // currently-open finding id
  filter: "pending-pickup",
};

const els = {
  list: document.getElementById("findings-list"),
  detail: document.getElementById("detail"),
  filter: document.getElementById("filter"),
  workspace: document.getElementById("workspace-name"),
  toast: document.getElementById("toast"),
  counts: {
    "pending-pickup": document.getElementById("count-pending"),
    "revise-requested": document.getElementById("count-revise"),
    "applied": document.getElementById("count-applied"),
    "rejected": document.getElementById("count-rejected"),
  },
  tpl: document.getElementById("detail-template"),
};

// ─── Utilities ──────────────────────────────────────────────────────────────

function toast(msg, isErr = false) {
  els.toast.textContent = msg;
  els.toast.classList.toggle("err", isErr);
  els.toast.classList.add("show");
  clearTimeout(toast._t);
  toast._t = setTimeout(() => els.toast.classList.remove("show"), 2400);
}

async function api(path, opts = {}) {
  const res = await fetch(path, {
    headers: { "content-type": "application/json" },
    ...opts,
  });
  let data;
  try { data = await res.json(); } catch { data = null; }
  if (!res.ok) {
    const msg = (data && data.error) || `request failed (${res.status})`;
    throw new Error(msg);
  }
  return data;
}

function el(tag, attrs = {}, ...children) {
  const node = document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (k === "class") node.className = v;
    else if (k === "dataset") Object.assign(node.dataset, v);
    else if (k.startsWith("on") && typeof v === "function") node.addEventListener(k.slice(2), v);
    else if (v !== undefined && v !== null) node.setAttribute(k, v);
  }
  for (const c of children) {
    if (c == null) continue;
    node.appendChild(typeof c === "string" ? document.createTextNode(c) : c);
  }
  return node;
}

// Highlight [Tier X] markers inside the rendered body. Returns a fragment.
function highlightTiers(text) {
  const frag = document.createDocumentFragment();
  const re = /\[Tier ([ABCDU])\]/g;
  let last = 0;
  let m;
  while ((m = re.exec(text)) !== null) {
    if (m.index > last) frag.appendChild(document.createTextNode(text.slice(last, m.index)));
    const span = document.createElement("span");
    span.className = `tier tier-${m[1].toLowerCase()}`;
    span.textContent = m[0];
    frag.appendChild(span);
    last = m.index + m[0].length;
  }
  if (last < text.length) frag.appendChild(document.createTextNode(text.slice(last)));
  return frag;
}

// ─── Counts ─────────────────────────────────────────────────────────────────

async function refreshCounts() {
  // Pull the full set (no filter) so the badges always reflect totals.
  try {
    const data = await api("/api/findings");
    if (data.workspace) els.workspace.textContent = data.workspace;
    const tally = { "pending-pickup": 0, "revise-requested": 0, "applied": 0, "rejected": 0 };
    for (const f of data.findings) {
      if (tally[f.status] !== undefined) tally[f.status]++;
    }
    for (const [status, node] of Object.entries(els.counts)) {
      node.textContent = String(tally[status]);
    }
  } catch (err) {
    // counts are best-effort
  }
}

// ─── List ───────────────────────────────────────────────────────────────────

async function refreshList() {
  const q = state.filter && state.filter !== "all" ? `?status=${encodeURIComponent(state.filter)}` : "";
  let data;
  try {
    data = await api(`/api/findings${q}`);
  } catch (err) {
    toast(err.message, true);
    return;
  }
  state.findings = data.findings;
  if (data.workspace) els.workspace.textContent = data.workspace;
  renderList();
}

function renderList() {
  // Clear the rail. Use replaceChildren() rather than innerHTML="" — we never
  // inject HTML strings; all child nodes are built via createElement / textNode,
  // and template content is cloned, so untrusted body text cannot be parsed as HTML.
  els.list.replaceChildren();
  if (state.findings.length === 0) {
    els.list.appendChild(el("li", { class: "li-empty" }, "no findings in this view"));
    return;
  }
  for (const f of state.findings) {
    const li = el(
      "li",
      {
        dataset: { id: f.id },
        class: f.id === state.selectedId ? "active" : "",
        onclick: () => selectFinding(f.id),
      },
      el("span", { class: "li-title" }, f.topic || f.id),
      el(
        "span",
        { class: "li-sub" },
        el("span", {}, f.project || ""),
        el("span", {}, f.date || ""),
        el("span", {}, f.status || ""),
      ),
    );
    els.list.appendChild(li);
  }
}

// ─── Detail ─────────────────────────────────────────────────────────────────

async function selectFinding(id) {
  state.selectedId = id;
  renderList();
  let data;
  try {
    data = await api(`/api/findings/${encodeURIComponent(id)}`);
  } catch (err) {
    toast(err.message, true);
    return;
  }
  renderDetail(data);
}

function renderDetail(f) {
  // Same XSS-safety rationale as renderList(): replaceChildren() clears without
  // touching the HTML parser. Body text from the finding file is appended via
  // text nodes inside highlightTiers().
  els.detail.replaceChildren();
  const node = els.tpl.content.cloneNode(true);

  node.querySelector(".finding-title").textContent = f.topic || f.id;

  const pills = node.querySelector(".finding-meta");
  setPill(pills, ".project", f.project ? `project: ${f.project}` : null);
  setPill(pills, ".researcher", f.researcher ? `by ${f.researcher}` : null);
  setPill(pills, ".date", f.date || null);
  setPill(pills, ".confidence", f.confidence ? `conf: ${f.confidence}` : null);
  setPill(pills, ".risk", f.risk ? `risk: ${f.risk}` : null);
  const statusPill = pills.querySelector(".status");
  statusPill.textContent = f.status;
  statusPill.dataset.status = f.status;

  const body = node.querySelector(".finding-body");
  body.appendChild(highlightTiers(f.body || ""));

  for (const btn of node.querySelectorAll("[data-action]")) {
    btn.addEventListener("click", () => onAction(f.id, btn.dataset.action, btn));
  }

  els.detail.appendChild(node);
}

function setPill(root, sel, text) {
  const pill = root.querySelector(sel);
  if (!text) { pill.remove(); return; }
  pill.textContent = text;
}

// ─── Actions ────────────────────────────────────────────────────────────────

async function onAction(id, action, btn) {
  const article = btn.closest(".finding");
  if (action === "comment") {
    const author = article.querySelector('input[name="author"]').value.trim() || "partner";
    const text = article.querySelector('textarea[name="text"]').value.trim();
    if (!text) { toast("comment cannot be empty", true); return; }
    try {
      await api(`/api/findings/${encodeURIComponent(id)}/comment`, {
        method: "POST",
        body: JSON.stringify({ author, text }),
      });
      toast("comment posted");
      article.querySelector('textarea[name="text"]').value = "";
      await Promise.all([selectFinding(id), refreshCounts()]);
    } catch (err) {
      toast(err.message, true);
    }
    return;
  }

  // status change
  try {
    await api(`/api/findings/${encodeURIComponent(id)}/status`, {
      method: "POST",
      body: JSON.stringify({ status: action }),
    });
    toast(`status -> ${action}`);
    await Promise.all([refreshList(), refreshCounts(), selectFinding(id)]);
  } catch (err) {
    toast(err.message, true);
  }
}

// ─── Wiring ─────────────────────────────────────────────────────────────────

els.filter.addEventListener("change", () => {
  state.filter = els.filter.value;
  refreshList();
});

async function tick() {
  await Promise.all([refreshList(), refreshCounts()]);
}

tick();
setInterval(tick, 5000);
