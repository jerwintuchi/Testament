# Requirements — main.gd decomposition (the code-structure paydown)

> The first extraction under the code-structure canon (`.claude/rules/code-structure.md`, TD-066).
> `client/scripts/main.gd` is a 2,684-line god-object (67% of client GDScript); the canon's S5 sets
> the target — a thin shell + feature files. This spec pays it down **incrementally**, each tranche
> its own behavior-preserving, capture-verified extraction (author ruling: full decomposition target,
> scene-per-feature).
>
> **Binding rule (S5):** an extraction is a **refactor, not a redesign** — behavior is byte-for-byte
> unchanged (I1/I2 hold); only *where the code lives* changes. Render + input only; no server/shared
> change. Numbering continues global: **R214+**, correctness **P122+**, tasks **T225+**. Logged
> **TD-067**. Verified by `--board-preview` / `--rite-banner` captures (client-spec convention).

---

## The pattern (all tranches)

**R214**: each extracted module follows the canon's GDScript rules (S3/S4).
- AC: pure/transient builders become a **preloaded `RefCounted`** with `static` funcs (the
  `BoardGeo`/`BoardDecor` idiom); a persistent node-owning feature becomes its **own scene+script**
  driven via methods + signals. **Never** a global `class_name` (TD-029/30) — always
  `const X = preload(...)`.
- AC: the extracted code is **moved verbatim** (same logic, same constants, same comments); call
  sites are updated mechanically; `main.gd` shrinks by exactly what moved.

**R215**: behavior is unchanged and provable.
- AC: after each tranche, the client parses clean headless, the board renders identically, and the
  affected feature works exactly as before (capture-compared); `git diff` is scoped to
  `client/ specs/ docs/`.

## Tranche 1 — shared UI builders + the rite banner (this spec's executed scope)

**R216**: the shared font + theme + rite-banner builders leave `main.gd`.
- AC: `_cinzel` → `ui/fonts.gd` (`Fonts.cinzel`); `_build_popup_theme` + `_btn_box` →
  `ui/popup_theme.gd` (`PopupTheme.build`); `_show_rite_banner` + `_rite_band_gradient` →
  `ui/rite_banner.gd` (`RiteBanner.show(host, title, sub, reduced_motion)` — the `BoardDecor`
  builds-on-a-passed-host idiom, since it owns a transient CanvasLayer overlay).
- AC: the header still renders in Cinzel; the popup still wears its gothic theme + scene tooltip;
  the `CONTRACT SEALED` banner still fires (party-wide) and reduced-motion still shows it static.

## The remaining tranches (specified, not yet executed — follow-up commits)

**R217** (queued): `ui/widgets.gd` — `_card_label` (20 refs), `_h1`, `_hrule`, `_focus_ring`,
`_engraved_line`. Heavier (many call sites); its own extraction commit.

**R218** (queued): `board/notice_reader.gd` — the reader + seal block + `_animate_seal` +
`_spawn_seal_flash` + cooldown + scroll continuity. The most delicate (owns the TD-062/64/65
logic); a node-owning subtree → the scene-per-feature form; its own commit, heavily capture-verified.

**R219** (queued): `board/contract_board.gd` — the board shell (`_build_contract_board`,
`_make_live_notice`, `_fit_writ`, decay, fixtures, `_board_preview`), driven by the snapshot,
emitting intents via signal; `main.gd` delegates from `_build_station_content`. The final, largest
extraction; leaves `main.gd` a thin router.

## Cross-cutting

**R220** (containment): client render only.
- AC: no `src/**` change; dependency map regenerated for the new `preload` edges; suites
  untouched-green.

---

## Verification (per tranche)

- **V1 (R216/R215):** headless parse clean; a `--board-preview` capture is identical to pre-change
  (header in Cinzel, themed popup); a `--rite-banner` capture shows the banner unchanged.
- **V2 (R220):** `git diff --name-only` is only `client/ specs/ docs/`; asset-map `--check` passes;
  server + shared suites still green (untouched).
