# Tasks — Board Dynamic Lighting v1

> T# continues global from T147 (notice-board Pass-2). Client-only; each task names its
> capture/headless verification (no GDScript unit harness — client-spec convention). Order is
> dependency + phase order (A→C), each phase independently reviewable. Nothing is "done" without
> its named verification passing. Trust boundary: render only (I1/I2) — no server/shared edits.

## Phase A — Normal-mapped surfaces

- [x] T148 [R129, R134 / P74] — **Normal-map generator.** New `client/assets/ui/gen_normals.py`
      (imports `pngio` read + `ashember` write, stdlib): re-authors `frame_v1.png` NEUTRAL
      (desaturate/flatten, kill baked highlight; original kept as `_frame_v1_src.png` for
      idempotence) + emits `frame_v1_n.png` (luminance→Sobel normal, strength 8), `backing_v1_n.png`
      + `wall_v1_n.png` (strength 4). Headless-imported. **Done** — 4 PNGs written, `--headless`
      parse clean.

- [x] T149 [R129, R133 / P72] — **Light rig + surface lighting. PIVOTED to a shader (go/no-go
      resolved).** The gate finding: **Godot Light2D does NOT reach these Control nodes** — a
      torch `PointLight2D` cranked to energy 8 / scale 7 changed the render by (0,1), i.e. nothing;
      the "torch glow" was always the additive sprites. So per the spec's flagged fallback, lighting
      is done by a **`canvas_item` fragment shader** (`assets/ui/board_surface.gdshader`) that
      samples the normal map + **uniform torch lights** (no Light2D dependency). One rig
      (`BoardDecor.torch_rig`, SCREEN_UV space) feeds every surface (P72). Frame → shader-lit
      `NinePatchRect` overlay tracking the popup rect (a StyleBox can't hold a material; an in-canvas
      frame is clipped by the ScrollContainer); backing (NinePatch) + wall (TextureRect) → shader
      material; dead `PointLight2D` removed. The dark `backing_v1` is pre-lifted in-shader
      (`diffuse_gain`). **Done** — **V1 passes**: lit rakes warm relief across frame/backing/wall,
      `--lights-off` (now zeroes the shader `light_count`) shows flat neutral wood (measured diff
      (0,213) vs the PointLight2D's (0,1)). 9-slicing preserved under the shader (verified on
      backing + frame).

## Phase B — Hybrid light shader

- [x] T150 [R130 / P71, P72] — **Ember-rim + warm-ambient tuning (uniform-based, per the T149
      pivot).** The spec's `light()`-override wording is pre-pivot: Light2D never reaches these
      Control nodes, so there is no native `LIGHT_*` to hook — the ember rim + warmth live in
      `board_surface.gdshader`'s **uniforms/fragment**, driven by the one torch rig (P72). Done:
      the rim term (`ember * pow(ndl,3) * rim_strength * atten`) already glows the flame-facing
      edges and cools with `atten`; Phase B **fixed the "pale-grey where the light doesn't reach"
      symptom** — added a warm `ambient_tint` so unlit wood reads as dim warm wood not cold silver,
      and swapped the hard linear-clamp falloff for a `smoothstep` shoulder + a taller torch reach
      (`radius` 0.62→0.74) so the warm pool climbs the board smoothly instead of cutting to grey
      mid-frame. **V2 green** — lit capture shows the warm ember gradient/rim on the flame-facing
      frame edges cooling with distance and the whole surround reading as warm torchlit wood; the
      `--lights-off` capture collapses to flat uniform dim wood (relief/warmth gone → the shader,
      not the diffuse, does the work — V1 still holds); no shader-compile error in either run.

- [ ] T151 [R130] — **(Stretch) heat-haze** quad above each flame (time-scrolled UV wobble),
      amount→0 under reduced motion. **Deferrable**: skip if it costs legibility or capture
      clarity; record the call.
      Verify: capture shows subtle shimmer above the flame only; reduced-motion capture is steady.

## Phase C — Particle fire + sconce

- [x] T152 [R132] — **Redesigned raster sconce.** Extended `gen_emblems.py` (`make_sconce` +
      `_seg_cov`) → a redrawn iron `torch_sconce.png` (12×20, bowl/cup + thick post + wall-plate
      foot, top-left key). Re-graded DUNGEON-DARK to match TD-048: near-black **warm-neutral** iron
      (firelit iron catches ember, not steel-blue — the first cut read as a pale bluish martini
      glass) with only a faint warm rim on the up-left lip and a warm ember cavity at the cup.
      Headless-imported; the emitter seats at the bowl (`board_decor` `cup_y - 2.0`).
      **Done** — **V4 green**: the capture shows a dim iron cup holding the flame, dark below, cast
      contained.

- [x] T153 [R131, R133, R134 / P73, P74] — **CPUParticles2D flame + flicker.** Replaced the
      4-frame `AnimatedSprite2D` with a `CPUParticles2D` at the cup (`torch_flame`): rectangle
      emission (bowl-width), buoyant rise (`gravity y -60`), grow-then-shrink `scale_amount_curve`,
      ember→smoke `color_ramp`, additive blend, and velocity/scale/lifetime variance +
      `tangential_accel ±18` for organic flicker (no visible loop). Added `spark.png` (8×8 soft
      additive dot). The sympathetic glow flicker + peak-pin already live in `add_torches` (T162).
      **Reduced motion (`--reduced-motion`):** `_static_flame` returns the frozen frame-0 sprite,
      seated at the cup; glow pinned by the caller.
      **Done** — **V3 green**: particle flame renders; two captures ~0.3s apart differ (mean-diff
      1.52 over the flame region → live flicker). **V5 green**: `--reduced-motion` capture is a
      steady static flame + pinned glow. Headless parse clean, no SCRIPT/shader error.

## Phase D — Diegetic props (parchments lit; banner redesign+lit; backing darker; crest/placard restyle)

- [ ] T155 [R137] — **Darker backing.** Re-author `backing_v1.png` deeper/lower-value (in
      `gen_normals.py`/`gen_structure.py`); in `_build_contract_board` drop the hard
      `modulate = Color(2.7,2.5,3.1)` to a gentle tint so the Phase-A light supplies brightness; keep
      the grain overlay + the T148 normal map.
      Verify: **V8** — capture shows a deeper backing, parchments popping, near-torch planks lifting warm.

- [ ] T156 [R136 / P75] — **Parchments lit + legibility floor.** Ensure the torch rig reaches the
      board centre so notices/reader catch warm falloff; add the **ambient fill** (dim cool
      DirectionalLight2D / low full-board light) + ease the centre vignette so no writ drops below the
      floor; keep ink Labels unlit on top.
      Verify: **V7** — near-torch writ warmer than far; worst-lit notice paper ≥ floor and ink ≥ 4.5:1
      (measured off capture, worst-case seed).

- [ ] T157 [R138 / P76] — **Banner redesign + lit.** New `gen_banner.py` (or `gen_emblems.py` add):
      author `banner_v1.png` fresh (frayed crimson tapestry, plain, folds-as-value, no stray pixels) +
      `banner_v1_n.png` normal (drape folds). Render as `Sprite2D` w/ `CanvasTexture`, lit by the rig;
      keep the mount. Headless-import.
      Verify: **V9** — capture shows the flame raking the folds; a pixel-scan finds no off-register cluster.

- [ ] T158 [R139 / P77, P78] — **Crest restyle + recolour (NOT lit).** Re-author `crest_v1.png` as a
      consistent raster bronze medallion (Origin-neutral sigil), tonally matched, faint baked gilt
      self-highlight, keep the mounted cast shadow. No normal, no shader. Headless-import.
      Verify: part of **V10** — crest matches the register, sits in ambient dim.

- [ ] T159 [R140 / P77, P78] — **Placard restyle + recolour (NOT lit).** Re-author `board_placard.png`
      as a consistent routed raster plaque (Godot draws gilt title over it), tonally matched. No normal,
      no shader. Headless-import.
      Verify: part of **V10** — placard matches the register, ambient dim.

## Phase B-2 — Lighting Restraint (dungeon-dark re-grade, TD-048)

> Supersedes the T150 grade. A re-tune + one asset re-author; no new shader machinery. Order:
> T160 (restore frame colour) → T161 (shader restraint) → T162 (fire-sprite restraint), each
> capture-verified, then folded into the T154 verification pass.

- [x] T160 [R143 / P80] — **Restore the frame's baked colour.** In `gen_normals.py`, re-author
      `frame_v1.png` **from the preserved `_frame_v1_src.png`** (carved warm wood, its own hue baked
      in; optionally value-darkened for the dungeon key) instead of neutralising it; keep
      `frame_v1_n.png`. Headless-import.
      **Done** — `_neutral_frame_pixel` replaced by `_restore_frame_pixel` (per-channel scale keeps the
      wood hue; highlights >mid compressed ×0.65 so no baked hotspot reads as a fake light; ×0.82 darken
      for the dungeon key); `frame_v1_n.png` unchanged (regen from same source is deterministic).
      `python3 gen_normals.py` clean; headless-reimported; `--lights-off` capture shows the frame as
      coloured carved warm wood (own hue present), not neutral grey (part of V11).

- [x] T161 [R142, R144 / P79, P81] — **Shader restraint (dungeon-dark).** Retire/neutralise the
      Phase-B warm `ambient_tint` (cool/low dungeon fill); pull `gain` down, the `torch_rig` radius
      in (from 0.74 → tight cup halo), the `light_col` energy down; drop the backing `diffuse_gain`
      toward ~1.0 so the planks read their own deep colour. Keep the low `ambient` floor so material
      whispers; one rig still feeds every surface (P72).
      **Done** — shader defaults: `ambient_tint` → faint-cool `(0.82,0.85,0.95)`, `gain` 1.7→0.7,
      `rim_strength` 0.7→0.35, `ambient` 0.42→0.40; `torch_rig` radius 0.74→0.24; `light_col.a`
      (energy) 1.35→0.9; per-surface ambient/diffuse_gain — frame `(0.40,1.0)`, backing `(0.42,1.1)`
      (was 2.6 wash), wall `(0.30,1.0)`. **V11 green** — lit capture reads deep dungeon-dark: surround
      near-black with the carved-wood colour whispering, only a tight per-sconce lift, orange wash gone;
      the lit-vs-`--lights-off` delta is now small + local (superseding V1's global delta, by design).

- [x] T162 [R145, R146 / P81, P73] — **Fire-sprite restraint.** In `board_decor.gd add_torches`,
      shrink-hard-or-drop the broad gutter `wash` sprite and reduce the cup `glow` to a small dim halo
      (near-zero board throw); flame stays alive; `--reduced-motion` still freezes flame + pins the dim
      light.
      **Done** — the board-wide gutter `wash` sprite (`torch_glow` @3.4×3.9) is **dropped**; the cup
      `glow` shrunk 1.35×1.5→0.7×0.78 and dimmed α0.52→0.28 (flicker 0.34↔0.22). **V12 green** — the
      flame stays alive with near-zero cast (a tight dim halo, no board bloom); `--reduced-motion`
      capture is steady with the glow pinned to peak (P73). No shader/SCRIPT error; headless parse clean.

## Cross-cutting

- [ ] T154 [R129–R146 / P71–P81] — **Verification pass.** Run `specs/board-lighting/playtest.md`
      (**V1–V13**) on a worst-case seed via the DebugCapture pipeline, incl. `--reduced-motion`; fix any
      GDScript/shader errors; confirm **no server/shared file changed** and the server + shared
      Vitest suites are still green (untouched); `--headless` parses clean. (V11 supersedes V1's global
      lights-off delta with the small local one; re-baseline captures.)
      Verify: V1–V13 green; `git diff --name-only` shows only client paths; MCP/headless clean.

## Notes

- The 4-frame `torch_flame.png` is retired for the board (kept only if the reduced-motion fallback
  reuses frame 0). `frame_v1.png` is replaced by its neutral re-author (warmth now comes from the
  torches). Normal-map sign (G channel) is verified in V1 — flip if the rake is inverted.
- If `CanvasTexture` normal-mapping does not light a `NinePatchRect`/`TextureRect` `Control` as
  expected on this Godot build (a known 2D-lighting-on-Control caveat), fall back per-surface to a
  `Sprite2D`/`TextureRect` with an explicit `NORMAL`-sampling `canvas_item` shader (still the
  hybrid, just self-sampled) — record the pivot in the DECISION_LOG. This is the one real
  technical risk; T149's V1 is the go/no-go gate.
