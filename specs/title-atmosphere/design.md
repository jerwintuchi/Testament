# Design — The whole atmosphere on one quad (TD-079)

> Satisfies R276–R286. Client render only. Verified by capture, by measurement, and by the budget.

---

## The idea

The plate is a `CanvasItem` covering the frame, rasterised every frame whether or not a shader is
attached. So a shader on it is **the cheapest surface in the scene**: ground haze, atmospheric
perspective, god rays, altar emphasis and the light's breath all become ALU on pixels that were
already being written. Everything they replace — three particle fog banks and a `light_shaft.png`
overlay — was *additional* blended coverage.

Measured, that is the difference between **102 particles / 1.44 screens of additive fill** and
**34 / 0.00**.

Testament is browser-first, and this is what "favor shaders" buys when it is taken literally.

## Depth without a depth buffer

There is no depth information in a painted plate. But there is a **vanishing point**, derived and
already trusted by the rig (TD-078, crop-corrected to `fy 0.898`). Distance from it is a serviceable
depth proxy: pixels near the VP are far down the nave, pixels at the frame edge are the near piers.

That single scalar drives both effects that need depth:

```
far = 1 - smoothstep(0, air_reach, |uv - vp|)     // 1 in the distance, 0 at the near piers

saturation  -= far * air_desat        // distance drains colour
colour      -> air_col by far * air_lift * (1 - luma*0.55)   // and lifts blacks more than highlights
```

Blacks lift more than highlights because that is what haze does — it *raises the floor*, it does not
brighten everything. Contrast falls out of that for free. **No blur**: a blur would need a second
sample set and would read as a lens defect rather than as air.

## Two rules that keep it from reading as "active"

1. **Nothing moves (P139).** Every animated term varies in *intensity*. Rays do not sweep, haze does
   not roll, the plate is never offset or scaled. This is the whole difference between atmosphere and
   an animated wallpaper.
2. **The plate is never resampled.** The shader reads its own `COLOR` and writes it back — no
   transform, no filtering change, no second sample.

Measured: over **8 seconds** the frame's mean per-pixel change is **1.30**, against the plate's own
pixel-to-pixel texture variation of **24.65**. The screen changes 19× less than its own grain, which
is what "almost frozen" means in a form that can be checked (R278).

## God rays that are light rather than an overlay

Each shaft hangs from an upper window and is defined by `(x0, y0, half-width at top, lean)`:

```
half_w  = w0 + ray_spread * drop          // widens as it descends
centre  = x0 + lean * drop                // leans, but never over time
across  = cos(d * PI/2)^2                 // soft edges, no findable rim
envelope= smoothstep in below the window, out before ray_die_y
```

They are strongest where there is haze to catch them (`catch_air` scales with the ground band), which
is why they read as light *in air* rather than as a decal.

**Strength is computed, not chosen.** TD-078's lesson was three rays shipped invisible because an
opacity was set without reading what it multiplied. Measured here by differencing captures with
`ray_strength` at 0 and at its shipped value: **peak add 25/255 over 16.4% of the frame**, against
the old sheet's 6.8/255 — visible, and free.

## Lighting and the altar

```
col *= 1 + 0.040 * sin(TIME * 0.0092 * TAU)     // +-4%, ~109s cycle
col += air_col * altar^2 * 0.055                // emphasis with no findable edge
```

±4% sits inside the brief's 3–5%, and a 109-second cycle is long enough that it never reads as a
pulse. The altar term is squared so it has no visible boundary — it is emphasis, not a glow.

## Dust, re-authored (R279)

Dust **drifts**; it does not rise. The old field pushed everything up on a negative gravity, which
reads as heat or smoke — the two things this hall is not. Now gravity is near nil, spread is full,
and two emitters sit at different depths:

| depth | count | size | life | drift | z |
|---|---:|---:|---:|---:|---:|
| near | 16 | 0.030–0.055 | 54s | 1.5 | −26 |
| far | 18 | 0.014–0.026 | 78s | 0.7 | −58 |

The parallax is *between the two layers*. Per-mote opacity varies through a `color_ramp`, so the
field is near-invisible except where the light finds it.

## The selection mark (R283)

Already the Collegium's laurel (TD-077). Refined: the transition is **175 ms** (inside 150–200), the
mark carries a **9-second, 14% idle breath**, and the selected label brightens by **+12% luminance**
— measured, down from +23%, which read as a highlight rather than as emphasis.

*A slide was considered and dropped:* the sprigs live in an `HBoxContainer`, which reassigns child
positions on every layout pass, so a tweened offset would be fragile. The brief says "fade **or**
slide"; fade is the one that cannot break.

## No camera breath (R284)

The brief asks for a sub-pixel camera breath *if appropriate*. It is not. The plate is authored at
1280×720 and drawn 1:1 through `NEAREST`; a sub-pixel move resamples every pixel of a pixel-art image
and produces shimmer, while an integer move visibly jumps. TD-075 and TD-077 both removed camera
drift for this reason. The "quietly alive" quality comes from the light breathing instead.

## Files

**New:** `client/assets/ui/title/title_air.gdshader`, `specs/title-atmosphere/*`.
**Edited:** `client/scripts/ui/title_scene.gd` (shader on the plate; banks and rays removed; dust
re-authored), `client/scripts/main.gd` (selection timing, breath, brightness),
`tools/title_assets.py` (`--budget` rewritten for the shader architecture), the asset manifest.
**Deleted:** `light_shaft.png` (+`.import`), `gen_title_overlays.py`, and `title_fire.gdshader` — an
orphan from the TD-073 matte era that found bright pixels and treated them as flame, dead since the
altar went cold.

## Correctness Properties

- **P138 (one pass, no extra fill):** atmosphere rides a quad already being rasterised.
- **P139 (intensity, never geometry):** no atmospheric element animates position, scale or shape.
- **P135 (nothing per-frame), standing:** `TIME` in the shader and looping tweens; no `_process`.
