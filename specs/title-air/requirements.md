# Requirements — The altar goes cold; the air becomes volumetric (TD-078)

> The author's brief: **remove the bright orangey glow on the altar**, and replace the flat fog with
> a **foggy air ambience built from particles, layered/parallaxed so the hall reads as 3D depth
> rather than 2D planes**. Specified under the new performance canon
> (`.claude/rules/performance.md`), which this is the first spec to answer to.
>
> **R269+**, **P135+**, **T287+**. Continues `specs/title-polish/` (TD-077).

---

## The problem this spec exists to fix

TD-077 gave the hall three drifting fog **sheets**. They are images. An image sliding sideways is
parallax in the strict sense — layers at different speeds — but it is still a *flat thing moving
across another flat thing*, and the author's read is that the hall still looks 2D. Sliding a picture
of fog does not put you inside the fog.

Three findings from measuring the current screen, which shape everything below:

1. **The screen already breaks the budget.** Five full-frame-or-wider additive layers are live
   (`fog_far` + `fog_mid` + `fog_near` + `smoke_overlay` + `dust_overlay`), plus three god-ray
   sheets. The ceiling in R272 is three.
2. **Dust is drawn twice** — `dust_overlay.png` (a static sheet of motes) *and* `_dust()`'s 46 CPU
   particles. One of them is redundant work that has been shipping since T260c.
3. **Particle count is the wrong number to budget.** The cost is **fill rate**: every particle is an
   additive blend at *device* resolution. Sixty 300px soft blobs cost far more than four hundred
   8px ones. A budget expressed only in counts would be satisfied and still be slow.

---

## R269 — The altar goes cold

- AC: the additive `_glow` pool over the sanctuary is **removed**.
- AC: the warm **haze pool** baked into `fog_far` is not re-created in the particle system.
- AC: the sanctuary **embers** are removed.
- AC: the plate's own painted light at the arch **stays** — it is baked into `hall_plate.png` and is
  not in scope. The sanctuary must still read as the lit end of a dark nave; it simply stops
  blooming, sparking, and hazing.
- AC: `FIRES`, `_glow`, `_embers` and `_radial` become unreachable from this screen. Whatever is
  genuinely dead is **deleted**, not left commented — and if any is still reachable from another
  screen, that is stated rather than assumed.

## R270 — Fog is particles, in three depth banks; the sheets are retired

- AC: `fog_far.png`, `fog_mid.png` and `fog_near.png` are **deleted**, along with
  `gen_title_fog.py`, `FOG`, `FOG_OVERHANG`, `_fog()` and the fog-headroom selftest that guarded
  them. Nothing is left switched-off "in case".
- AC: three particle banks replace them — **far**, **mid**, **near** — differing in *every* channel
  that carries depth: particle size, speed, opacity, lifetime, colour temperature, and z-order
  relative to the architecture.
- AC: `dust_overlay.png` is **also retired** (finding 2 above). The banks are the air now; a static
  sheet of motes under a live particle field is duplicated work and one of the layers over budget.
- AC: the banks are declared in **one ordered table** in the rig, near-to-far, so depth is a single
  readable gradient and not values scattered across three functions (P136).

## R271 — Depth reads as motion *through* space, not planes sliding

This is the requirement the spec exists for; the rest is housekeeping.

- AC: the near bank's particles travel **radially outward from the hall's vanishing point**, growing
  and accelerating as they approach the camera, and fade out before they reach the frame edge. That
  is the motion of flying *through* fog and it is the strongest depth cue available in 2D.
- AC: the far bank barely moves and **converges** toward the vanishing point; the mid bank is
  between the two. So the three banks differ in the *direction* of travel, not only its speed.
- AC: the vanishing point is **read from the hall's measured camera**, not eyeballed — the same
  zenith/VP that `tools/measure_reference.py` solved and that `gen_title_furniture.py`'s shear uses.
  A VP guessed by eye will disagree with the architecture and the effect collapses.
- AC: no particle crosses the menu's reading area brightly enough to hurt legibility (R245 stands).

## R272 — The performance budget (the first spec under the performance canon)

Budgeted **mobile-first**, at the author's direction: the title screen is the first thing that runs.

- AC: **≤ 120 live particles** on screen at once, across all emitters, in the settled state.
- AC: **≤ 3 full-frame (or wider) additive layers.** Down from the current five.
- AC: **≤ 2.5 screens of additive fill** per frame from atmosphere — that is, the sum over every
  particle and overlay of (its area × its count) ÷ (one screen) — measured at the 1080p device
  target, not at the 640×360 logical viewport. **This is the binding constraint**, not the count.
- AC: **zero per-frame script work.** No `_process`, no `_draw` on this screen; emitters and tweens
  only (P135). The rig has none today and must still have none.
- AC: emitters use `preprocess` so the screen opens with the air already in motion, never switching
  on after load.
- AC: the budget is **verified, not asserted** (performance canon P3): the numbers are derived from
  the rig by a tool and fail the build if exceeded.

## R273 — Reduced motion loses nothing

- AC: F9 / `--reduced-motion` renders a **still, fully-lit** frame in which every bank is present.
  Reduced motion removes movement, never content (the standing P134).
- AC: with particles that means the banks are emitted and then frozen, not skipped — a still frame
  with no fog is a different picture, which is what this AC exists to prevent.

## R275 — The god-rays are made visible or they are deleted

Found while costing the budget, on the author's report that they cannot see the rays. They are not
mis-layered; they are **double-dimmed into invisibility**, and they are simultaneously the single
most expensive thing in the frame.

`light_shaft.png` is authored with a peak alpha of **34/255** (deliberately subtle, banded), and only
~9% of the sheet reaches even that. The rig then multiplies by `0.20 / 0.13 / 0.10`, and `_breathe`
removes a further 35% at its trough. Net peak brightening is **6.8 / 4.4 / 3.4 out of 255** — under
3% — over a hall whose own stone texture varies by more than that.

- AC: **decide, do not tune blindly.** Either the rays reach a measured, visible contribution (a peak
  add the capture can actually show), or all three are deleted and their ~0.95 screens of fill —
  more than every particle in R272 combined — is reclaimed.
- AC: whichever way it goes, the effective peak contribution is **computed from the sheet's own alpha
  times the rig's opacity**, not set by eye. Setting an opacity without reading the asset's alpha is
  exactly how this became invisible.
- AC: if they stay, they are exempted from nothing — they count against the fill ceiling in R272 like
  everything else, and on current numbers they dominate it.

## R274 (containment) — client render + generated art only

- AC: no `src/**` change, no wire change; asset map, manifest and spec registry regenerated;
  `title_assets --check` green; suites green.

---

## Correctness Properties

- **P135 (nothing per-frame):** the title screen runs no script per frame. Everything moves under
  emitter simulation or a looping tween, so the cost is bounded by the budget and the whole rig
  frees with its node.
- **P136 (depth lives in one table):** every depth-varying value for the banks is one ordered
  near-to-far table. A depth cue split across functions drifts the moment one is tuned.
- **P137 (the VP is derived):** the vanishing point used by the particle motion is read from the
  same measured camera the architecture and prop shears use — never a second, eyeballed one.

## Verification

- **V1 (R269):** capture; the altar is cold — no bloom, no sparks, no haze — and still reads as the
  lit end of the nave. Compared against the TD-077 capture.
- **V2 (R270/R271):** captures at two moments seconds apart; the banks differ in direction of
  travel, not just speed. Near-bank motion is radial from the VP.
- **V3 (R272):** the budget tool prints counts, layer count and estimated fill, and **fails** when a
  ceiling is exceeded — proven by exceeding one deliberately, as the fog-headroom test was.
- **V4 (R273):** `--reduced-motion` capture; every bank present, fully lit, still.
- **V5 (R274):** diff scoped `client/ specs/ docs/ tools/`; asset map + registry + `title_assets`
  green; suites green.

---

## Deliberately not in this spec

- **The room-creation and join screens.** The author has flagged that they look unrelated to the
  title screen — correctly; they are the TD-071-era plate-and-nave treatment. That is its own spec,
  queued behind this one at the author's direction ("polish the title screen first").
- **GPU particles.** The client runs the **GL Compatibility** renderer, and the whole project's
  particle work (the board's torches, this screen) is `CPUParticles2D`. Switching renderer-sensitive
  particle backends to chase throughput is a bigger decision than this spec, and at ≤120 particles
  the CPU cost is not the constraint — fill rate is, and that is identical either way.
