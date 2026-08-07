# Design — Volumetric air from three particle banks (TD-078)

> Satisfies R269–R275. Client render + tooling only. Verified by capture **and** by a budget tool.

---

## The idea, in one sentence

Put the emitters **at the hall's vanishing point** and let the particles accelerate outward from it,
growing as they come — so the fog is not sliding across the picture, it is coming *past the camera*.

That is the whole design. Everything below is the arithmetic to make it cheap and the plumbing to
keep it honest.

## Why sheets could not get there

A sheet drifting sideways gives *lateral* parallax: layers at different speeds. Real depth in a
static frame comes from **motion toward the viewer** — things growing, accelerating, and leaving the
frame edge — because that is the one cue a flat plane physically cannot fake. Three sheets sliding
at 90 / 55 / 32s are three flat planes sliding, and the author read them as exactly that.

## The vanishing point is derived (P137)

`tools/measure_reference.py` solves the hall's camera from two vanishing points and reports the nave
VP as `fx 0.500, fy 0.8651` — **on the uncropped source**. The shipped plate is cropped by
`gen_title_matte.py` at `(0, 110, 1536, 974)` before scaling to 1280×720, so that number is not the
one the rig wants:

```
source 1536x1024, crop y=110 height 864
  VP  fy 0.8651  ->  (0.8651*1024 - 110) / 864  =  0.8980
  VP  fx 0.500   ->  unchanged (crop is full width)

NAVE_VP = Vector2(0.500, 0.898)     in viewport fractions
```

Using the raw 0.8651 would place the VP ~24 logical px above where the architecture actually
converges — small enough to look plausible in a still and wrong enough that the radial motion would
visibly disagree with the piers. The conversion is written into the rig beside the constant.

> **Latent defect found on the way, recorded not fixed here.** `gen_title_furniture.ZENITH_FY`
> is `-6.768` — the **source-space** zenith, used against display fractions without the same crop
> correction. The crop-corrected value is **-8.148**, so every prop's shear is computed against a
> zenith ~20% too close. It is dormant because `PROPS_IN_PLATE = true` switches all nine props off;
> turning them back on would ship a wrong lean. Out of scope here (this spec touches no prop), but it
> must not be lost — it goes in the DECISION_LOG and stays in `specs/title-scene/` as a known defect.

## The banks (P136 — one ordered table, near to far)

```
                near            mid             far
count           18              26              30
radius (logical) 26             16              7
radial_accel    +14 .. +22      +3 .. +7        -2 .. -1     (negative = converges on the VP)
lifetime        7s              13s             26s
alpha peak      0.085           0.055           0.030
tint            cool grey       neutral         warm-grey (the distance)
z_index         -20 (in front)  -45             -62 (behind everything)
```

Every channel that can carry depth carries it, and they all move together in one table. The *sign*
of `radial_accel` is what makes the far bank read as receding while the near bank rushes past — the
requirement that the banks differ in direction of travel, not just speed (R271).

## How it runs with zero per-frame script (P135)

`CPUParticles2D` does all of it in its own simulation — no `_process`, no `_draw`:

- **emitter position** = the VP. **`emission_shape`** = a small sphere around it, so particles are
  born in the distance.
- **`radial_accel_min/max`** accelerates each particle *away from the emitter origin* — which, with
  the emitter at the VP, is exactly outward along the nave. This is the effect, and it is one
  built-in property.
- **`scale_amount_curve`** grows the particle over its life (approach), **`color_ramp`** fades it in
  and out so nothing pops at birth or death.
- **`preprocess = lifetime`** so the hall opens with the air already moving (R272).
- **reduced motion**: emit, `preprocess`, then set `speed_scale = 0.0` — the bank is fully present
  and lit, simply frozen (R273). Skipping the emitter would give a still frame with no fog, which is
  a different picture.

## The budget, computed (R272)

Fill is scale-invariant — the ratio of blended pixels to screen pixels is the same at 720p and 1080p
— so it is computed in logical units against a 640×360 = 230,400 px screen:

| source | count | area each (px²) | fill (screens) |
|---|---:|---:|---:|
| near bank | 18 | π·26² = 2,124 | 0.166 |
| mid bank | 26 | π·16² = 804 | 0.091 |
| far bank | 30 | π·7² = 154 | 0.020 |
| dust (kept, 46 → 28) | 28 | π·4² = 50 | 0.006 |
| god rays ×3 | 3 | 108k / 63k / 47k | 0.950 |
| **total** | **102 particles** | | **≈ 1.23** |

Against the ceilings: **102 ≤ 120** particles, **≈1.23 ≤ 2.5** screens of fill, and **1 ≤ 3**
full-frame-or-wider additive layers (only `smoke_overlay` — see below).

**The rays are the single largest line, and they are currently invisible (R275).** They cost more
fill than every particle combined, while contributing a peak of 6.8/255 at the brightest — the
sheet's own 34/255 alpha multiplied by the rig's 0.20, then reduced another 35% by `_breathe`. So
the budget's dominant term is buying nothing. R275 forces the decision rather than leaving it
half-present: make them measurably visible, or delete them and reclaim 0.95 screens. If they go, the
whole atmosphere costs **≈0.28 screens** — a ninth of the ceiling.

### What gets retired, and why each is not just "cleanup"

| retired | reason |
|---|---|
| `fog_far/mid/near.png` + `gen_title_fog.py` + `_fog()` + the headroom selftest | replaced by the banks (R270) |
| `dust_overlay.png` | dust was drawn **twice** — this sheet *and* `_dust()`'s particles |
| `smoke_overlay.png` | it is a plume from an altar that is now **cold**. TD-076 removed the censers' incense on exactly this reasoning: smoke rising from nothing is the same failure as a glow over nothing. Reversible in one line if the author wants a smouldering altar. |
| `_glow`, `_embers`, `_radial`-for-glow, `FIRES` | the altar goes cold (R269) |

Retiring `smoke_overlay` drops the full-frame additive count to **zero** and total fill to ≈1.23.

## Verified, not asserted (R272, performance canon P3)

`tools/title_assets.py` gains **`--budget`**: it parses the bank table, the dust emitter and the
overlay/ray tables out of `title_scene.gd`, computes live count, full-frame layer count and estimated
fill in screens, prints them, and **exits 1** when a ceiling is exceeded. The ceilings live in the
tool, next to the numbers they bound.

This is the same shape as TD-077's fog-headroom check, and for the same reason: the failure is
invisible in a still capture. A screenshot cannot show a frame cost, so if the budget is not a test
it is a comment.

## Files

**New:** `specs/title-air/*`.
**Edited:** `client/scripts/ui/title_scene.gd` (banks, VP, retirements), `tools/title_assets.py`
(`--budget`, minus the fog-headroom check), `specs/title-scene/asset-manifest.md`, CLAUDE.md.
**Deleted:** `client/assets/ui/gen_title_fog.py`, `client/assets/ui/title/fog_{far,mid,near}.png`
(+ `.import`), `client/assets/ui/title/dust_overlay.png`, `client/assets/ui/title/smoke_overlay.png`,
and the `smoke`/`dust` emitters in `gen_title_overlays.py` (leaving it the god-ray generator).

## Correctness Properties

- **P135 (nothing per-frame):** no `_process`/`_draw` on this screen; emitter simulation and looping
  tweens only.
- **P136 (depth lives in one table):** every depth-varying value is one ordered near-to-far table.
- **P137 (the VP is derived):** the VP is the measured camera's, crop-corrected, with the conversion
  recorded at the constant.
