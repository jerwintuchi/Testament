# Code Structure — Canon

How Testament's code is organized. The goal is a project that stays **readable,
maintainable, and scalable**: small files with one job, a tree that makes the
trust boundary obvious, and the smallest possible change per task. These rules
are descriptive of what already works (`src/server/`, `src/shared/`, the client
UI components) and prescriptive for the one place that doesn't yet (`main.gd`).

> **The proven model:** `src/server/` is 49 files at one responsibility each with
> colocated tests; `src/shared/` is 13 files of types-only. That IS the standard.
> The client should read the same way. Do not "improve" the server layout — mirror it.

## S0 — The Golden Rule

If you cannot state a file's single responsibility in one sentence, it is doing
too much. Split it.

## S1 — The three layers ARE the security model (never blur them)

The directory boundary is the trust boundary (see `netcode-invariants.md`). Keep
it a *visible* boundary so a reviewer spots a violation by the file it lives in.

| Layer  | Path            | Holds                                        | Tests                        |
|--------|-----------------|----------------------------------------------|------------------------------|
| Server | `src/server/`   | ALL game logic + state; authoritative        | `*.test.ts` colocated (Vitest) |
| Shared | `src/shared/`   | Wire types + constants ONLY — no logic (I4)  | shape/contract tests         |
| Client | `client/`       | Render + input; a render copy, never a source | capture-verified (client-spec) |

Rules: no game-state evaluation in `client/` or `src/shared/`; no `src/**` import
of anything under `client/`; a client file that reads authoritative state directly
(instead of the snapshot) is a bug, not a shortcut.

## S2 — One responsibility per file

1. A file's **name says what it does** (`selectContract.ts`, `notice_reader.gd`),
   not what type it is (`utils.gd`, `helpers.ts` are smells — name the domain).
2. **Group by feature/domain, not by mechanical type.** The server proves this:
   `incarnate/`, `rooms/handlers/`, `site/`. The client mirrors it — a Contract
   Board feature lives under `board/`, not scattered across a flat `scripts/` pile.
   (The engine's own top-level split — `scenes/` vs `scripts/` vs `assets/` — is a
   Godot requirement and stays; feature-grouping happens *within* `scripts/`.)
3. **Soft size ceiling ≈ 300–400 lines** for a script/module. Crossing it is a
   signal to split, not a hard failure. `main.gd` is the standing exception being
   paid down under S5 — nothing else may join it there.
4. **Colocate tests** on the server/shared side: `foo.ts` beside `foo.test.ts`.

## S3 — GDScript decomposition (scene-per-feature)

The client is decomposed the Godot-native way, not by mechanically slicing
functions into files:

1. **A module that OWNS a node subtree → its own scene + script.** The Contract
   Board, the notice reader, a HUD panel each become `feature.tscn` + `feature.gd`,
   **instanced** by the parent and **driven via methods** (`refresh(snapshot)`),
   **decoupled upward via signals** (child emits an intent; parent forwards it to
   the server). This is the biggest readability win and how new node-owning UI ships.
2. **Pure logic / stateless helpers → a preloaded `RefCounted` "namespace"** with
   `static` funcs (the `BoardGeo` / `Notice` pattern). No nodes, no state.
3. **Cross-cutting services → an autoload singleton** (`PixelScale`, `Net`).
4. **Never a global `class_name`** — always `const X = preload(...)` (TD-029/30), so
   a `--headless` parse/import resolves every dependency.
5. **Client emits intentions, never derives state** (I1): a component renders the
   snapshot it is handed and emits signals; it does not mutate game state or call
   the server directly (the shell owns the socket).

## S4 — Within-file order (source-level consistency)

Every script reads top-to-bottom in the same order, so any file is navigable at a
glance (this standardizes what `main.gd`'s `# ── section ──` markers already hint):

1. Class doc comment (`## …` — the one-sentence responsibility, S0).
2. `extends` (+ `const` preloads).
3. `const` values, then `signal`s.
4. Member `var`s, **grouped and commented** (e.g. server-derived state, then UI state).
5. `_ready` / lifecycle.
6. Public API (methods the parent calls).
7. Signal handlers / `_on_*`.
8. Private helpers.
9. `_process` / `_draw` / `_input` grouped at the end.

Keep the `# ── … ──` divider convention between these groups.

## S5 — `main.gd`: the standing debt + its target

`client/scripts/main.gd` (~2.7k lines, one god-object) is decomposed incrementally
toward a **thin shell**: boot, autoload wiring, and the `_on_message` router that
**delegates** to feature modules. Target shape:

```
client/scripts/
  main.gd            — boot + the _on_message router (delegates only)
  net.gd             — socket service (autoload-style)
  core/              — screen_manager.gd (Screen enum + _show_*), session_state.gd (render copy)
  world/             — walkable_world.gd, player.gd, space_view.gd
  board/             — contract_board.(tscn+gd), notice_reader.gd, seal_block.gd,
                       + the existing board_geometry/board_decor/board_bar/notice/
                         wax_seal/verb_badge/ornament_scrollbar
  stations/          — station_popup.gd, quartermaster.gd
  ui/                — theme.gd, widgets.gd (_card_label/_hrule/focus ring/…)
```

Rules while the debt is paid down:
- **New client features do NOT enter `main.gd`.** They start as their own file/scene.
- Each extraction is its **own spec (R#→T#→test) + commit**, verified by a
  `--board-preview`/screen capture, `git diff` scoped to `client/ specs/ docs/`.
- Behavior is unchanged by an extraction (I1/I2 hold); a refactor is not a redesign.

## S6 — Performance is architecture, not file layout

File structure has ~zero runtime cost (scripts compile once). Performance comes from
*what the code does*, and the canon captures the lesson:

- **Update the smallest subtree that reflects a change** — never rebuild a whole
  screen for a local one (TD-065: a stamp refreshes only the reader, not the board).
- **Memoize deterministic generators** (TD-064: the board textures are built once).
- **Avoid per-frame allocation / regeneration** in `_process` and rebuild paths.

If a change is slow, look at the rebuild scope and per-frame work — not the file tree.

## S7 — Tie-in to the spec workflow

Structure does not replace `spec-workflow.md`; it constrains it:
- `design.md` **names the file(s)/scene(s)** a feature will live in (S2/S3).
- A client feature that owns nodes ships as a **scene** (S3.1).
- Regenerate the dependency map on any new `load`/`preload`/`ext_resource`
  (`tools/asset_map.py`; see `docs/technical/code-map.md`).

---

**Golden rule, restated:** one file, one responsibility, one sentence. The server
already lives this — bring the client to it, one extraction at a time.
