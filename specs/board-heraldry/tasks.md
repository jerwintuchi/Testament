# Tasks — Board Heraldry (ornate crest + carved nameplate)

> T# continues global from T162 (board-lighting). Client-only; each task names its
> capture/headless verification (no GDScript unit harness — client-spec convention). Order is
> dependency order (assets → wiring → verify). Nothing is "done" without its named verification
> passing. Trust boundary: render only (I1/I2) — no server/shared edits. Run generators FROM
> `client/assets/ui/` (relative filenames).

## Assets

- [x] T163 [R147 / P83, P84] — **Ornate crest generator.** New `client/assets/ui/gen_heraldry.py`
      (imports `ashember`): a `metal()` primitive on a DIM bronze/gold ramp (dungeon-dark — catches
      by ornament + gilt edges, not brightness) + a composited crest — top filigree C-scrolls,
      broken ring, laurel wreath (leaves along a lower-flank arc, tangent-tilted so they read as a
      wreath, not radial spikes), upright sword (blade/fuller/crossguard/grip/pommel), central boss.
      Supersampled AA, lit top-left, Origin-neutral (blade + laurel = the order's). `crest_v1.png`
      150×132. Headless-imported.
      **Done** — **V1 green**: the capture shows the layered blade-and-laurel-and-scroll emblem, each
      component reading; no Origin sigil. (First cut was too bright gold → re-graded to dim bronze.)

- [x] T164 [R148 / P83] — **Carved nameplate generator.** Added `nameplate_px` to `gen_heraldry.py`
      → `board_nameplate.png` (112×48, 9-slice, margins 22/22/22/16): a dark IRON CORNER PLATE with a
      beveled lit outer rim + a domed brass bolt in each fixed corner, a warm plank bevel border, a
      deep warm-wood field with horizontal grain, and a recessed darker title panel. Headless-imported.
      **Done** — **V2 green**: the capture shows the carved plate with dark iron corner fittings +
      brass bolts; stretched to the title width the corners hold (9-slice). (First cut's corner L-arms
      read as a light-grey frame → re-authored to dark iron plates with the bolt fixed.)

## Wiring

- [x] T165 [R148, R149, R150 / P85] — **Header re-wire.** `_notice_placard(title, subtitle)` → two
      gilt labels ("THE COLLEGIUM" 17px / "CONTRACT BOARD" 9px letter-spaced, centred, drop-shadowed,
      unlit on top), nameplate 9-slice swapped in (margins 22/22/22/16), nails dropped. `placard_rect`
      widened (`w = inner.x·0.60`, taller for two lines). **Crest made a popup-tracking OVERLAY**
      (`_board_crest`, created in `_init`, added to `pcenter` OUTSIDE the clipping ScrollContainer,
      synced in `_process` anchored to the nameplate's global rect — base overlapping the plate top by
      14px) so the emblem crowns OVER the top edge without being clipped at y=0; `TOP_RESERVE_FRAC`
      0.20→0.235 so the notices reserve just below the compact plate.
      **Done** — **V3 green**: "THE COLLEGIUM / CONTRACT BOARD" gilt, centred, **8.6:1** at the title.
      **V4 green**: the crest crowns + overlaps the plate; `keepout ok=true` logs; notices show all
      lines. Reader view unaffected (the crest stays crowning above the dimmed board).

## Verification

- [x] T166 [R147–R151 / P82–P85] — **Verification pass.** DebugCapture pipeline (`--board-preview`
      + `--reader`) exercised across the iterations; the 9-slice stretches cleanly at the header
      width. **Done** — **V1–V6 green**: layered crest (V1), carved plate + iron corners hold under
      stretch (V2), title 8.6:1 (V3), crest crowns + `keepout ok=true` (V4), `--headless` clean +
      `git diff` client/docs/specs only + server 362 / shared 65 green (V5), and the capture beside
      the reference reads as the same design language — ornate blade-and-laurel crest + carved
      nameplate + title/subtitle (V6). Board-preview artifact refreshed.

## Notes

- Supersedes the T158 radiant-star crest + T159 routed placard (baseline this replaces).
- Generator gotchas (carried from board-lighting): run FROM `client/assets/ui/`; brand-new PNGs
  need `godot --headless --import` before a run loads them; `gen_structure.py` no longer owns
  `torch_sconce.png`.
- If a 9-slice nameplate with baked corner brackets streaks under stretch on this Godot build,
  fall back to a fixed-width nameplate sized to the title (no stretch) + separately-placed corner
  bracket sprites — record the pivot.
