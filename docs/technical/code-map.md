# Code Map

> **Status:** Active. The machine-readable dependency graph lives in
> [asset-map.md](asset-map.md) (generated); this file is the human layer around it.
> **Spine:** Observe → Hypothesize → Test → Record · **Index:** [../README.md](../README.md)

## Purpose

A living map of where things live and how they wire together, so a fresh session greps **one
trustworthy file** instead of re-scouring `client/` for "which script loads this PNG? which
generator writes it? who preloads this `.gd`?".

The wiring itself is **derived from source**, never hand-maintained — a stale dependency doc is
worse than none (it misleads and costs *more* context than looking fresh). See
[DECISION_LOG](../DECISION_LOG.md) TD-051.

## The generated dependency map — [asset-map.md](asset-map.md)

`tools/asset_map.py` scans the tree and writes `asset-map.md`. It captures, for every asset, its
**producer** (the `gen_*.py` that writes it) and **consumers** (scripts/scenes that `load`/`preload`
it); for every script, its loads/preloads/loaded-by; plus **orphans** (dead art), **dangling** refs
(a `load` to a missing file), and **unresolved dynamic** refs (paths built from a variable — the
scanner's declared blind spots).

```bash
python3 tools/asset_map.py            # regenerate docs/technical/asset-map.md
python3 tools/asset_map.py --check    # exit 1 if the committed map is stale (run this first to trust it)
python3 tools/asset_map.py --selftest # assert known edges + determinism
```

**Regenerate `asset-map.md` (and confirm `--check` passes) whenever you add/remove a script↔asset
dependency** — a new `load()`, a new generator output, a new scene `ext_resource`. `--check` is the
guard that keeps the committed map honest.

### It stays current automatically (two hooks)

- **PostToolUse hook** (`.claude/settings.json` → `tools/asset_map_hook.py`): during a Claude session,
  editing a `client/` `.gd`/`.tscn` or a generator `.py` auto-regenerates the map. No manual step.
- **git pre-commit hook** (`tools/git-hooks/pre-commit`): blocks any commit whose map has drifted from
  source — the backstop for edits made **outside** a session. Install it once per clone:
  ```bash
  git config core.hooksPath tools/git-hooks
  ```
  If the hook blocks a commit, run `python3 tools/asset_map.py && git add docs/technical/asset-map.md`.

`res://` resolves to `client/`. The map is text-static by design (no Godot resource-graph
dependency); a resource loaded purely from a runtime-built string is surfaced under *Unresolved
dynamic references* rather than silently missed.

## Standing gotchas (the things sessions re-learn)

- **Generators run FROM `client/assets/ui/`** — they `write_png("name.png", …)` relative to the CWD.
  Run them from anywhere else and the PNGs land in the wrong place.
- **Brand-new PNGs need a headless import** before a game-run loads them:
  `godot --headless --path <UNC-client> --import` (writes the `.png.import`). See
  [dev-environment.md](dev-environment.md).
- **`res://assets/ui/*` == `client/assets/ui/*`** on disk; `res://scripts/*` == `client/scripts/*`.
- Full run/screenshot/server seams are in [dev-environment.md](dev-environment.md); don't re-derive them.

## Provenance-header convention (the *why* a scanner can't infer)

The generated map is the source of truth for **what** is wired. It cannot know **why**. For
non-obvious wiring, add a short, optional header block to the script/generator recording intent:

```gdscript
# @consumes res://assets/ui/crest_v1.png — heraldic crest, drawn as a popup-tracking overlay
# @why      overlay (NOT a child of the ScrollContainer) so it can crown OVER the clipped top edge
```
```python
# @produces crest_v1.png, board_nameplate.png — run FROM client/assets/ui/; headless-import new files
# @why      authored at display res + shown 1:1 NEAREST to avoid LINEAR downscale mush (TD-050)
```

Keep it to the surprising part (a clip escape, a filter choice, a size ruling, a superseded twin) —
not a restatement of the `load()` line. The auto map already carries the *what*.

## Where systems live (orientation)

| Area | Path | Notes |
|------|------|-------|
| Server (authoritative) | `src/server/` | all game state, seeded RNG, handlers |
| Wire contract | `src/shared/` | types + constants only, no logic |
| Client (render/input) | `client/` | Godot 4.7 project; zero game logic |
| UI raster generators | `client/assets/ui/gen_*.py` + `ashember.py` | stdlib PNG authoring (TD-046) |
| Board scene | `client/scripts/main.gd` + `scripts/board/*.gd` | Contract/Notice Board render |
| Protocol codegen | `tools/` (node) | GDScript codegen from the message registry |
| Dependency map | `tools/asset_map.py` → `asset-map.md` | this document's machine half |

## Future Expansion

- A `--check` pre-commit hook / CI step (keeps the map honest automatically) — natural next step,
  out of scope for the v1 tool.
- Optional: the scanner hoisting a one-line `@why` from the provenance header into the asset entry.
