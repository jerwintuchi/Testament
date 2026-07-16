# Tasks — Contract Board Header redesign

> T# continues global from T182 (board-banner). Client render / generated art only — the named test is a
> `--board-preview` capture read back (client-spec convention; no Vitest). Order: art first (the plaque +
> seal must exist before the header can be built), then the Godot header, then the reserve/keepout, then
> verify. Nothing is done without its capture check. Containment: no `src/**` change (P101).

## Art

- [x] T183 [R171, R175 / P100 / V1, V5] — **`gen_header.py` — the carved plaque.** New generator emitting
      `board_header.png` (144×96, 9-slice margins 26/30/18): aged walnut/oak grain + age bands, a routed
      recessed field (groove + double bevel, carried from `gen_heraldry.nameplate_px`), forged **iron
      corner straps** each with two **bronze bolts**, and an eroded worn rim. Dim, matte, institutional —
      no gloss, no additive layer. Provenance header. Import via `godot --headless --import`.
      Test: **V1/V5** — a composited preview + a board capture show carved wood with iron/bronze
      reinforcement, worn edges, materials in register (no polished/modern surface).

- [x] T184 [R172, R175 / P100 / V2] — **`gen_header.py` — the inset bronze seal.** Emit `board_seal.png`
      (72²): socket AO annulus → iron rim → aged bronze disc (patina mottle, no specular) → the emblem in
      **raised relief** (read `collegium_logo.png` with PIL; lit upper-left / occluded lower-right edges
      derived from the alpha mask offset ∓1px, interior `BRONZE_MID` warmed by source luminance).
      `@consumes collegium_logo.png` in the provenance header.
      Test: **V2** — the seal reads as a struck bronze medallion set into a socket (rim + shadow ring),
      embossed not pasted; no glow.

## The header object

- [x] T185 [R172, R173 / P98 / V2, V3] — **Build `_board_header()` in `main.gd`.** Replace
      `_notice_placard(title)`: `board_header.png` 9-slice + a Godot contact shadow, a centered
      `VBoxContainer` in the routed field holding the seal (`TextureRect`, LINEAR, 44×44) then
      **THE COLLEGIUM** (size 20, aged gilt, letter-spaced) then **Contract Board** (size 12, dim bronze),
      each line an **engraved stacked pair** (dark incised cut under a lit face). Vertical rhythm
      seal/+10/primary/+4/secondary. **Retire** `_board_crest` (decl, build, `_process` chase) and
      `BoardDecor.board_crest()`.
      Test: **V2/V3** — a capture shows the seal inside the header (no floating crest anywhere),
      THE COLLEGIUM dominant over a subordinate Contract Board, lettering engraved + weathered, seal +
      lines reading as one centered object.

## Composition

- [x] T186 [R174 / P99 / V4] — **Grow the reserve, keep the scatter.** In `board_geometry.gd`:
      `placard_rect` h `inner.y*0.098 → *0.165`, w `inner.x*0.56 → *0.50` (clamp ≥ 300);
      `TOP_RESERVE_FRAC` 0.205 → ~0.27. Capture-iterate both.
      Test: **V4** — the keep-out self-check logs `keepout live=N ok=true … hit_ok=true` with every live
      notice placed below the taller header; a board capture shows the notice scatter, bottom bar, and
      flanking banners composition unchanged.

## Verify

- [x] T187 [R171–R176 / P98–P101 / V6] — **Verification pass.** Retire the dead `crest_px`/`crest_v1.png`
      + superseded `nameplate_px`/`board_nameplate.png` from `gen_heraldry.py` and delete the PNGs
      (+ `.import`); re-import; capture board + empty + reader on a worst-case seed; confirm V1–V5 green by
      eyeball; regenerate `asset-map.md` + `--check` (the crest double-producer conflict should clear);
      confirm `git diff --name-only` is only `client/ art/ specs/ docs/ CLAUDE.md`; server + shared Vitest
      suites still green (untouched); refresh the preview artifact; append DECISION_LOG TD-053.
      Verify: **V1–V6** green; diff scoped; suites green.

## Notes

- The seal must live **inside** the header subtree (P98). The old crest needed the overlay + `_process`
  chase only because it crowned *over* the clipping ScrollContainer's top edge (TD-049); a seal set into
  the plaque has nothing to escape, so both the overlay and the per-frame chase go.
- `gen_header.py` imports PIL to read + emboss the emblem (sanctioned for generators) but still writes via
  `ashember.write_png` so the asset-map producer edge holds; the generator→emblem INPUT edge is invisible
  to the text-static scanner — the provenance header records it (same as `gen_banner.py`).
- Do NOT touch `GUTTER_CX`, `add_torches`, or `torch_rig` — the banners/sconces/wall shader are coupled
  through them (P95, TD-052) and are out of scope here.
