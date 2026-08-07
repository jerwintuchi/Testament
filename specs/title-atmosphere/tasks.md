# Tasks — The hall becomes quietly alive (TD-079)

> T# continues global from T294. A polish pass: client render only, composition untouched.
> Every claim here is a measurement, because "it feels right" is what this brief is trying to beat.

- [x] T295 [R277, P138 / V1] — **`title_air.gdshader` on the plate.** Ground haze, atmospheric
      perspective, god rays, altar emphasis and the light's breath in one pass on a quad that is
      rasterised every frame anyway. Depth has no buffer, so distance from the derived vanishing
      point is the proxy.
      **A real bug on the way, and a Godot semantics trap worth recording:** in a `canvas_item`
      shader, `COLOR` on entry **already holds** `texture(TEXTURE, UV) * modulate`. Sampling again
      and multiplying by `COLOR` therefore *squares* the image — on a hall this dark it cost a factor
      of **5** in mean luminance (37.2 → 7.6) and looked like the shader had destroyed the plate.
      Bisected by detaching the material, which put the un-shaded baseline at 35.8 and proved the
      shader was the cause rather than the deleted fog. Read `COLOR`, write `COLOR`: correct, and one
      texture fetch cheaper.
      Test: **V1** — captured; composition unchanged, the nave recedes.

- [x] T296 [R282 / V1] — **Atmospheric perspective, tuned to stay dark.** The first working pass
      lifted mean luminance **27%** over the un-shaded plate: the distance receded but the hall
      stopped being dark, and dark is the brief. `air_lift` 0.30→0.17, `air_desat` 0.35→0.28,
      `haze_amount` 0.13→0.075, `altar_lift` 0.085→0.055 — settling at **42.2** against a 35.8
      baseline, a restrained +18%.
      Test: **V1** — captured; distant architecture is softer and lower-contrast, the near piers keep
      their contrast, and no blur is used.

- [x] T297 [R278, P139 / V2] — **Motion is almost frozen, and it is a number.** Two captures **8
      seconds** apart: mean per-pixel change **1.30**, against the plate's own pixel-to-pixel texture
      variation of **24.65**. The screen changes **19× less than its own grain**. Nothing animates
      geometry — rays and haze vary in intensity only.

- [x] T298 [R280 / V1] — **God rays that are light, not an overlay.** Procedural shafts from the
      upper windows: soft cosine-squared edges, widening as they descend, dead before the floor,
      intensity-animated on their own slow periods.
      **Measured, not assumed** — the TD-078 lesson: captures differenced with `ray_strength` at 0 and
      at its shipped value give a **peak add of 25/255 over 16.4% of the frame**, against the retired
      sheet's 6.8/255. Visible, and at no fill cost.

- [x] T299 [R279 / V3] — **Dust drifts, it does not rise.** The old field pushed everything upward on
      a negative gravity, which reads as heat or smoke. Gravity is now near nil with full spread, at
      **two depths** (16 near / 18 far) differing in size, speed, lifetime and z — the parallax is
      between the layers. Per-mote opacity varies through a `color_ramp`.

- [x] T300 [R281 / V3] — **Lighting breathes; the altar leads.** ±4% over a ~109s cycle (inside the
      brief's 3–5%, long enough never to read as a pulse), and a squared altar term so the emphasis
      has no findable edge.

- [x] T301 [R283 / V4] — **The mark becomes the Collegium's seal.** Transition **175 ms** (inside
      150–200), a **9s / 14%** idle breath, and the selected label at **+12% luminance** — measured,
      down from **+23%**, which read as a highlight rather than as emphasis. A slide was dropped on
      purpose: the sprigs live in an `HBoxContainer` that reassigns child positions every layout
      pass, so a tweened offset would be fragile, and the brief says "fade *or* slide".

- [x] T302 [R284] — **No camera breath, recorded as a decision.** The plate is drawn 1:1 through
      `NEAREST`; a sub-pixel move resamples every pixel and shimmers, an integer move jumps. TD-075
      and TD-077 removed camera drift for the same reason. The brief's "if appropriate" is answered:
      it is not, and the light breathes instead.

- [x] T303 [R285, R286 / V5] — **Land it.** Budget **102 particles / 1.44 screens → 34 / 0.00**; the
      tool now names the shader pass explicitly at zero fill rather than silently omitting it,
      because "it is free" is exactly the claim that should be visible where the numbers are.
      Retired: `light_shaft.png` (+`.import`), `gen_title_overlays.py`, and `title_fire.gdshader` —
      an orphan from the TD-073 matte era that found bright pixels and treated them as flame, dead
      since the altar went cold and confirmed unreferenced in HEAD before deleting.
      All checks green; suites untouched; diff scoped. DECISION_LOG **TD-079**.

## Not in this pass, by instruction

- **No new props.** No banners, censers, statues or candles: the hall is a clean architectural
  foundation and stays one.
- **The composition is untouched** — menu layout, typography, logo placement, background, spacing.
- **The room-creation and join screens** remain queued; they are still the TD-071-era treatment.
