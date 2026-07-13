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

- [x] T155 [R137] — **Darker backing.** Satisfied by the TD-048 dungeon re-grade: `backing_v1.png`
      already reads deep (native meanV≈22), the hard `modulate = Color(2.7,2.5,3.1)` was **already
      dropped to `Color(1,1,1)`**, and T161 pulled the shader `diffuse_gain` back to 1.1 (no wash). The
      grain overlay + T148 normal map are kept.
      **Done** — **V8 green**: the capture shows a deep board with the parchments popping; no re-author
      needed (the re-grade delivered the deeper key R137 asked for).

- [x] T156 [R136 / P75] — **Parchment legibility floor.** Reconciled with TD-048: the parchments are
      **unlit baked paper** (no dynamic rig lighting — that would fight the near-zero cast), so the floor
      is met by **lifting the paper itself**. `gen_parch_v1.py` gains a `LIFT` (×1.6) that raises the dim
      v1 painted paper **partway** toward the live tone (the user's ruling: readable, keep aged warmth —
      NOT full cream); the vignette (`board_geometry.vignette_gradient`) is **eased** (dark ring pushed
      0.66→0.78, α 0.42→0.30) so outer notices aren't sunk; ink Labels stay unlit on top.
      **Done** — **V7 green** (measured off the capture, worst-lit notices): paper lands at **lum ≈0.27–0.29**
      (warm aged tan, short of the 0.47 cream floor by design) with **ink ≈4.8–5.1:1** at every worst-lit
      (farthest-from-torch) notice — comfortably above the 4.5 floor. (Supersedes R136's "lit by the rig +
      ambient fill" for the dungeon-dark grade; the floor now lives in the asset, not fragile lighting.)

- [x] T157 [R138 / P76] — **Banner redesign.** New `gen_banner.py` authors `banner_v1.png` fresh —
      a plain frayed blood-crimson tapestry: three soft vertical fold-drapes as VALUE, a torn/deckled
      hem, smooth low-freq age variation (the first cut's `x//8,y//10` worn-patches read as blocky
      rectangles — the very defect being removed — replaced by overlapping sines), and a warm glow
      baked into the lower hem where the sconce burns at the banner's foot. No emblem, no stray pixels.
      `board_decor` modulate lifted (0.46,0.15,0.15 → 0.90,0.86,0.86) so the baked crimson reads.
      **Adaptation (TD-048):** per the dungeon-dark grade the fold relief + torch warmth are BAKED into
      the diffuse (the banner is a plain `Sprite2D`); **no companion `banner_v1_n.png` / dynamic rake**
      is wired — a dynamic light on the banner would fight the near-zero cast, and the baked value reads
      the drape against the near-black board. (Supersedes R138's "cloth normal + lit by the rig".)
      **Done** — **V9 green**: pixel-scan finds **0** stray dark specks (vs the corrupted proto slice);
      the capture shows a clean crimson drape with a warm hem by the flame.

- [x] T158 [R139 / P77, P78] — **Crest regenerated (NOT lit).** Re-authored `crest_v1.png` as a
      generated bronze oval medallion (`gen_emblems.make_crest`), replacing the proto slice + its
      Origin-suggestive **cross** with an **Origin-neutral RADIANT STAR** (illumination / the Watcher /
      "we seek truth" — deliberately not the eye/inverted-cross/diamond of Belief/Sin/Relic). Domed
      bronze lit top-left, debossed sigil with a lit far lip, a raised rim bevel so it reads MOUNTED;
      **darkened key** so it sits in the top's ambient dim (first cut read as a pale floating pebble).
      `board_crest` still draws the cast shadow. No normal, no shader. Headless-imported.
      **Done** — part of **V10 green**: the crest matches the register and sits in the ambient dim.

- [x] T159 [R140 / P77, P78] — **Placard regenerated (NOT lit).** Re-authored `board_placard.png`
      (`gen_structure.placard_px`): **deepened field** (lerp WOOD_DEEP↔WOOD_EDGE) + a **carved inner lip**
      so the Godot-drawn gilt title pops harder against the dungeon-dark key; kept the gold-lined groove +
      brass nails. Also **removed `torch_sconce.png` from `gen_structure`'s jobs** (gen_emblems owns the
      redrawn sconce now — a full gen_structure run no longer clobbers it). No normal, no shader.
      **Done** — part of **V10 green**: the placard matches the register, ambient dim, gilt title reads.

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
