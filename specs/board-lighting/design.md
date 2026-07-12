# Design — Board Dynamic Lighting v1

> Satisfies R129–R135. **Client render only** (I1/I2): no server/shared/wire change. Extends
> the existing `board_decor.gd` torch rig and the `_build_contract_board` surface nodes; adds
> two generators (normals, sconce), one shader, and swaps three surfaces to `CanvasTexture`.
> Canon: hand-painted raster + in-engine lighting (TD-043/TD-046).

---

## Background — why hybrid (normal map + `light()` shader), not a bare shader

Godot's 2D renderer already performs **normal-mapped per-light shading**: give a `CanvasItem`
a `CanvasTexture` with a `normal_texture`, and every `Light2D` in range lights it with correct
directional relief, attenuation, and colour — for free, batched, mobile-supported. A hand-
rolled fragment shader that samples a light position/colour uniform merely **reimplements** that
(and must be kept in sync with the light rig). So the base is **normal map + Light2D**. The
**shader** is then a *thin* `light()` override that adds only what Light2D can't: a stylised
**ember rim** and a **warm push**, reading the light **natively** (`LIGHT_COLOR`,
`LIGHT_ENERGY`, `NORMAL`) so it can never desync from the rig. That is the user's **hybrid**,
and it is the industry-standard layering (engine lighting + a stylisation pass).

## Phase A — Normal-mapped surfaces

### Assets — `client/assets/ui/gen_normals.py` (new, imports `ashember`)

Emits neutral diffuse + normal maps; new PNGs imported via `godot --headless … --import`
([[godot-new-png-import]] verified this works).

- **`frame_v1.png` → re-authored NEUTRAL** (this file is edited, per the locked scope): sample
  the existing painted frame, **desaturate + flatten** toward a mid neutral warm-grey wood
  (kill the baked highlight/hotspot so no direction is pre-lit), keep the plank/carve texture as
  value detail. Save over `frame_v1.png` (the old warm one is replaced; the light re-warms it).
- **`frame_v1_n.png`** — a normal map from an authored **height field** for the 9-slice: raised
  outer bevel + raised inner bevel + a recessed channel between, iron-stud bumps at corners.
  Height → normal via Sobel (`n = normalize(-dH/dx, -dH/dy, k)`), packed to `(0.5*n+0.5)` RGB,
  blue up. A hand-shaped height (not luminance-derived) gives clean rails that rake convincingly.
- **`backing_v1_n.png`**, **`wall_v1_n.png`** — normals **derived from each diffuse's luminance**
  (bump-from-diffuse: height = blurred luma, Sobel → normal), flattened (low strength `k` high)
  so planks/bricks get gentle relief without noise. Diffuse art **unchanged**.

Normal-map convention: tangent-space, **+Y up in texture = toward top of screen**; verify sign
against Godot's expectation (flip G if the light rakes the wrong way — checked in V1).

### Wiring — `main.gd` `_build_contract_board` + `board_decor.gd`

A `CanvasTexture` per surface carries diffuse + normal:

```gdscript
func _canvas_tex(diffuse: Texture2D, normal: Texture2D) -> CanvasTexture:
    var ct := CanvasTexture.new()
    ct.diffuse_texture = diffuse
    ct.normal_texture = normal
    ct.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    return ct
```

- **Frame:** today a `StyleBoxTexture` in a `PanelContainer`. StyleBox normal-map support is
  unreliable, so the frame becomes a **`NinePatchRect`** whose `.texture` is the frame
  `CanvasTexture` (patch margins = the old 9-slice), drawn as the board's border layer; the
  `PanelContainer` keeps only a transparent/again-empty box. (The popup's *station* skin is
  unaffected — only the Contract Board path swaps.)
- **Backing:** already a `NinePatchRect` — set `.texture` to its `CanvasTexture`; drop the
  hard `modulate` brightening (the light now supplies brightness) to a gentle tint.
- **Wall:** the `_stone_bg` `TextureRect` — set `.texture` to its `CanvasTexture`.

For a `Light2D` to light these Controls, they must share the light's canvas (they do — all under
`layer`) and `light_mask`/`range_item_cull_mask` overlap (defaults do). The torch
`PointLight2D` already lives on `_stone_bg`; its **range** must cover the surround (texture_scale
already boosted; tune in V1).

### Light rig source of truth (R133/P72)

`board_decor.add_torches` computes, per torch, one `Torch = { pos: Vector2, color: Color,
energy: float }`. It drives: (1) the `PointLight2D` (`position`, `color`, `energy`, and the
flicker tween on `energy`); (2) the particle emitter `position`; (3) the light shader **reads the
same `PointLight2D` natively** via `light()`, so there is nothing to sync. One rig, three readers.

## Phase B — the `light()` shader (`client/assets/ui/board_surface.gdshader`, new)

A `canvas_item` shader assigned (as a `ShaderMaterial`) to the frame NinePatch (and optionally
backing/wall). It leaves `fragment()` to sample the diffuse+normal (default), and overrides
`light()` to add an ember rim + warmth:

```glsl
shader_type canvas_item;
render_mode blend_mix;

uniform float rim_strength : hint_range(0.0, 2.0) = 0.9;
uniform float warm_amount  : hint_range(0.0, 1.0) = 0.5;
uniform vec3  ember : source_color = vec3(1.0, 0.62, 0.30);

void light() {
    // Godot supplies NORMAL (from the normal map), LIGHT_COLOR, LIGHT_ENERGY, LIGHT (the
    // light's texel), and the attenuation via LIGHT_COLOR.a.
    float ndl   = clamp(dot(normalize(NORMAL.xy), vec2(0.0, -1.0)) * 0.5 + 0.5, 0.0, 1.0);
    vec3  base  = LIGHT_COLOR.rgb * COLOR.rgb;               // standard lit term
    float rim   = pow(ndl, 3.0) * rim_strength * LIGHT_ENERGY;
    vec3  warm  = mix(base, ember, warm_amount * LIGHT_ENERGY * LIGHT_COLOR.a);
    LIGHT = vec4(warm + ember * rim * LIGHT_COLOR.a, LIGHT_COLOR.a);
}
```

(Exact math tuned in V2 — the intent: edges facing the flame gain a warm rim that falls off with
the light's own attenuation, so it can never out-run the light's reach.) The shader **degrades
gracefully**: if a `light()` compile fails on some driver, the surface still shows the default
normal-mapped Light2D result (the material can be dropped at runtime on shader error).

**Heat-haze (stretch, R130 AC, may defer):** a second tiny `canvas_item` shader on a thin quad
just above each flame, wobbling `SCREEN_UV` sample by a time-scrolled noise, `amount` → 0 under
reduced motion. Deferred if it hurts legibility or won't capture cleanly.

## Phase C — particle fire + sconce

### `torch_flame` → CPUParticles2D (`board_decor.gd`)

Replace the 4-frame `AnimatedSprite2D` with a `CPUParticles2D` at the cup:

```gdscript
var fire := CPUParticles2D.new()
fire.amount = 22
fire.lifetime = 0.55
fire.local_coords = false
fire.texture = load("res://assets/ui/spark.png")     # small soft dot (generated) or torch_glow
fire.material = BoardGeo.additive_material()          # ADD blend
fire.direction = Vector2(0, -1)
fire.gravity = Vector2(0, -60)                         # rise
fire.initial_velocity_min = 18; fire.initial_velocity_max = 34
fire.spread = 16.0
fire.scale_amount_min = 0.5; fire.scale_amount_max = 1.1
fire.scale_amount_curve = <grow-then-shrink Curve>
fire.color_ramp = <ember #F9DCA6 → #E8973C → smoke fade a=0 Gradient>
fire.angular_velocity_min/max, fire.damping, fire.tangential_accel  # turbulence → flicker
```

- **Flicker** = per-particle velocity/scale/lifetime variance + a slow randomised
  `tangential_accel`, plus the sympathetic **light energy tween** (already in the rig). No manual
  frame loop, so no visible period.
- **Reduced motion (P73):** when `_reduced_motion`, DON'T emit particles — draw a **static flame
  sprite** (the old frame-0 look, or a single steady `CPUParticles2D` with `speed_scale`
  preprocessed then paused) and **pin the light to peak**. Clean, deterministic, capture-stable.
- `spark.png`: a tiny (8×8) soft round grayscale-additive dot from a generator (or reuse a
  cropped `torch_glow`). White+alpha, tinted by the color ramp.

### Redesigned sconce — `gen_emblems.py` (extend) → `torch_sconce.png`

A redrawn iron T-bracket: a wall plate + two arms cupping a bowl, hand-painted raster, **lit
top-left** to match the board. Emitter seats at the bowl lip (`cup_y`), stem/plate below. Import
headless. (Kept small; the flame is the hero.)

## Phase D — Diegetic props (parchments lit; banner redesigned+lit; backing darker; crest/placard restyled, not lit)

### Parchments lit + legibility floor (R136 / P75)

The notices and the reader sheet already sit under `layer` with the torch `PointLight2D`s, so
they **receive the light for free** once the light rig reaches the board centre. Design:
- **No per-sheet normal map** — paper is near-flat; the warm falloff + the TD-046 curl/drop-shadow
  carry the relief. (A single shared, very-gentle paper normal is an option if the flat light reads
  too even; default is none.)
- **Legibility floor (P75):** dynamic light may only *add* warmth. Guarantee readability two ways
  together: (1) an **ambient fill** — a dim, cool `DirectionalLight2D` (or a low-energy full-board
  `PointLight2D`) so no parchment is ever below the live-tone floor; (2) the ink Labels are drawn
  **on top, unlit** (Controls' text isn't normal-mapped), so text contrast is set by the ink colour,
  not the light. Verified by measuring the **worst-lit** notice off a capture (V7). This preserves the
  notice-board T145 contrast floor under the new lighting.
- The vignette (TD-046) stays but is **eased** where it would fight the floor at the board's centre.

### Backing darker (R137)

`gen_normals.py` (or `gen_structure.py`) re-authors `backing_v1.png` to a **deeper, lower-value**
aged plank. In `_build_contract_board`, **drop the hard `modulate = Color(2.7,2.5,3.1)`** to a gentle
tint (~`1.0`); the Phase-A torch light now supplies brightness near the flames. Keep the wood-grain
overlay. Net: a deep board with warm pools, parchments popping.

### Banner redesign + lit (R138)

`gen_banner.py` (new, or a `gen_emblems.py` addition) authors `banner_v1.png` fresh: a tall, narrow
**frayed blood-crimson tapestry**, hand-painted raster — torn/deckled bottom, subtle vertical drape
folds as **value** (light-agnostic), **plain** (no emblem). This **regenerates away the stray-pixel
defect** (no patching). A companion `banner_v1_n.png` normal encodes the drape folds so the adjacent
torch **rakes** the cloth (warm on the fire side, folds shadowing away). Rendered as a `Sprite2D` with
a `CanvasTexture` (diffuse+normal), lit by the same rig; the mount (rod+nails+contact shadow) is kept.

### Crest + placard: restyle + recolour, NOT lit (R139/R140 / P77)

The torches (bottom flanks, ~200px throw) do not reach the top-center — **user ruling: don't fake it.**
So `crest_v1.png` and `board_placard.png` are **re-authored for style/colour only**, tonally matched to
the board's raster set, and carry **no normal map and no `ShaderMaterial`** — they sit in the top's
honest ambient dim (canon "lit, not evenly bright"). A **faint baked gilt self-highlight** may be drawn
into the diffuse so the eye still catches them, but nothing dynamic. `crest`: consistent bronze medallion
(Origin-neutral Collegium sigil) keeping its TD-046 mounted cast shadow; `placard`: consistent routed
plaque, Godot draws the gilt title over it.

### Consistency (R141 / P78)

One raster register across every board surface; one light rig for every LIT prop (surround + parchments
+ banner); crest + placard the two documented un-lit exceptions. Decor stays low-contrast so gilt still
leads the eye to headline/target/seal.

## Correctness Properties

- **P71 (render-only, R135):** every change is a client node/asset/shader; no `src/server` or
  `src/shared` edit, no wire message, no game-state read/write (I1/I2).
- **P72 (one light rig, R133):** each torch's `{pos,color,energy}` is computed once; the
  Light2D, the particle emitter, and the shader (native `LIGHT_*`) all read it — no second,
  divergable light definition.
- **P73 (reduced motion, R131):** F9/`--reduced-motion` freezes the flame (static sprite) + the
  light (pinned peak) + the shader/haze pulse; the light stays on (load-bearing), only motion
  stops.
- **P74 (capture-verifiable, R134):** the flame and the dynamic frame lighting render in the
  windowed DebugCapture, and the project parses headless with no SCRIPT/shader error — so every
  acceptance is eyeballed against a screenshot, not asserted blind.
- **P75 (legibility floor under light, R136):** at the worst-lit notice position the paper stays ≥
  the live-tone floor and the ink ≥ 4.5:1; dynamic light only adds warmth, never sinks a writ (the
  ambient fill + unlit ink Labels guarantee it).
- **P76 (one rig, all lit props, R133/R141):** the surround, parchments, and banner all read the
  single per-torch `{pos,color,energy}`; no lit prop invents its own light.
- **P77 (honest reach, R139/R140):** crest + placard are NOT given a light they don't receive — they
  carry no normal/shader and sit in the top's ambient dim (no faked top hotspot).
- **P78 (one register, R141):** every board surface is the same hand-painted raster style; no prop is
  left in a foreign look.

## Assets & files touched (all client)

New: `assets/ui/gen_normals.py`, `frame_v1_n.png`, `backing_v1_n.png`, `wall_v1_n.png`,
`spark.png`, `board_surface.gdshader` (+ `.import`s). Edited: `frame_v1.png` (neutralised),
`gen_emblems.py` (sconce), `board_decor.gd` (rig + particles + sconce + lights),
`board_geometry.gd` (maybe a `canvas_tex` helper), `main.gd` `_build_contract_board` (frame →
NinePatch CanvasTexture, backing/wall CanvasTextures). **No server/shared files.**

## Superseded / notes

- The 4-frame `torch_flame.png` sprite sheet is retired for the board (kept only if the reduced-
  motion fallback reuses frame 0). The baked warm `frame_v1.png` is replaced by the neutral one
  (the warm look now comes from the torches). The earlier "don't touch the frame" note is
  **explicitly lifted for lighting** by the user (2026-07-12) — logged in DECISION_LOG TD-047.
