# Requirements — Dependency Map (script ↔ asset provenance, generated + trustworthy)

> Dev-tooling / documentation. Every fresh session currently re-scours the tree to answer
> "which script loads this PNG?", "which generator writes it?", "who preloads this .gd?" —
> a recurring, avoidable context cost. This spec makes that graph a **generated, always-current**
> artifact the next session can grep instead of re-deriving.
>
> **Design ruling (author, 2026-07-13): DERIVE, don't hand-maintain.** A hand-written dependency
> doc rots on the first edit, and a *stale* map is worse than none — it misleads and costs MORE
> context than scouring fresh. So the load-graph is produced by static analysis and guarded by a
> staleness `--check`; inline comments are kept only for the one thing a scanner cannot infer —
> *why* a dependency exists (intent).
>
> **Trust boundary:** not applicable at runtime — this is build/dev tooling. The tool READS source
> (`client/`, `src/`) and WRITES only docs. It ships no game logic, is never imported by the server
> or client, and is stdlib-only Python (matches the existing `gen_*.py` toolchain). Numbering
> continues global: **R159+**, correctness **P92+**, tasks **T173+**.

---

## The generated map

**R159** (tool): a single tool derives the project's script↔asset dependency graph and writes it to
`docs/technical/asset-map.md`.
- AC: it captures every edge kind present in the tree —
  - **script → asset**: GDScript `load("res://…")` / `preload("res://…")` of a non-`.gd`/`.tscn` resource,
  - **script → script**: `preload("res://scripts/…gd")`,
  - **scene → resource**: `.tscn` `[ext_resource … path="res://…"]` (script or asset),
  - **generator → asset**: Python `write_png("name.png", …)` (incl. the `A.`-aliased form) under `client/assets/ui/`.
- AC: it resolves `res://` to the `client/` project root and records, for each asset: its **producer(s)**
  (generator) and **consumer(s)** (scripts/scenes); for each script: its **loads**, **preloads**, and
  **loaded-by**; for each generator: what it **writes**.
- AC: it is **deterministic** — the same source tree yields byte-identical output (stable sort), so the
  committed map only changes when a real dependency changes (P92).

**R160** (tool): **templated** paths are resolved, and anything the scanner cannot resolve is surfaced,
never silently dropped.
- AC: format-string paths (`"…parch_v1_%d.png" % i`, `"seal_%s.png" % o`, `%02d`, `{}`) are turned into a
  glob and matched against on-disk files, so `parch_v1_%d.png` expands to the real `parch_v1_0.png` /
  `parch_v1_1.png` edges (both as producer and consumer).
- AC: a reference the scanner **cannot** statically resolve (pure concatenation / a variable path) is listed
  verbatim in an **"Unresolved dynamic references"** section with its source location — so a reader knows the
  map's blind spots rather than trusting a false-complete graph (P93).

## Trust guards

**R161** (tool): the map is **trustworthy** — self-declaring and staleness-checkable.
- AC: the file opens with a **"generated — do not edit by hand"** banner naming the tool + the exact
  regenerate command; hand-editing is never expected.
- AC: a **`--check`** mode regenerates in memory and compares to the committed file, exiting **non-zero** on
  any difference (so CI / a pre-commit / a session's first move can prove the map is current in one command).

**R162** (tool): **orphans** and **dangling** references are reported.
- AC: an **Orphans** section lists on-disk assets under `client/assets/` with **no producer and no consumer**
  (candidate dead art) — advisory, not an error.
- AC: a **Dangling** section lists resolvable (non-pattern) `res://` references whose target file is **absent
  on disk** (a broken `load`/`ext_resource`) — advisory, surfaced for a human to fix.

## Provenance convention (the "why" a scanner can't infer)

**R163** (docs): a standard **provenance header** convention is documented so new scripts/generators record
intent the graph can't express, and `docs/technical/code-map.md` is filled to point at both the convention
and the generated map.
- AC: `code-map.md` (currently a placeholder) documents: how to read `asset-map.md`, how to regenerate it,
  the generator "run FROM `client/assets/ui/`" + headless-import gotchas, and the provenance-header format.
- AC: the provenance-header format is a short, optional block a script/generator MAY carry (e.g. a
  `# @produces` / `# @consumes` / `# @why` comment) documenting non-obvious wiring; the auto map remains the
  source of truth for *what* is wired, the header for *why*.
- AC: CLAUDE.md and `.claude/rules/spec-workflow.md` point new work at "regenerate `asset-map.md` (and pass
  `--check`) when a script/asset dependency changes."

## Cross-cutting

**R164** (containment): the tool reads source and writes only under `docs/`; it adds **no** game logic, is
never imported by `src/server`, `src/shared`, or the client at runtime, uses **stdlib only**, and does not
mutate any asset, script, or scene (P94).

---

## Verification

Spec-workflow requires a named test. Because this is Python tooling, verification is a built-in
**`--selftest`** (assert-based, no framework) plus the `--check` round-trip:
- **V1 (R159):** `--selftest` asserts known edges hold in the freshly-scanned graph — e.g. `crest_v1.png` is
  produced by `gen_heraldry.py` and consumed by `board_decor.gd`; `board_geometry.gd` is preloaded by
  `board_decor.gd`; `main.tscn` ext_resources `main.gd`.
- **V2 (R159/P92):** determinism — scanning twice yields identical bytes.
- **V3 (R160/P93):** `parch_v1_%d.png` resolves to the on-disk `parch_v1_0/1.png` edges; a synthetic
  unresolved reference lands in the "Unresolved dynamic" section.
- **V4 (R161):** after generating, `--check` exits 0; touching a `load(...)` line then `--check` exits 1;
  regenerating restores exit 0.
- **V5 (R162):** a known orphan (an asset nothing loads) appears under Orphans; a synthetic dangling
  `res://…` appears under Dangling.
- **V6 (R163):** `code-map.md` documents reading/regenerating the map + the provenance header; CLAUDE.md +
  spec-workflow.md carry the "regenerate on dependency change" pointer.
- **V7 (R164):** `git diff --name-only` shows only `tools/`, `docs/`, `specs/`, `CLAUDE.md`, and
  `.claude/` paths; the tool is stdlib-only; server + shared Vitest suites remain green (untouched).
