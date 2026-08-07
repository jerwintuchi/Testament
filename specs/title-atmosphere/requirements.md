# Requirements — The hall becomes quietly alive (TD-079)

> A **polish pass**, not a redesign. The author's brief: the title screen is the Collegium, the last
> surviving bastion — ancient, sacred, solemn, immense, quiet, dignified. Dark Souls / Demon's Souls
> Nexus / Blasphemous. Never haunted, abandoned, fantasy-MMO or noisy.
>
> **R276+**, **P138+**, **T295+**. Continues `specs/title-air/` (TD-078).

---

## R276 — Preserved, explicitly

The composition is **not** in scope and must come out unchanged: menu layout, typography, logo
placement, the Great Hall background, menu spacing, overall composition.

- AC: no new props — no banners, censers, statues or candles. The hall is a clean architectural
  foundation and stays one.
- AC: the plate's own pixels are never resampled. Everything below modulates colour; nothing moves,
  scales or filters the plate.

## R277 — The atmosphere moves into ONE shader pass

The brief asks for lightweight **shader-driven** effects over decorative props, and Testament is
browser-first. The plate is a `CanvasItem` drawn across the whole frame every frame regardless, so a
shader on it is the cheapest surface in the scene: haze, atmospheric perspective, god rays and the
light breath all cost **zero additional fill**.

- AC: `title_air.gdshader` on the plate supplies ground haze, atmospheric perspective, god rays,
  altar emphasis and the global light breath in a single pass.
- AC: it **replaces** the three particle fog banks and the `light_shaft.png` overlay entirely —
  "replace obvious fog particles with cathedral air", and no looping clouds or smoke-like motion.
- AC: sampling is 1:1 and `NEAREST` is preserved; the shader modulates colour and never resamples.
- AC: all animation is driven from `TIME` inside the shader, so there is still **no per-frame
  script** (the standing P135).

## R278 — Motion is almost frozen

- AC: nothing draws attention to itself. Movement should be noticed only after several seconds.
- AC: **no effect animates its geometry** — rays and haze vary in *intensity* only.
- AC: measured, not judged by eye: between two captures several seconds apart, the mean per-pixel
  change over the frame is **below the plate's own texture variation**. If a still-vs-still diff is
  loud, the screen is too active.

## R279 — Dust hangs in centuries-old air

- AC: dust **drifts**, it does not rise. No constant upward column.
- AC: extremely slow, with slight horizontal variation, at **two or more depths** with different
  sizes, opacities and speeds — the parallax is between the dust layers.
- AC: opacity varies per mote; the field is near-invisible except where light falls.

## R280 — God rays behave like cathedral light

- AC: they originate from the **upper windows**, have soft edges and low opacity, **widen as they
  descend**, and **fade before reaching the floor**.
- AC: animated by **intensity variation only** — the geometry never moves.
- AC: they read as light in air, not as a translucent overlay laid on top. Effective contribution is
  **computed** from the shader's own maths, not set by eye (the TD-078 lesson: three rays shipped
  invisible at 6.8/255 because an opacity was chosen without reading what it multiplied).

## R281 — Lighting breathes, and the altar is the focal point

- AC: global brightness varies **±3–5%** over a long cycle. No dramatic flicker.
- AC: the altar carries **slightly stronger** illumination than its surroundings — emphasis, not a
  glow, and no visible hotspot edge.

## R282 — Depth by atmospheric perspective

- AC: distant architecture is **softer and lower in contrast**; the near piers keep their contrast.
- AC: no blur. The effect is achieved by lifting blacks and desaturating with distance, using the
  hall's **derived** vanishing point as the depth proxy (P137 stands).

## R283 — The selection mark is the Collegium's seal

The laurel sprig already ships (TD-077). This refines its behaviour.

- AC: transition on selection change is **150–200 ms**, a gentle fade/slide.
- AC: the sprig carries an **extremely gentle idle breathing** animation.
- AC: the selected label brightens by **only 10–15%** — currently it jumps considerably more.
- AC: no glow, sparkles or fantasy effects. Aged brass / old gold, as the logo.

## R284 — No camera breathing (a decision, not an omission)

The brief asks for a sub-pixel camera breath *"if appropriate"*. **It is not**, and this records why
so it is not re-proposed:

- The plate is authored at 1280×720 and drawn **1:1 through NEAREST**. A sub-pixel translation or
  zoom resamples every pixel of a pixel-art image — the result is shimmer, not life — and an
  integer-only move visibly jumps. TD-075 and TD-077 both removed camera drift for exactly this.
- AC: the "quietly alive" quality is delivered by the **light** breathing instead (R281), which the
  brief also asks for and which costs nothing and breaks nothing.

## R285 — Performance (browser-first)

- AC: the atmosphere's **additive fill drops**, because the shader pass rides a quad that is already
  drawn. Enforced by `title_assets --budget` against the standing ceilings.
- AC: no post-processing, no full-screen extra passes, no new render targets.
- AC: live particle count falls — the banks are gone and only dust remains.

## R286 (containment) — client render + generated art only

- AC: no `src/**` change, no wire change; maps, manifest and registry regenerated; suites green.

---

## Correctness Properties

- **P138 (one pass, no extra fill):** every atmospheric effect that can live in the plate's shader
  does, so atmosphere costs ALU on a quad already being rasterised rather than another blended layer.
- **P139 (intensity, never geometry):** no atmospheric element animates its position, scale or shape.
  This is what keeps the screen from reading as active.
- **P135 (nothing per-frame), standing:** no `_process`/`_draw`; `TIME` in the shader and looping
  tweens only.

## Verification

- **V1 (R277/R280/R282):** capture; haze, rays and depth read, and the composition is unchanged
  against the TD-078 capture.
- **V2 (R278):** two captures seconds apart, differenced — the mean change is below the plate's own
  texture variation, reported as a number.
- **V3 (R279/R281):** capture; dust drifts at two depths, the altar is the focal point with no
  visible hotspot edge.
- **V4 (R283):** capture the marked option; the brightness delta is measured and inside 10–15%.
- **V5 (R285/R286):** `title_assets --budget` shows fill and particle count **down**; maps, registry,
  suites green; diff scoped.
