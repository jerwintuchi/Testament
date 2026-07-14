# Tasks — Board Banner, Crest & Placard pass

> T# continues global from T177 (dependency-map). Client render / generated art only — the named
> test is a `--board-preview` capture read back (client-spec convention; no Vitest). Order:
> quick crest fix → banner generator + imprint → placement/lighting → placard → verify. Nothing
> is done without its capture check. Containment: no `src/**` change (P96).

## Crest

- [x] T178 [R165 / V1] — **Shrink the crest.** In `board_decor.board_crest()` reduce `cs` 51×84 →
      ~40×66 (aspect 0.60, base pinned). Test: **V1** — a board capture shows the crest visibly
      smaller, still legible, not crowding the top notice row.

## Banner generator + imprint

- [x] T179 [R166, R167 / P97 / V2, V3] — **Rewrite `gen_banner.py`** into a proper banner + bake the
      bone-dye imprint. Widen to 180×360; baked crimson folds + AO; a top hem (baked pole sleeve); a
      **swallowtail** bottom (V-notch, silhouette alpha + selvage border). Load `collegium_logo.png`,
      recolor to bone (lum→BONE ramp, alpha×IMPRINT_A), LANCZOS-scale to ~0.62·W, seat in the upper
      cloth, composite → `banner_v1.png`. Add a **provenance header** (`@consumes collegium_logo.png`,
      `@why`). Test: **V2** clean cloth + swallowtail (no ragged deckle); **V3** the bone emblem reads
      as printed (crimson through), both on a composited preview and in-board.

## Placement + lighting

- [x] T180 [R168 / P95 / V4] — **Center + widen + retire hardware.** Add shared `GUTTER_CX`
      (`[0.065,0.935]`) read by BOTH `torch_rig` and `add_torches`; set banner width ≈ `vp.x·0.15`
      (overflow off-screen OK), re-derive `bs`/`target_h`, cap by height so the foot clears the sconce
      cup; delete the `rod` + nail `Panel`s. Keep the contact shadow + sconce/flame/glow. Test: **V4**
      — both banners centered in their gutters and wider; a torch-lit capture shows the wall light
      still aligned under the banners (no desync).

## Placard

- [x] T181 [R169 / V5] — **Re-cut the nameplate.** In `gen_heraldry.nameplate_px` deepen the routed
      recess + bevel, warm the plank, firm the gilt inner edge (same 9-slice margins, so
      `_notice_placard`/`placard_rect` are untouched). Test: **V5** — a capture shows a cleaner carved-
      wood placard with the gilt "CONTRACT BOARD" line, crest crowning it.

## Verify

- [x] T182 [R165–R170 / P95–P97 / V6] — **Verification pass.** Re-import new PNGs; capture board +
      empty (+ a torch-lit frame) on a worst-case seed; confirm V1–V5 green by eyeball; regenerate
      `asset-map.md` + `--check`; confirm `git diff --name-only` is only `client/ art/ specs/ docs/
      CLAUDE.md`; server + shared Vitest suites still green (untouched); refresh the preview artifact;
      append DECISION_LOG TD-052.
      Verify: **V1–V6** green; diff scoped; suites green.

## Notes

- `gen_banner.py` now imports PIL (sanctioned for generators) to read + recolor the emblem; it still
  writes via `ashember.write_png` so the asset-map scanner sees the producer edge. The
  generator→`collegium_logo.png` INPUT edge is invisible to the scanner (text-static; py only tracks
  `write_png`) — the provenance header records it.
- Keep the torch light rig the single source of gutter x (`GUTTER_CX`) — the shader reads it, so a
  hard-coded second copy would desync the wall lighting (P95).
