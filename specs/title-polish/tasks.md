# Tasks — Title screen polish (TD-077)

> T# continues global from T280. Client render + generated art only; the named test is a capture
> unless stated otherwise.

- [x] T281 [R265 / V3] — **The laurel marker.** `gen_menu_sigil.py` re-authored: a branch rooted at
      the bottom inner corner, arcing up and outward, 34×30, shown at 17×15 logical so its pixels
      land 1:1 on device pixels. The UI mirrors it for the left side, giving the author's `\ word /`.
      **The leaves are hand-authored ASCII stamps, not a shape function** — five analytic passes each
      failed a different way (thorns → pods → one fused gilt mass → a fishbone once spaced apart),
      which is TD-057's finding arriving again at 34×30: *a shape function samples a curve; it cannot
      decide which pixel carries the leaf*. The **rim is derived** (every empty pixel touching gold
      becomes `wood[0]`), because at four pixels across only a dark edge separates two overlapping
      leaves, and a dilation cannot be forgotten on one leaf and not another.
      Test: `assert_on_palette` passes; captured at 1:1 and examined at 4× — the leaves read as
      leaves, and the marker keeps its footprint unlit so selection never shifts the lettering
      (P133).

- [x] T282 [R264 / V2] — **Hard-edged Cinzel, project-wide.** `antialiasing=1 → 0` and
      `subpixel_positioning=4 → 0` in `client/assets/fonts/Cinzel.ttf.import` — the **import**, not a
      runtime property, so every load of the face is affected and nothing can opt back in by
      accident. `fonts.gd`'s comment claimed the AA was a deliberate exception; it is corrected in
      place with what the captures actually showed.
      Test: **V2**, before/after at 3× on both screens.
      **Verdict — the title screen: better.** TESTAMENT at 26px gains cut-stone edges, and the 13px
      options are sharper and fully readable; nothing was lost.
      **Verdict — the Contract Board: safe, with one honest caveat.** Cinzel on the board is only the
      header (`Fonts.cinzel` has four call sites: `widgets.h1`, the title options, `rite_banner`,
      `room_scroll`). "THE COLLEGIUM" improves. The subordinate "Contract Board" line — the smallest
      Cinzel anywhere in the game — comes out slightly **chunkier**, its stems a shade irregular; it
      stays legible and now matches the register around it, so it ships, but it is the one place the
      old exception had a point. **The board's small text is unaffected** — the legend, status and
      keyhint labels are the default sans and are pixel-identical.

- [x] T283 [R263, P132 / V1] — **Parallax fog.** `gen_title_fog.py` emits three 1440×720 banded
      alpha sheets (four alpha steps each, alpha-only so the rig's `modulate` is an honest dimmer
      plus a tint); `title_scene._fog` drifts them at 90 / 55 / 32s with seeded phases and a slower
      vertical breath. The plate is not touched (P132) — the depth cue is entirely fog against fog.
      **The first pass was ~4× too strong** and had to be cut twice over: additive white over a hall
      this dark lifts the black floor across the whole frame, so it read as a milky film laid over
      the picture and the deep contrast that makes the scene work was gone. Two fixes — the sheet
      alphas roughly quartered, and a `nave(fx)` weight that keeps fog off the near piers, which are
      the *closest* thing in the picture and were the worst of the wash.
      Test: **V1.** Captured in motion and under `--reduced-motion`: the F9 still frame keeps every
      bank, fully lit (P134). Motion measured between t=3s and t=26s as mean |Δ| per band —
      near 2.46, far 1.61, mid 1.02 — so all three move and by different amounts. (Honest limit: the
      sample also contains dust and the fire flicker, and the mid band is thinned 80% by `quiet()`
      where the menu is read, so this proves *differential motion*, not a clean per-bank isolation.)
      Edge safety is a **real test, not arithmetic in a comment**: `title_assets --selftest` now
      parses `FOG_OVERHANG` and each bank's drift out of the rig and fails if a drift exceeds the
      half-overhang — verified to fail by raising the near drift 38 → 48. That failure is invisible
      in a still and only appears as a hard seam sliding across the hall seconds after load, and
      "raise the drift so the parallax reads more" is exactly the future edit that would cause it.

- [x] T284 [R266 / V4] — **Haze, embers, rays.** All three, and **no new asset slot** for any of
      them. **Haze** is baked into `fog_far.png` as a warm pool at the sanctuary arch — it *is* fog,
      so a layer of its own would only be one more thing to keep in sync. **Embers**: with the six
      vessel fires gone the altar is the one fire in frame, and at the old count it threw two or
      three sparks a second into the brightest part of the picture, where they vanished; count
      7→16, life 4.2→5.6s, alpha 0.45→0.62. **Rays**: `light_shaft.png` placed three times rather
      than drawn three times — the dominant one keeps its position and strength, two narrower and
      dimmer ones flank it (one mirrored), each breathing on its own period, because rays pulsing
      together are the same tell as synchronised flicker.
      Test: **V4** — captured. The altar now reads as burning rather than merely lit and the nave
      recedes into warm air. One correction found by looking: the altar sits **directly below the
      menu column**, so the livelier embers climbed straight through the last option. Fixed with
      `damping` (2.4–5.0) plus a wider spread — the stream thins and stops below the reading area,
      which is also what a cooling ember actually does. All four options legible in the capture.

- [x] T285 [R266 / V4] — **Arrival and polish.** `_title_arrival` fades each child of the menu
      column in order (0.075s apart, 0.42s each), so the device settles, then the title, then the
      rule, then the options. The sigils **ease** over 0.12s with the previous tween killed via a
      node meta, so arrowing down the menu does not flicker four of them on and off; the marked
      option's letters **warm** a step (the sigils say *which*, the warmth says it is live). The
      **version string** sits bottom-right, read from `application/config/version`, parented to the
      environment so it leaves with the screen.
      Test: **V4** — captured at 0.45s / 0.75s / 2.5s: the stagger reads, and the settled frame is
      correct. Under `--reduced-motion` the 0.45s capture is **already settled** — the sequence is
      skipped, not merely sped up.
      **Two real bugs found by looking rather than by asserting:**
      (1) The arrival appeared not to run. `--title-preview` was deferring a **second**
      `_show_title()` purely to inject its fake token, so the flourish played on a build that was
      immediately thrown away — and every title capture had been constructing the whole scene twice.
      The token is now set before the first build and the rebuild is gone.
      (2) Removing that rebuild exposed an **older** bug it had been masking: `--reduced-motion` was
      parsed *after* `_show_title()`, so the title only ever honoured it because that unrelated flag
      happened to rebuild the screen afterwards. Moved above the first build.
      Also: `config/version` first read back empty because the comment I put in `project.godot` used
      `#` — it is a Godot ConfigFile, where comments are `;`, and a `#` line silently breaks its
      section. Noted at the call site.

- [x] T286 [R267, R268 / V5] — **Land it.** **No camera drift**, recorded as a decision and not an
      omission: at 1:1 device pixels a sub-pixel move resamples every pixel of the plate and an
      integer-only move visibly jumps, so the fog supplies the life instead (R267, the same finding
      TD-075 recorded when the drift was first removed).
      Test: **V5** — `title_assets --selftest` (incl. the new fog-headroom assertion) + `--check` at
      **16 of 16** slots; `asset_map --selftest` + `--check`; `spec_status --selftest` + `--check`;
      suites green and untouched (server 362, shared 65, tools 7). Captured at **both** integer
      scales — 1280×720 (logical 640×360) and 1904×1040 (logical 952×520): no layer seam, fog reads
      at both, the laurel pair flanks the marked option, the version string sits clear.
      Diff scoped to `client/ specs/ docs/ tools/` — **no `src/**` change** (R268). DECISION_LOG
      **TD-077**.
