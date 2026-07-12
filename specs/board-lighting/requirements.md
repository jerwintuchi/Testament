# Requirements — Board Dynamic Lighting v1 (normal-mapped surfaces + light shader + particle fire)

> Phase 5, visual. Turns the Contract Board's lighting from **baked/static** into
> **dynamic**: the wooden surround (frame, backing, wall) is a set of **normal-mapped**
> surfaces lit by the torch `PointLight2D`s, so recolouring and firelight fall out of the
> light — not painted into the diffuse. A **custom `light()` canvas shader** adds an ember
> rim/warmth beyond flat Light2D (the user's chosen **hybrid**). The sconce fire is
> redesigned as a **CPUParticles2D** flame with flicker, and the iron **sconce** is a
> redrawn hand-painted raster prop.
>
> **Decisions locked by the user (2026-07-12), do not re-litigate:**
> - Lighting technique = **hybrid**: normal map (relief) **+** a light-driven shader
>   (ember rim / warmth). Justified over a bare custom shader because Godot's 2D renderer
>   already does normal-mapped lighting natively, so relief + colour come from the existing
>   torch lights for free; the shader adds only what Light2D can't (a stylised ember rim).
> - Fire = **CPUParticles2D** (renders in the capture pipeline so it's eyeball-verifiable;
>   portable to mobile, TD-042). GPU particles were declined for capture/mobile risk.
> - Scope = **frame + backing + wall** all react to torchlight. `wall_v1`/`backing_v1` keep
>   their painted diffuse (art unchanged); `frame_v1` is **re-authored NEUTRAL** so the light
>   supplies its colour. This **explicitly authorises editing `frame_v1`** for lighting —
>   superseding the earlier "don't redesign the wall/frame" note, for lighting only.
>
> Numbering continues global: **R129+**, correctness **P71+**, tasks **T148+**. Trust
> boundary unchanged — this is **client render only** (I1/I2): no server/shared change, no
> game state, no wire change. Canon: hand-painted raster 2D pixel art, in-engine lighting a
> pillar (DECISION_LOG TD-043/TD-046).

---

## Phase A — Normal-mapped surfaces (relief lit by the torches)

**R129** (client): the frame, backing, and wall are **normal-mapped** and lit by the
existing torch `PointLight2D`s, instead of carrying baked directional light.
- AC: each surface renders through a **`CanvasTexture`** carrying a `diffuse_texture` +
  `normal_texture`, so Godot's 2D renderer applies per-light normal-mapped shading from the
  torches (the carved bevels catch warm light on the torch-facing side, shade away from it).
- AC: **`frame_v1.png` is re-authored to a NEUTRAL** desaturated mid-wood diffuse (no baked
  highlight/hotspot), so the light — not the texture — supplies colour and directional
  shading; its companion `frame_v1_n.png` normal encodes the 9-slice carved relief (raised
  outer/inner rails, recessed channel).
- AC: **`wall_v1.png` and `backing_v1.png` keep their painted diffuse unchanged**; each
  gains a companion `*_n.png` normal (derived from its own height/luminance) so it too takes
  relief lighting. No art redesign of wall/backing.
- AC: with the torches present the surround reads as **lit from the flames** (a visible warm
  gradient falling off with distance from each torch); with the torch lights removed it reads
  as flat neutral wood (proving the light is doing the work, not the diffuse).

**R133** (client): there is **one canonical light rig per torch** feeding every consumer.
- AC: each torch owns a single `{position, color, energy}` source of truth; the normal-map
  `PointLight2D`, the shader's light data, and the particle-sympathetic light all derive from
  it — no divergent light positions/energies (P72).

## Phase B — Hybrid light shader (ember rim / warmth)

**R130** (client): a custom **`canvas_item` `light()` shader** on the frame (and the other
surround surfaces) adds an ember rim + warmth beyond default Light2D shading.
- AC: the shader's `light()` processor boosts a **rim highlight** on strongly light-facing
  normals and **warms** the lit result toward the ember ramp, scaled by `LIGHT_ENERGY`, so the
  frame's edges glow warmer nearest a flame and cool with distance.
- AC: it reads the light natively (`LIGHT_COLOR`, `LIGHT_ENERGY`, `NORMAL`) — **no manual
  per-frame uniform** that could desync from the rig (keeps P72 trivially true).
- AC: **render-only** — the shader touches no gameplay data (I1/I2); it degrades gracefully
  (a driver without the shader still shows the normal-mapped Light2D result).
- AC (stretch, may defer): a subtle **heat-haze** UV wobble just above each flame; deferred if
  it costs legibility or capture-verifiability.

## Phase C — Particle fire + redesigned sconce

**R131** (client): the sconce fire is a **CPUParticles2D** flame with flicker, replacing the
4-frame additive sprite sheet (`torch_flame.png`).
- AC: particles emit at the sconce cup, rise + taper, run an **ember→smoke** colour ramp with
  **additive** blend, and use turbulence + per-particle scale/lifetime variance so the flame
  **flickers** organically (no visible looping).
- AC: the torch's `PointLight2D` **energy flickers in sympathy** with the flame from the same
  rig (R133), so light and fire pulse together.
- AC: **reduced motion (F9 / `--reduced-motion`)** freezes the flicker to a **steady** flame +
  **pinned-peak** light (existing accessibility lever; the light stays load-bearing, only the
  pulse stops) (P73).

**R132** (client): the iron **sconce** is redrawn as a hand-painted raster prop (TD-046),
holding the particle flame at its cup.
- AC: a new `torch_sconce.png` authored by a generator, lit top-left to match the board's one
  light convention; the particle emitter seats at its cup, the stem hangs below.

## Phase D — Diegetic props: light where reachable, consistent raster everywhere

> Added 2026-07-12 (user). The surround (Phase A) is not the only board art — the
> parchments, banner, backing, crest, and placard must read as **one consistent
> hand-painted raster set** (TD-046), and the ones the torches actually **reach** must be
> lit by the same rig. The user's ruling on reach: **crest + placard are top-center, out
> of the bottom torches' throw, so they are deliberately NOT lit** (faking it would be
> dishonest) — they are **restyled + recoloured only**. Parchments and the banner **are**
> reached and **are** lit.

**R136** (client): the **contract parchments** (the 8 notices + the reader sheet) are lit by
the torch rig, with a legibility floor.
- AC: each parchment receives the torches' warm falloff — the flame-facing edge warms, the
  far edge cools — from the **same rig** as the surround (R133), so a writ near a torch reads
  visibly warmer than one across the board.
- AC: a **hard legibility floor** holds: an ambient minimum (a low, cool fill light or a
  clamped paper floor) keeps every parchment's paper ≥ the live-tone floor (~`#CBB583`) and its
  **ink ≥ 4.5:1** at the **worst-lit** (farthest-from-torch) position — dynamic light may only
  *add* warmth, never sink a writ into unreadability (P75, heritage of the notice-board T145
  contrast floor).
- AC: parchments carry **no per-sheet normal map** (paper is near-flat; the warm falloff plus
  the existing curl + drop-shadow carry the relief — a normal per sheet is low ROI); the notice
  **text (Labels) stays unlit ink** so legibility is independent of the light.

**R137** (client): the **plank backing** diffuse is re-authored **darker/deeper**.
- AC: `backing_v1.png` becomes a deeper, richer aged wood (lower base value) so the board reads
  with more depth and the lit parchments pop; the hard brightening `modulate` is **dropped** —
  the Phase-A torch light lifts the planks near the flames instead (a deep board with warm pools).
- AC: the wood-grain age overlay (TD-046) is kept; the backing still takes the Phase-A normal map.

**R138** (client): the **banner** is redesigned as clean hand-painted raster and lit.
- AC: `banner_v1.png` is **re-authored** — a weathered, frayed **blood-crimson tapestry**,
  **plain (no emblem)** so it never competes with the crest/seals for the eye; **no stray /
  malformed pixels** (the current one's defect is gone by regeneration, not patching).
- AC: it gains a **cloth normal map** and is lit by the **adjacent** torch (it hangs right by the
  flame → a strong warm rake on the fire side, cooling into the folds away from it), on the one
  rig (R133/P76). The mount (iron rod + nail heads + contact shadow, TD-046) is kept.

**R139** (client): the **crest** is restyled + recoloured to the consistent raster set — **not
lit**.
- AC: `crest_v1.png` is re-authored as a consistent hand-painted raster **bronze medallion**
  (Origin-neutral Collegium sigil), tonally matched to the board; it keeps its mounted cast
  shadow (TD-046). **No normal map, no torch lighting** — it is out of the torches' reach and is
  deliberately left to the top's ambient dim (P77); the gilt may carry a faint baked self-highlight
  so it still catches the eye, but nothing dynamic.

**R140** (client): the **placard** is restyled + recoloured to the consistent raster set — **not
lit**.
- AC: the carved header plaque (`board_placard.png`) is re-authored as a consistent routed raster
  plaque (Godot still draws the gilt title text over it); tonally matched. **No normal map, no
  torch lighting** (same reach ruling as the crest, P77).

## Cross-cutting

**R141** (client): the whole board art is **one consistent hand-painted raster set** on **one
light rig**.
- AC: parchments, banner, backing, wall, frame, crest, placard, seals, badges, tacks all read as
  the same weathered raster register (TD-046); **every LIT prop reads the single per-torch rig**
  (parchments + banner + surround), and **crest + placard are the documented exceptions** (not
  lit) — no prop invents its own light (P76), and no prop is left in a different style (P78).

**R134** (client): the feature is **mobile-safe and capture-verifiable**, no headless
regression.
- AC: CPUParticles2D + `CanvasTexture` normal maps + a lightweight `light()` shader — all in
  the mobile-supported feature set (TD-042); the project parses clean in a **headless** run and
  the flame + dynamic frame lighting **render in the windowed DebugCapture** (so every claim is
  eyeballed, never guessed) (P74).

**R135** (containment, standing I1/I2): nothing here crosses the trust boundary — no
server/shared file changes, no new wire message, no game-state read/write. Behaviour of the
board (select/deselect/deploy) is untouched.

---

## Verification

No GDScript unit harness (client-spec convention). Each requirement is verified by the
**DebugCapture** pipeline + a headless parse, per `specs/board-lighting/playtest.md`:
- **V1 (R129):** capture shows the torches raking relief across frame/backing/wall; a
  lights-off debug toggle shows flat neutral wood (light is doing the work).
- **V2 (R130):** capture shows a warm ember rim on the frame's flame-facing edges, cooling
  with distance; shader compiles (no shader error in the run log).
- **V3 (R131/R133):** capture shows the particle flame; two captures ~0.3s apart differ
  (flicker is live); the sympathetic light moves with it.
- **V4 (R132):** capture shows the redrawn sconce seating the flame at its cup.
- **V5 (R131/P73):** `--reduced-motion` capture shows a steady flame + pinned light.
- **V6 (R134/P74):** `--headless` parses clean (no SCRIPT/shader errors); windowed capture
  renders the flame + lit frame. Server + shared suites remain green (untouched).
- **V7 (R136/P75):** capture shows a parchment near a torch reading warmer than one across the
  board; at the **worst-lit** notice position the paper stays ≥ floor and the ink ≥ 4.5:1
  (measured off the capture, worst-case seed) — dynamic light never sinks a writ.
- **V8 (R137):** capture shows a deeper backing with the parchments popping; near-torch planks
  lift warm (no more flat hard-modulated slab).
- **V9 (R138):** capture shows the redesigned banner (no stray pixels) with the flame raking its
  folds; a pixel-scan of `banner_v1.png` finds no off-register cluster.
- **V10 (R139/R140/R141/P77/P78):** capture shows the restyled crest + placard tonally matched to
  the board (consistent raster), sitting in the top's ambient dim (not dynamically lit); no prop
  is in a foreign style.
