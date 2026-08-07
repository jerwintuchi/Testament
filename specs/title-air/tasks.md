# Tasks — The altar goes cold; the air becomes volumetric (TD-078)

> T# continues global from T286. Client render + tooling only; the named test is a capture **or** the
> budget tool. First spec written under `.claude/rules/performance.md`, so every task that adds render
> work answers to the budget in R272.

- [ ] T287 [R269 / V1] — **The altar goes cold.** Remove the additive `_glow` pool, the sanctuary
      `_embers`, and (with the fog sheets in T288) the warm haze baked into `fog_far`. Delete
      `FIRES`, `_glow`, `_embers` and the glow's use of `_radial` once nothing reaches them —
      **deleted, not commented out**. Confirm by grep that no other screen calls them; `_radial` is
      also the particle texture, so it stays.
      Test: **V1** — `--title-preview` capture beside the TD-077 capture: no bloom, no sparks, no
      haze at the arch, and the sanctuary still reads as the lit end of a dark nave on the plate's
      own painted light.

- [ ] T288 [R270 / V2] — **Retire the sheets.** Delete `gen_title_fog.py`, `fog_{far,mid,near}.png`
      (+ `.import`), `FOG`, `FOG_OVERHANG`, `_fog()`, and the fog-headroom assertion in
      `title_assets --selftest` (it guards a thing that no longer exists — leaving it green against
      nothing is worse than deleting it). Also retire `dust_overlay.png` (dust was being drawn twice
      — as this sheet *and* as `_dust()`'s particles) and `smoke_overlay.png` (a plume from an altar
      that is now cold — the same reasoning TD-076 used to remove the censers' incense), trimming
      `gen_title_overlays.py` to the god-ray generator it becomes.
      Test: **V2** — `title_assets --check` green at the reduced slot count; `asset_map --selftest`
      + `--check` show no dangling reference and no new orphan; headless parse clean.

- [ ] T289 [R271, P137 / V2] — **The vanishing point, derived.** `NAVE_VP = Vector2(0.500, 0.898)`
      in the rig, with the source→plate crop conversion written at the constant (the measurement
      reports `fy 0.8651` on the **uncropped** source; the plate is cropped at y=110 of 1024 to a
      height of 864). Guard it: `title_assets --selftest` re-derives the conversion from
      `gen_title_matte.py`'s crop box and fails if the rig's constant disagrees — so a future re-crop
      of the plate cannot silently leave the air converging on the wrong point.
      Test: **V2** — selftest green, and proven failing by perturbing the constant.

- [ ] T290 [R271, R272, P135, P136 / V2, V3] — **The three banks.** One ordered near-to-far table
      (count / radius / `radial_accel` / lifetime / alpha / tint / z) driving three
      `CPUParticles2D` emitters positioned **at the VP**, with `radial_accel` positive for near
      (rushing outward past the camera), near-zero for mid, and **negative** for far (converging into
      the distance) — the banks differ in the *direction* of travel, not only its speed.
      `scale_amount_curve` grows each particle over its life, `color_ramp` fades it in and out,
      `preprocess = lifetime` so the hall opens with the air already moving. `_dust` drops 46 → 28,
      since the banks are the air now. **No `_process`, no `_draw`** (P135).
      Test: **V2** — captures seconds apart show the near bank crossing frame and the far bank
      nearly still; **V3** — the budget tool passes.

- [ ] T291 [R272 / V3] — **Make the budget a test.** `tools/title_assets.py --budget` parses the
      bank table, the dust emitter and the overlay/ray tables out of `title_scene.gd`; computes live
      particle count, full-frame-or-wider additive layer count, and estimated fill in screens
      (Σ area × count ÷ 230,400 logical px — scale-invariant, so it holds at every device
      resolution); prints all three; and **exits 1** over any ceiling (120 / 3 / 2.5).
      Test: **V3** — prints the expected ≈102 particles, 0 full-frame layers, ≈1.23 screens, and is
      **proven to fail** by raising a bank's count past the ceiling, exactly as the fog-headroom
      check was proven. A screenshot cannot show a frame cost; if the budget is not a test it is a
      comment.

- [ ] T292 [R273 / V4] — **Reduced motion freezes, never skips.** Emit and `preprocess` every bank,
      then `speed_scale = 0.0`. A still frame with no fog is a *different picture*, which is the
      failure this task exists to prevent.
      Test: **V4** — `--reduced-motion` capture: all three banks present, fully lit, motionless.

- [ ] T293 [R275 / V1, V3] — **The god-rays: visible or gone.** They are not mis-layered — the
      sheet's peak alpha is 34/255, the rig multiplies by 0.20/0.13/0.10, and `_breathe` removes
      another 35%, so the brightest ray adds **6.8/255** over a hall that varies by more. Meanwhile
      they are ~0.95 screens of fill, more than every particle in R272 combined. Compute the
      effective contribution from the asset's alpha × the rig's opacity (never set an opacity by eye
      — that is how this happened), then either raise them to a contribution a capture can show, or
      delete all three and reclaim the fill.
      Test: **V1** — captures with rays present and absent, differenced: if the two are
      indistinguishable the rays are not earning their cost; **V3** — the budget tool reports the
      reclaimed or spent fill either way.

- [ ] T294 [R274 / V5] — **Land it.** Asset map, manifest, spec registry and `title_assets` all
      regenerated and checked; suites green; diff scoped `client/ specs/ docs/ tools/` with no
      `src/**` change. Record in the DECISION_LOG as **TD-078**, including the two findings this
      spec surfaced but did not cause: dust drawn twice since T260c, and
      `gen_title_furniture.ZENITH_FY` holding the **source-space** zenith (-6.768) where the
      crop-corrected value is **-8.148** — dormant only because the props are switched off.

## Queued behind this (the author's sequencing)

- **The room-creation and join screens.** Flagged by the author as looking unrelated to the title
  screen — correctly: they are the TD-071-era plate-and-nave treatment with a purple-navy panel and
  chunky gold buttons, against a title screen that has since been rebuilt three times. Its own spec,
  after this one.

## Not in this spec

- **T262 ambient audio** — still blocked on adding an audio tool to the closed list.
- **GPU particles** — the client runs GL Compatibility and every particle in the project is
  `CPUParticles2D`. At ≤120 particles the CPU cost is not the constraint; fill rate is, and that is
  identical on either backend.
