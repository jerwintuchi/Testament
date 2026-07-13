# Design — Contract Board Scene Consistency

> Satisfies R152–R158. **Client render only** (I1/I2): no server/shared/wire change. Re-tunes
> existing generators + wiring; adds no new system. Canon preserved (TD-046 hand-painted raster);
> the carved frame is the reference register and is **not touched**. Partial walk-back of TD-048
> (backing + wall only) logged in DECISION_LOG TD-050.

---

## R152 — Crest: smaller + crisp

Root cause of the blur: `crest_v1.png` is authored 150×132 and displayed ~82×72 via a LINEAR
`TextureRect` (`board_decor.board_crest`) — a downscale interpolation mush.

- **`gen_heraldry.py`:** author the crest at (near) display resolution so there is little/no
  downscale. Reduce the canvas to ~**96×86** and **bump `SS`** (supersample) for clean AA at that
  size, keeping bold, defined sword/laurel/ring/filigree shapes (thicker strokes so they survive at
  the smaller size). The design is unchanged — only scale + stroke weight.
- **`board_decor.board_crest`:** display the crest at ~its native size (≈**66×59**, smaller than the
  old 82×72) and set the face + shadow `texture_filter = TEXTURE_FILTER_NEAREST` (crisp pixel edges,
  no LINEAR smear). If NEAREST at the exact display size still shows uneven pixels, display at an
  **integer fraction** of the source (author 2× the display, NEAREST) — pick whichever reads crispest
  in V1 and record it.
- The overlay placement (`_process`, anchored to the nameplate rect, TD-049) is unchanged; the smaller
  `size` naturally reduces the crest's footprint over the notices (feeds R154).

## R153 — Title: "CONTRACT BOARD" only

- **`_notice_placard(title)`** (main.gd) drops the two-label VBox for a **single** centred gilt
  `_card_label("CONTRACT BOARD", ~15, GILT)` with the existing drop shadow (unlit on top). The
  `_letterspace` subtitle + the "THE COLLEGIUM" line are removed. `_place_placard` passes one string.
- **`placard_rect`** (board_geometry): height back to a **single-line** band (~`inner.y·0.075`), and it
  may narrow a touch (a name-plate, not a banner). The plate reads as one carved sign with the gilt title.

## R154 — De-crowd the scatter (keep it)

- With the crest smaller (R152) and the plate single-line (R153), restore breathing room:
  **`TOP_RESERVE_FRAC`** back toward **~0.20** (from 0.235) so notices sit just below the compact
  header. The scatter algorithm (`_layout_live` / keep-out) is **unchanged** — only the reserve + the
  header footprint shrink, so the seeded sizes/rotation/jitter stay (TD-040) but nothing crowds.
- Verify `keepout ok=true` and that each live notice shows its full lines (V3).

## R155 — One register: sharpness + detail

The frame is the anchor (untouched). Audit + normalise the rest:
- **Sharpness:** the crest (R152) is the main offender. Also review the wax **seals**, verb **badges**,
  and **tacks** — where a LINEAR downscale softens a small emblem, author nearer to display size and/or
  filter NEAREST so it reads crisp, consistent with the frame.
- **Detail (level DOWN to the frame):** turn down props that read busy/noisy relative to the frame:
  - **Parchment** (`gen_parch_v1.py`): ease the **foxing / mottle** intensity (`mott`, the `mott < -3`
    foxing) and the per-pixel fibre jitter so the paper reads clean-aged, not speckled.
  - **Decay** (`_add_decay` / `gen_detail`): reduce **cobweb** opacity/reach and the **votive** clutter
    so they're a whisper, not a focal detail.
  - **Seal sigils / tacks:** simplify any over-fussy sigil linework to match the register.
  - The exact set is capture-driven (V4) — the bar is "no element is a detail outlier against the frame."
- This is render/asset only — no element's identity or behaviour changes (P89).

## R156 — Banners shorter, clear of the sconces

In `board_decor.add_torches`:
- The banner currently spans `target_h = vp.y·0.72` with the sconce mounted at its **foot**
  (`cup_y = banner_bottom − vp.y·0.02`) — so cloth overlaps the fixture. Decouple them:
  - **Shorten** the banner (`target_h ≈ vp.y·0.5`) and hang it in the **upper** gutter (`banner_top`
    unchanged) so its **foot ends above the sconce**.
  - Keep the sconce at its own gutter position (near its current `cup_y`), leaving a **visible gap**
    between the banner hem and the sconce cup — cloth and fixture read as two separate things.
- Keep the mount (rod + nails + contact shadow) and the T157 crimson render; the warm hem glow (baked
  at the banner foot) still reads since the foot is just its own lower edge now.

## R157 — Backing + wall visible (moody)

A **partial** walk-back of TD-048 for the two surfaces only (`main.gd _build_contract_board` /
`_surface_material` args + `board_surface.gdshader` `ambient`/`diffuse_gain`):
- **Wall** (`_stone_bg`, currently `_surface_material(wall_v1_n, ambient 0.30, diffuse_gain 1.0)`):
  raise `ambient` (~**0.48**) so the masonry reads at rest; keep it the darkest surface.
- **Backing** (currently `ambient 0.42, diffuse_gain 1.1`): raise so the plank grain reads (~`ambient
  0.56, diffuse_gain 1.25`), still below the parchment/frame key.
- Order (dark→light): wall < backing < parchments/frame. The torch cup pools + the frame's carved relief
  are unaffected (only the two base keys rise). Tune exact values against V6 (grain/masonry legible,
  still moodier than the foreground). The vignette (over the papers) may need a slight ease so the lifted
  backing isn't re-sunk at the edges.

## Correctness Properties

- **P86 (render-only, R158):** every change is a client asset/shader/node param; no `src/server` or
  `src/shared` edit, no wire, no game-state read/write.
- **P87 (crest crisp + read, R152):** the sword + laurel read as hard defined forms at the smaller size
  (no downscale mush); the emblem is still recognisable and crowns the plate.
- **P88 (scatter un-crowded, R154):** the seeded scatter is unchanged in kind; `keepout ok=true`; no live
  notice is pushed under the header, clipped, or crowded — every one shows its full lines.
- **P89 (one register, R155):** no board element reads as a sharpness or detail outlier against the frame;
  the frame is unchanged; the canonical hand-painted raster register is preserved (not replaced).
- **P90 (banner ∥ sconce, R156):** the banner hem ends above the sconce with a visible gap — no cloth-on-
  fixture overlap at any supported viewport.
- **P91 (surfaces visible-but-moody, R157):** the backing grain + wall masonry read at rest, yet both stay
  darker than the parchments/frame; the notices still pop.

## Files touched (all client)

`assets/ui/gen_heraldry.py` (crest size/stroke/SS), `assets/ui/gen_parch_v1.py` (foxing/jitter down),
possibly `assets/ui/gen_detail.py` / `gen_emblems.py` (decay/seal/tack detail + crispness),
`scripts/ui/board_decor.gd` (crest NEAREST + size; banner length/placement),
`scripts/main.gd` (`_notice_placard` single line; `_surface_material` args for wall/backing; `_add_decay`),
`scripts/ui/board_geometry.gd` (`placard_rect` single-line; `TOP_RESERVE_FRAC`; maybe vignette ease),
`assets/ui/board_surface.gdshader` (if ambient defaults move). Re-authored PNGs re-imported headless.
**No server/shared files.** The carved **frame** (`frame_v1*`) is deliberately **not touched**.

## Superseded / notes

- TD-049's two-line title + 82×72 crest are re-tuned (single line + smaller crisp crest). The heraldry
  DESIGN (sword+laurel+ring+filigree, iron-cornered nameplate) is kept.
- TD-048's dungeon-dark is **partially** walked back for the **backing + wall only** (R157); the frame's
  restored colour, the parchment floor, and the near-zero fire cast all stand.
- Generator gotcha carries over: run generators FROM `client/assets/ui/`.
