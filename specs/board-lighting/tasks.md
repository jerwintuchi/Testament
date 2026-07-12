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

- [ ] T150 [R130 / P71, P72] — **Ember-rim `light()` shader.** New
      `client/assets/ui/board_surface.gdshader` (`canvas_item`, `light()` override: rim +
      warm-to-ember, scaled by `LIGHT_ENERGY`/attenuation, native `LIGHT_*` — no manual uniform).
      Assign a `ShaderMaterial` to the frame NinePatch (+ backing/wall if it reads well). Guard:
      drop the material on shader error (graceful degrade).
      Verify: **V2** — capture shows a warm ember rim on the frame's flame-facing edges cooling
      with distance; run log has no shader-compile error.

- [ ] T151 [R130] — **(Stretch) heat-haze** quad above each flame (time-scrolled UV wobble),
      amount→0 under reduced motion. **Deferrable**: skip if it costs legibility or capture
      clarity; record the call.
      Verify: capture shows subtle shimmer above the flame only; reduced-motion capture is steady.

## Phase C — Particle fire + sconce

- [ ] T152 [R132] — **Redesigned raster sconce.** Extend `gen_emblems.py` → a redrawn iron
      `torch_sconce.png` (wall plate + bowl, top-left key). Headless-import; seat the emitter at
      the bowl.
      Verify: **V4** — capture shows the new sconce holding the flame at its cup.

- [ ] T153 [R131, R133, R134 / P73, P74] — **CPUParticles2D flame + flicker.** Replace the
      4-frame `AnimatedSprite2D` with a `CPUParticles2D` at the cup (rise+taper, ember→smoke ramp,
      additive, turbulence/scale variance for flicker); add `spark.png` (tiny soft additive dot);
      the rig's light energy flickers in sympathy. **Reduced motion (F9/`--reduced-motion`):**
      static flame + pinned-peak light.
      Verify: **V3** — capture shows the particle flame; two captures ~0.3s apart differ (live
      flicker); the light moves with it. **V5** — `--reduced-motion` capture is steady.

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

## Cross-cutting

- [ ] T154 [R129–R141 / P71–P78] — **Verification pass.** Run `specs/board-lighting/playtest.md`
      (**V1–V10**) on a worst-case seed via the DebugCapture pipeline, incl. `--reduced-motion`; fix any
      GDScript/shader errors; confirm **no server/shared file changed** and the server + shared
      Vitest suites are still green (untouched); `--headless` parses clean.
      Verify: V1–V10 green; `git diff --name-only` shows only client paths; MCP/headless clean.

## Notes

- The 4-frame `torch_flame.png` is retired for the board (kept only if the reduced-motion fallback
  reuses frame 0). `frame_v1.png` is replaced by its neutral re-author (warmth now comes from the
  torches). Normal-map sign (G channel) is verified in V1 — flip if the rake is inverted.
- If `CanvasTexture` normal-mapping does not light a `NinePatchRect`/`TextureRect` `Control` as
  expected on this Godot build (a known 2D-lighting-on-Control caveat), fall back per-surface to a
  `Sprite2D`/`TextureRect` with an explicit `NORMAL`-sampling `canvas_item` shader (still the
  hybrid, just self-sampled) — record the pivot in the DECISION_LOG. This is the one real
  technical risk; T149's V1 is the go/no-go gate.
