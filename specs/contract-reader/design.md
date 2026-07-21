# Design — The contract read (TD-061)

> Satisfies R190–R195. Client render only. Verified by `--board-preview` captures.

---

## R190/R191 — pips out, dread in

- `main.gd`: drop the `ThreatPips` preload + the reader's threat row; delete
  `client/scripts/ui/threat_pips.gd` (+`.uid`). Git history is the archive (unlike the wax seal
  there is no art to keep — the control drew primitives).
- `notice.gd` gains the plea grammar: per-tier frame tables in the petitioner's voice, slots from
  intel (`siteName`, requester `role`/`place`), seeded `contractId + "|plea"`:
  - APPRENTICE — routine unease: "A small unquiet thing; we would know its name.", …
  - JOURNEYMAN — worry: "The parish keeps indoors past vespers; this is beyond us.", …
  - MASTER — dread: "Two wardens went to look. Neither returned. We beg haste.", …
- `_build_notice_reader`: the plea renders as its own centred line (petitioner's italic register =
  the soft ink used by the preamble) between preamble and charge, replacing the threat row.

## R192 — content-fitted, seeded, non-uniform writs

`BoardGeo.layout_live` keeps returning the grid **cells** (centre + cell size — the disjoint
ceiling). `main._build_contract_board` then derives each writ's own rect inside its cell:

1. Seeded width: `w = cw · (0.80 + 0.20·u1)` (`u1` from `hash(cid+"|w")`), floored, ≥ `HIT_MIN`.
2. Measure the text at that width via `ThemeDB.fallback_font.get_multiline_string_size` (the same
   font Labels use): target at size 9, site at size 7, wrapped to `w - 2·pad`.
3. `h = ceil(target_h + site_h + separation + furniture headroom)` (+ a small seeded slack so even
   short writs vary), clamped to `[HIT_MIN, ch]`.
4. If the needed `h > ch` (long text in a short cell), step fonts down one size (8/6) and remeasure
   — the guarantee that nothing ever clips (the old failure: "at Hollowmere Crossing" wrapped past
   the sheet).
5. The chosen per-writ font sizes are passed into `_make_notice` so measure == render (P111).

Footprints use the actual writ size (≤ cell), so `all_disjoint` holds by construction; the
keep-out self-check log stays the arbiter. Flavor notices untouched.

## R193/R194 — the sheet consumed, the quill-line scrollbar outside

- `_build_notice_reader`: scroll insets shrink (34/30 → 26/22; pad 12/10 → 8/8) — the freed
  scrollbar width plus the tightened margin goes to text. `vertical_scroll_mode =
  SCROLL_MODE_SHOW_NEVER` (scrolling live, internal bar gone); `_style_scrollbar` call dropped.
- New `client/scripts/ui/ornament_scrollbar.gd` (preloaded, render+input only):
  - `attach(scroll: ScrollContainer)` — reads the scroll's `VScrollBar` (`value/max_value/page`),
    listens to its `value_changed` + `changed` for both-ways sync; hides itself (and stops
    drawing) when `page >= max_value` (no scroll needed).
  - `_draw()`: a 1px vertical line in dim aged brass; 2.5px dot finials at both ends; the thumb a
    **rotated-square lozenge** (outlined, transparent fill) with two inner chevrons (^ over v,
    per the reference), centred at `lerp(top+inset, bottom-inset, scroll_ratio)`, in brighter
    gilt. No bloom (R175 heritage).
  - Input: LEFT press on the lozenge starts a drag (`ratio = (y - top) / span` → sets
    `scroll_vertical`); LEFT press on the line jumps to that ratio; wheel events fall through to
    the reader (IGNORE outside presses). Emits nothing; touches no state but the scroll value.
- Placement: `_show_notice_reader` wraps reader + ornament in an `HBoxContainer` (separation 10)
  inside the existing CenterContainer; the ornament is ~14px wide, `SIZE_SHRINK_CENTER`, its
  height ~82% of the reader's. It sits fully outside the parchment (the dim shows between).

## Correctness Properties

- **P110 (no number anywhere, R190/R191):** no rendered contract surface shows tier as a count,
  scale, meter, or label; the plea is prose derived only from intel; deterministic per contract.
- **P111 (measure == render, R192):** the size used to lay a writ out is computed with the same
  font, size, and wrap width the writ renders with — so fitting is exact, not heuristic; every
  writ stays inside its cell and `keepout ok=true`.
- **P112 (ornament is a view, R194):** the scrollbar reads/writes only the ScrollContainer's
  scroll value; it emits no message, holds no state of its own beyond drag bookkeeping, and
  hides when scrolling is impossible.

## Files touched

Edited: `client/scripts/main.gd` (pips out; plea row; per-writ sizing; reader insets; ornament
wiring), `client/scripts/ui/notice.gd` (plea grammar), `client/scripts/ui/board_geometry.gd`
(only if a helper is needed — cells API unchanged), `docs/DECISION_LOG.md` (TD-061), `CLAUDE.md`
(active spec), `docs/technical/asset-map.md` (regenerated). New:
`client/scripts/ui/ornament_scrollbar.gd`, `specs/contract-reader/*`. Deleted:
`client/scripts/ui/threat_pips.gd` (+`.uid`).
