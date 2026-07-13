# Tasks — Contract Board Scene Consistency

> T# continues global from T166 (board-heraldry). Client-only; each task names its capture/headless
> verification (no GDScript unit harness — client-spec convention). Order: header layout fixes first
> (they interact), then surfaces, then the style pass, then verify. Nothing is "done" without its named
> verification. Trust boundary: render only (I1/I2). Run generators FROM `client/assets/ui/`. The carved
> frame is the reference register and is NOT touched.

## Header

- [x] T167 [R152 / P87] — **Crest: smaller + crisp.** Re-author the crest in `gen_heraldry.py` at ~display
      resolution (≈96×86, bolder strokes so sword/laurel survive small; bump `SS`); in
      `board_decor.board_crest` display it smaller (≈66×59) with `TEXTURE_FILTER_NEAREST` on face + shadow
      (kill the LINEAR downscale mush). Headless-import.
      Verify: **V1** — capture + a zoom show a smaller crest with crisp, defined sword + laurel (no blur);
      it still crowns the nameplate.

- [x] T168 [R153, R154 / P88] — **Single-line title + de-crowd.** `_notice_placard(title)` → one centred
      gilt "CONTRACT BOARD" (drop the VBox / "THE COLLEGIUM" / `_letterspace`); `placard_rect` back to a
      single-line height (~`inner.y·0.075`); `TOP_RESERVE_FRAC` back toward ~0.20 so the scatter sits clear
      of the compact header (scatter algorithm unchanged).
      Verify: **V2** — one gilt "CONTRACT BOARD" line, ≥4.5:1, no "THE COLLEGIUM". **V3** — even scatter,
      `keepout ok=true`, every live notice shows all its lines, none under the plate.

## Surfaces

- [x] T169 [R156 / P90] — **Banners shorter, clear of sconces.** In `board_decor.add_torches`, shorten the
      banner (`target_h ≈ vp.y·0.5`) so its foot ends above the sconce with a visible gap; keep the mount +
      crimson render + hem glow. Sconce/flame position unchanged.
      Verify: **V5** — capture shows each banner stopping above its sconce with a clear gap (no overlap).

- [x] T170 [R157 / P91] — **Backing + wall visible (moody).** Raise the wall `ambient` (~0.30→0.48) and the
      backing `ambient`/`diffuse_gain` (~0.42/1.1→0.56/1.25) in `_surface_material`/shader so the grain +
      masonry read at rest, kept below the parchment/frame key; ease the centre vignette a touch if it
      re-sinks the lifted backing.
      Verify: **V6** — capture shows the backing grain + wall masonry reading clearly, still darker than the
      parchments/frame; notices still pop; torch pools + frame relief unaffected.

## Style pass

- [x] T171 [R155 / P89] — **One-register consistency pass.** Audit the scene against the frame: (sharpness)
      crisp the seals/badges/tacks where a LINEAR downscale softens them (author nearer display size /
      NEAREST); (detail, level DOWN) ease parchment foxing/mottle + fibre jitter (`gen_parch_v1.py`), reduce
      cobweb/votive prominence (`_add_decay`/`gen_detail`), simplify any over-fussy seal sigil. Frame left
      as-is. Capture-driven — the bar is "no element is a sharpness/detail outlier."
      Verify: **V4** — capture + zooms show a consistent register (crest crisp, no busy/blurry outlier); the
      frame is unchanged; canon preserved.

## Verification

- [x] T172 [R152–R158 / P86–P91] — **Verification pass.** Run the DebugCapture pipeline (`--board-preview`,
      incl. `--reader`), fix any GDScript/import errors; confirm **no server/shared file changed** and the
      server + shared Vitest suites are still green (untouched); `--headless` parses clean. Refresh the
      board-preview artifact.
      Verify: **V1–V7** green; `git diff --name-only` shows only client/docs/specs paths; headless clean;
      suites green.

## Notes

- Re-tunes TD-049 (two-line title + 82×72 crest → single line + smaller crisp crest); the heraldry design
  is kept. Partially walks back TD-048 for the backing + wall only (T170); frame colour, parchment floor,
  and near-zero fire cast stand.
- If NEAREST at the crest's exact display size shows uneven pixels, author 2× the display and NEAREST-
  downscale by an integer factor; record the call.
- `board_placard.png` (routed placard) stays superseded by `board_nameplate.png`; if the single-line plate
  wants a shorter nameplate, re-proportion `board_nameplate.png` rather than reviving the old placard.
