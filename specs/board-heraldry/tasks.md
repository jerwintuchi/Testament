# Tasks — Board Heraldry (ornate crest + carved nameplate)

> T# continues global from T162 (board-lighting). Client-only; each task names its
> capture/headless verification (no GDScript unit harness — client-spec convention). Order is
> dependency order (assets → wiring → verify). Nothing is "done" without its named verification
> passing. Trust boundary: render only (I1/I2) — no server/shared edits. Run generators FROM
> `client/assets/ui/` (relative filenames).

## Assets

- [ ] T163 [R147 / P83, P84] — **Ornate crest generator.** New `client/assets/ui/gen_heraldry.py`
      (imports `ashember`): a `metal()` shading primitive on the bronze/gold ramp + composited
      crest — filigree scrolls, broken ring, laurel wreath, upright sword (blade/fuller/guard/
      grip/pommel), central boss — supersampled AA, lit top-left, Origin-neutral. Emit a taller
      `crest_v1.png` (≈150×132). Headless-import.
      Verify: **V1** — capture shows the layered blade-and-laurel-and-scroll emblem; sword + ring
      + wreath + filigree each read; no Origin sigil. (If the filigree reads messy at capture size,
      simplify to a pair of curls and record the call.)

- [ ] T164 [R148 / P83] — **Carved nameplate generator.** Add a nameplate to `gen_heraldry.py`
      (or `gen_structure.py`) → `board_nameplate.png` (≈112×48, 9-slice): iron corner brackets +
      bolts in the fixed corners, beveled plank border, deep warm-wood field with horizontal grain
      + a recessed title panel. Headless-import.
      Verify: **V2** — capture shows the carved plate with iron corner brackets/bolts + bevel;
      stretched to the title width, no smeared corner (9-slice holds).

## Wiring

- [ ] T165 [R148, R149, R150 / P85] — **Header re-wire.** `_notice_placard(title, subtitle)` →
      two gilt labels ("THE COLLEGIUM" large / "CONTRACT BOARD" small, letter-spaced, centred,
      drop-shadowed, unlit on top), nameplate 9-slice swapped in (margins 22/22/22/16), nails
      dropped. `placard_rect` widened (`w ≈ inner.x·0.62`, taller) + `board_crest` grown
      (≈96×85) and raised to crown/overlap the plate. Notices below un-occluded.
      Verify: **V3** — "THE COLLEGIUM / CONTRACT BOARD" gilt, centred, legible (≥ floor at the
      title). **V4** — crest crowns + overlaps the wider plate; `keepout ok=true` still logs.

## Verification

- [ ] T166 [R147–R151 / P82–P85] — **Verification pass.** Run the DebugCapture pipeline
      (`--board-preview`, incl. a stretched-title case), fix any GDScript/import errors; confirm
      **no server/shared file changed** and the server + shared Vitest suites are still green
      (untouched); `--headless` parses clean. Place the capture beside the reference (V6 design
      fidelity). Refresh the board-preview artifact.
      Verify: **V1–V6** green; `git diff --name-only` shows only client/docs/specs paths;
      headless clean; suites green.

## Notes

- Supersedes the T158 radiant-star crest + T159 routed placard (baseline this replaces).
- Generator gotchas (carried from board-lighting): run FROM `client/assets/ui/`; brand-new PNGs
  need `godot --headless --import` before a run loads them; `gen_structure.py` no longer owns
  `torch_sconce.png`.
- If a 9-slice nameplate with baked corner brackets streaks under stretch on this Godot build,
  fall back to a fixed-width nameplate sized to the title (no stretch) + separately-placed corner
  bracket sprites — record the pivot.
