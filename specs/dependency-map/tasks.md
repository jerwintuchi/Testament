# Tasks — Dependency Map

> T# continues global from T172 (board-consistency). Python tooling — the named test is the tool's
> own `--selftest` + the `--check` round-trip (no Vitest; mirrors `ashember.py`'s self-test
> convention). Order: scanner core → resolution/report → guards → docs/wiring → verify. Nothing is
> "done" without its named verification. Containment: reads source, writes only docs (P94).

## Core

- [x] T173 [R159 / P92] — **Scanner + graph + generated map.** Write `tools/asset_map.py` (stdlib only):
      extract the four edge kinds (gd `load`/`preload`, tscn `ext_resource`, py `write_png`), build the
      producers/consumers/preloads model, and emit deterministic `docs/technical/asset-map.md` (Assets /
      Scripts / Generators sections, stable-sorted, with the do-not-edit banner + regenerate command).
      Test: **V1** — `--selftest` asserts `crest_v1.png` ← `gen_heraldry.py` / → `board_decor.gd`,
      `board_geometry.gd` preloaded by `board_decor.gd`, `main.tscn` → `main.gd`. **V2** — two scans are
      byte-identical.

- [x] T174 [R160 / P93] — **Templating + unresolved trail.** Resolve `%d/%s/%0Nd/{}` → glob against
      on-disk files (both producer + consumer sides); list any statically-unresolvable reference verbatim
      under "Unresolved dynamic references" with `file:line`.
      Test: **V3** — `parch_v1_%d.png` expands to the `parch_v1_0/1.png` edges; a synthetic variable-path
      `load()` fixture lands in the Unresolved section (and nowhere else).

## Guards

- [x] T175 [R161, R162] — **`--check`, orphans, dangling.** Add `--check` (regenerate in memory, `difflib`
      vs committed file, exit 1 on diff) and the Orphans (asset with no producer ∧ no consumer) + Dangling
      (resolvable ref, file absent) report sections.
      Test: **V4** — post-generate `--check` exits 0; editing a `load(...)` line makes it exit 1; regenerate
      restores 0. **V5** — a known orphan asset shows under Orphans; a synthetic dangling `res://…` shows
      under Dangling.

## Docs + workflow wiring

- [x] T176 [R163 / V6] — **code-map.md + provenance convention + pointers.** Fill `docs/technical/code-map.md`
      (how to read/regenerate `asset-map.md`, the generator CWD + headless-import gotchas, the provenance-
      header format); add the "regenerate `asset-map.md` + pass `--check` when a script/asset dependency
      changes" pointer to CLAUDE.md and `.claude/rules/spec-workflow.md`.
      Test: **V6** — the three docs carry the described content (grep for the regenerate command + header keys).

## Verify

- [x] T177 [R159–R164 / P92–P94 / V7] — **Verification pass.** Run `--selftest` (V1–V3, V5) and the `--check`
      round-trip (V4) green; confirm `git diff --name-only` is only `tools/ docs/ specs/ CLAUDE.md .claude/`;
      confirm stdlib-only (no third-party import); server + shared Vitest suites still green (untouched);
      append DECISION_LOG TD-051.
      Verify: **V1–V7** green; diff scoped; suites green.

## Notes

- The tool is text-static by design (no Godot resource-graph dependency) — runtime string-built loads are
  exactly what the Unresolved section surfaces; that is a feature, not a gap.
- A `--check` pre-commit hook / CI step is the natural follow-up but is **out of scope for v1** (R161 is met
  by the manual command).
- `res://` resolves to `client/`; generators write relative to `client/assets/ui/` (their documented CWD).
