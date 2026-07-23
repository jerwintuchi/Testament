# Requirements — The title screen as a composed, lit scene (TD-073)

> **Supersedes the single-plate approach of TD-072.** That spec tried to produce the title art as
> one procedurally generated PNG. It hit a ceiling, and the ceiling is structural rather than a
> tuning problem: a per-pixel classifier with analytic shapes can only produce perfect symmetry,
> uniform repetition, hard edges and banded falloff. The author's north star is a *painting* — its
> quality comes from thousands of individually judged decisions (asymmetric walls, candles at
> varying heights, censers hanging differently, haze, reflection). No amount of iteration on a
> shape function reaches that.
>
> The canon already said so. TD-057: **"Python owns surfaces… Aseprite owns sprites — anything
> where a pixel is a design decision."** A hero title illustration is the second thing; TD-072 was
> using the surface tool to paint a picture.
>
> **The route (author ruling): a modular scene, lit in-engine** — separate authored assets composed
> as layered sprites in Godot with `Light2D`, normal maps and particles, exactly how the Contract
> Board is built (`frame_v1` + `backing_v1` + `banner_v1` + `torch_*` + `stone_tile`, not one
> baked image). That is also the only route that yields **subtle life** (author ruling): candle
> flicker, slow ember drift, a faint banner sway.
>
> The reference is **mood and composition only** — the author generated it via ChatGPT and holds
> usage rights, but chose to build original art rather than ship the plate.
>
> Client render + generated art. **R241+**, **P128+**, **T255+**. Logged **TD-073**.

---

## R241 — The scene is composed from layers, not baked into one image
- AC: the title backdrop is a **scene tree** of sprites at distinct depths, not a single texture:
  far (shrine/apse), mid (arcade + vault), near (the two flanking piers), plus props — banners,
  censers, candle racks, floor.
- AC: each layer is its **own asset** with its own normal map where it is lit, so Godot's renderer
  does the lighting. Nothing is lit by baked arithmetic alone (bible rule 2, TD-043).
- AC: layer order and placement are **authored** (hand-placed offsets), so the composition can be
  asymmetric — the regularity of the TD-072 plate is a large part of why it read as procedural.

## R242 — The right tool authors each asset (TD-057)
- AC: **Python generators** author the *surfaces*: piers, arcade, vault, floor, banner cloth, and
  every normal map. These are grain, bevel, AO and gradient work.
- AC: **Aseprite** (driven in batch from WSL, per the sanctioned pipeline) authors the *props*
  where a pixel is a design decision: the censer, the candle rack, the shrine device.
- AC: the TD-072 camera is **reused, not discarded** — its one-point projection at hfov 105° /
  pitch 15° is what makes the layers share a perspective. The architecture layers are emitted as
  **depth slices** of that same projection, so far/mid/near line up by construction (P128).

## R243 — Lighting is in-engine and warm
- AC: every visible flame has a **`Light2D`**: candle racks, censers, the shrine. The stone is lit
  by them, not by pre-baked warmth.
- AC: the register is inherited from the board — `navestone` warm ashlar, `flame`/`gold` light,
  `wax` banners — with the same warm-on-cool separation that makes the board's torch halos read.
- AC: no board asset changes (P127 stands).

## R244 — Subtle life (author ruling)
- AC: candle and censer lights **flicker** on a low-amplitude, seeded, non-synchronised cycle.
- AC: slow **ember/dust motes** drift upward through the light (`CPUParticles2D`).
- AC: the banners carry a faint **sway**.
- AC: **reduced motion (F9) freezes all of it** to a static, fully-lit frame — the existing lever
  must keep working, and the screen must lose no information when frozen.

## R245 — It remains a backdrop
- AC: the emblem, title and options stay legible over it; the frame's centre stays comparatively
  quiet.
- AC: the composition holds at the integer scales `PixelScale` produces, and no layer seam is
  visible at any of them.

## R246 (containment): client render + generated art only
- AC: no `src/**` change, no wire change; asset-map regenerated; suites green.

---

## Correctness Properties

- **P128 (one camera, many layers):** every architecture layer is emitted from the *same* projection
  and depth range, so the layers cannot disagree about perspective. A layer authored by eye against
  the others is a bug — the shared camera is what keeps parallax coherent when they move.
- **P127 (register propagates one way, standing):** the title inherits the board's ramps and
  lighting language; no board asset changes for the menu's benefit.

## Verification

- **V1 (R241/R242):** `--title-preview` capture shows the composed scene; each layer exists as its
  own asset in `assets/ui/title/` with its normal map where lit.
- **V2 (P128):** far/mid/near share a vanishing point — checked by capture, and by the layers being
  emitted from one projection with different depth ranges.
- **V3 (R243):** `--lights-off` proves the `Light2D` rig is what lights the scene (as the board's
  does); the scene reads dark and flat without it.
- **V4 (R244):** capture with motion and with **F9 reduced-motion**; the frozen frame is fully lit
  and loses no information.
- **V5 (R245):** title/emblem/options legible; re-captured at a second integer scale.
- **V6 (R246):** diff scoped `client/ specs/ docs/`; asset-map `--selftest` + `--check`; suites green.
