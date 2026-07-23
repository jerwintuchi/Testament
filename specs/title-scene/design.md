# Design — The title screen as a composed, lit scene (TD-073)

> Satisfies R241–R246. Client render + generated art. Verified by capture.

---

## Why the single plate failed (kept, so it is not retried)

TD-072 generated the whole nave as one PNG from a per-pixel classifier. Four passes went into it and
it never approached the reference. The failures were not tuning:

- **Symmetry and uniformity.** Analytic bays, ribs and courses repeat exactly. The reference's walls
  differ left from right, its candles vary in height, its censers hang at different angles.
- **Small props at small scale.** A drawn flame failed four times (box → cone → ball → box). At a few
  pixels, a shape function cannot decide *which pixel* is the flame — the same finding TD-057 already
  recorded for the 17×22 medallion device.
- **Light as arithmetic.** Baked falloff over a stepped ramp bands; it needed dithering to hide, and
  it can never flicker. The bible requires in-engine lighting anyway (TD-043).

What *is* worth keeping is the **camera**: hfov 105°, pitch 15°, in metres at Chartres proportions.
It was measured from the reference and it is correct. It becomes the shared projection every
architecture layer is emitted from.

## The scene

```
TitleScene (Control)
├─ Backdrop        ColorRect            navestone[0] — nothing is ever pure void
├─ L0_far          Sprite2D  nave_far.png    (+_n)   z=-40   dim, small, the apse
├─ L1_shrine       Sprite2D  shrine.png            z=-35   + PointLight2D (warm, steady)
├─ L2_mid          Sprite2D  nave_mid.png    (+_n)   z=-30   arcade + vault
├─ L3_pier_L/R     Sprite2D  pier.png        (+_n)   z=-20   the near frame, darkest
├─ L4_banner_L/R   Sprite2D  title_banner.png(+_n)   z=-15   sway tween
├─ L5_censer ×4    Sprite2D  censer.png            z=-12   + PointLight2D (flicker)
├─ L6_candles ×4   Sprite2D  candle_rack.png       z=-10   + PointLight2D (flicker)
├─ L7_floor        Sprite2D  floor_wet.png   (+_n)   z=-8    runner + reflection band
└─ Embers          CPUParticles2D                    z=-5    slow motes, additive
```

Everything above the backdrop is a `Sprite2D` with `texture_filter = NEAREST`, positioned by
**authored** offsets in viewport fractions so the composition can be asymmetric.

## Who authors what (R242 / TD-057)

| Asset | Size | Tool | Why |
|---|---|---|---|
| `nave_far.png` (+`_n`) | 320×180 | **Python** (`gen_nave_layers.py`) | architecture: projection, grain, AO |
| `nave_mid.png` (+`_n`) | 640×360 | **Python** | ditto |
| `pier.png` (+`_n`) | 200×360 | **Python** | ashlar, bevel, colonnette rounds |
| `floor_wet.png` (+`_n`) | 640×160 | **Python** | flags, runner, reflection gradient |
| `title_banner.png` (+`_n`) | 96×220 | **Python** | cloth folds + a normal map — the board's `gen_banner` idiom |
| `censer.png` | 24×56 | **Aseprite** | a hanging lamp on a chain: every pixel is a decision |
| `candle_rack.png` | 64×40 | **Aseprite** | a rank of tapers at varying heights — irregularity is the point |
| `shrine.png` | 96×72 | **Aseprite** | the device + its housing |

The three Aseprite assets are exactly the class TD-057 assigns to it, and Aseprite is drivable in
batch from WSL (`Aseprite.exe -b --script`), so this needs no new tool.

### Depth slices (P128)

`gen_nave_layers.py` imports TD-072's projection unchanged and emits each architecture layer by
**restricting the depth range** it draws, writing transparent elsewhere:

```
nave_far   z ∈ [55, ∞)    everything beyond the fifth bay
nave_mid   z ∈ [14, 55)   the working arcade + vault
pier       z ∈ [0, 14)    the near frame, emitted once and mirrored
```

Because all three come from one camera, they share a vanishing point by construction — a layer
placed by eye would drift the moment parallax moved it.

## Lighting (R243)

Each flame gets a `PointLight2D` with the board's warm colour, energy driven by a seeded flicker:

```gdscript
energy = base * (1.0 + 0.10 * sin(t * f1 + p1) + 0.05 * sin(t * f2 + p2))
```

Per-light `f`/`p` from a hash of its index, so no two pulse together — synchronised flicker is the
tell that reads as fake. `--lights-off` and F9 both pin every light to its base energy, which is
also the reduced-motion state (R244): fully lit, simply still.

## Motion (R244)

- **Flicker**: light energy only, never position.
- **Embers**: one `CPUParticles2D`, additive, slow upward drift, low count.
- **Banner sway**: a looping `skew`/`rotation` tween of ±0.6°, out of phase left vs right.
- All three are created only when `not _reduced_motion`; F9 rebuilds the screen.

## Correctness Properties

- **P128 (one camera, many layers):** every architecture layer is emitted from the same projection
  with a different depth range, so perspective agreement is structural, not eyeballed.

## Files

New: `client/assets/ui/gen_nave_layers.py`, `client/assets/ui/gen_title_banner.py`,
`art/src/censer.aseprite` + `candle_rack.aseprite` + `shrine.aseprite` (+ exported PNGs),
`client/scripts/ui/title_scene.gd`, `specs/title-scene/*`. Edited: `client/scripts/main.gd`
(`_show_title` instances the scene instead of one TextureRect). Retired: the single-plate path in
`gen_nave.py` (its projection is imported by the layer generator, so the file stays).
