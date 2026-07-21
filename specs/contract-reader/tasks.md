# Tasks — The contract read (TD-061)

> T# continues global from T200 (writ-format). Client render only — tests are `--board-preview`
> capture checks (client-spec convention). Order: retire pips (small), prose plea, writ fitting,
> then the reader/scrollbar rework, then verify.

- [x] T201 [R190 / P110 / V1] — **Retire the threat pips.** Remove the reader's threat row + the
      `ThreatPips` preload; delete `threat_pips.gd` (+`.uid`).
      Test: **V1** — `--reader` capture shows no Threat row; `grep threat_pips client/` is empty;
      headless parse clean.

- [x] T202 [R191 / P110 / V2] — **The petitioner's dread.** `notice.gd plea(intel)`: tier-banded
      frame tables (APPRENTICE routine / JOURNEYMAN worried / MASTER dread), slots from intel,
      seeded `contractId+"|plea"`; rendered between preamble and charge in the reader.
      Test: **V2** — reader captures show the plea varying by tier band; deterministic across
      reopens (same fixture → same sentence).

- [x] T203 [R192 / P111 / V3] — **Content-fitted, non-uniform writs.** Per-writ seeded width inside
      the grid cell; measure target/site wrapped at that width (`ThemeDB.fallback_font`
      multiline-size, same sizes the labels use); height from content + furniture headroom +
      seeded slack, clamped to the cell; fonts step down one size if the cell can't fit; the
      chosen sizes flow into `_make_notice` (measure == render). Footprints from actual sizes.
      Test: **V3** — board capture shows varied writ sizes, every target/site (incl. "at
      Hollowmere Crossing") fully inside its sheet; `keepout ok=true minhit≥44 hit_ok=true`.

- [x] T204 [R193 / V4] — **Consume the sheet.** Reader scroll insets 34/30 → 26/22, pad → 8/8;
      `SCROLL_MODE_SHOW_NEVER` (internal bar gone); R189 clip holds.
      Test: **V4** — `--reader` + `--reader-foot` captures: wider/deeper text block, every glyph
      inside the sheet, nothing rides the torn edge.

- [x] T205 [R194 / P112 / V4] — **The quill-line scrollbar.** New `ornament_scrollbar.gd` (line +
      dot finials + chevroned diamond thumb, aged brass/gilt, interactive drag + track-jump,
      both-ways sync, auto-hide); wired beside the reader in an HBox, outside the sheet.
      Test: **V4** — captures at top/foot show the diamond at the matching position, outside the
      parchment; drag/jump verified by the foot capture matching a jumped scroll.

- [x] T206 [R190–R195 / V5] — **Verification pass.** V1–V5 by capture; asset-map regenerate +
      `--check`; suites untouched-green; diff scope `client/ specs/ docs/ CLAUDE.md`; refresh the
      board preview artifact; append DECISION_LOG TD-061; swap the active spec in CLAUDE.md.
