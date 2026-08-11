# Tasks — The Stores Gain Form (TD-115)

> T# continues global from T425. **Presentation only.** No `src/**` change.
> Tasks marked **[needs art]** are blocked on an author delivery — see
> [`asset-briefs.md`](asset-briefs.md). Everything else can ship without waiting.

## Phase 1 — What does not wait on art

- [x] T426 [R402 / V4] — **The seal-stamp drops to bench scale.** `PROP_DIV` becomes
      per-prop; the stamp reduces by four (37×57 → ~28×43), the quill and scale stay at
      three.
      Test: `--quartermaster` capture — the stamp sits beside the quill at a plausible
      desk size, and the scale and quill are pixel-identical to the previous capture.
      **Done.** `STAMP_DIV = 4`; the quill and scale keep `PROP_DIV = 3` and are
      byte-identical. 37x57 -> 28x42.

- [x] T427 [R403 / V5] — **The light goes moodier.** Wall ambient 0.22→0.13, candle
      0.44/0.90→0.34/1.05, lantern fill 0.34→0.22, vignette 0.26→0.38. Pools stay coupled
      to their fixtures (P95).
      Test: capture; mean frame luma measured before and after and reported as a number,
      not an impression; the record's text contrast re-measured and still ≥ 4.5:1.
      **Done, and the first attempt measured as a no-op — which is the finding.** The
      four numbers changed the WALL by -15% and the frame mean by -1.1%, because the
      author's furniture carries no shader and so is immune to the room's light. It ended
      up BRIGHTER than the wall behind it, the opposite of the brief. Fixed by giving the
      furniture a FLAT normal map (`qm_flat_n.png`): in `board_surface.gdshader` the lit
      term is `ndl * atten`, and with the normal straight out `ndl` varies with distance
      alone — so the art takes the pool's falloff and none of its direction, which is what
      keeps TD-081's double-shading trap shut. Measured after: frame 44.08 -> 38.89, wall
      48.2 -> 27.3, bench far from the candle 51.5 -> 26.4, bench AT the candle 55.9 ->
      81.4. The lit-to-shadow ratio went from **1.09 (flat) to 3.08**.
      Record text re-measured honestly — paper `#CCAB7D` vs ink `#524029` = **4.56:1**,
      above the 4.5 floor. An earlier 3.95 reading was a bad percentile proxy that swept
      in anti-aliased edges and the ornament rules.

- [x] T428 [R404, P181 / V6] — **Hover carries the light.** The existing gold edge gains
      a local brighten on the icon; mouse and keyboard focus drive the same handler. No
      tween, no state, no message, no movement (TD-103 retired the lift deliberately).
      Test: `--qm-hover` capture with an instrument hovered; `qm_budget.py` asserts the
      hover path sets no `view` state and calls no `on_*` intent.
      **Built; not capture-verified** — an unattended capture can neither hover nor
      focus. That is the standing TD-074 gap, not a new one.

## Phase 2 — The cabinet, rebuilt at 1:1

- [x] T429 [R397] — **`gen_qm_furniture` rebuilds the cabinet by repeating drawn bands:**
      one alcove+shelf band inserted full-width (166→199 tall), one backboard slice
      inserted inside each bay (166→240 wide). Never a scale factor.
      Test: generator runs clean; the emitted PNG is 240×199; a 4× contact sheet is
      **looked at** before any code consumes it — the cheap place to catch a bad seam,
      which is exactly how four defects were caught in T371.
      **Done.** 166x166 -> 240x199, by inserting one alcove+shelf band (rows 70-102)
      and one backboard slice inside each bay. Contact sheet looked at before wiring.

- [x] T430 [R397] — **Judge the drawer band.** The horizontal insert lands inside a
      drawer, so two of the four drawers become wider. If that reads badly, fall back to
      inserting a whole drawer unit and accept a wider bay.
      Test: the contact sheet from T429, looked at; the decision recorded here either way.
      **Resolved itself.** The column cuts landed on drawer dividers, so the cabinet
      gained two WHOLE drawers (4 -> 6) rather than widening two. No fallback needed.

- [x] T431 [R397, P182 / V1] — **Geometry is measured back off the emitted PNG** — shelf
      rows by their lit top edge, bay spans by their uprights — and `room.gd` consumes
      what was measured. `--qm-geometry` prints the found rows so a disagreement between
      art and placement is visible rather than silent.
      Test: printed rows match the design's table; capture shows four shelves per bay and
      three instruments per shelf, none clipped.
      **Done, and the check is real rather than asserted.** Measured off the emitted
      PNG: bays at x13 w104 and x125 w103; shelves 36/69/102/135 and 41/67/97/130.
      `qm_budget.py` now re-measures the PNG and compares it against room.gd's `CAB_PX`
      and `CAB_BAYS`, **proven to bite** against both a moved shelf row and a wrong
      `CAB_PX`. Instruments fill from the BOTTOM shelves up, three to a shelf; the
      shelves left over become stock.

## Phase 3 — Author art, as it lands

Each of these is **[needs art]** and independently shippable. Until the PNG exists the
room keeps the generated piece (P179), so these may be ticked in any order.

- [ ] T432 [R398, P180 / V2] — **The wall.** Grade + wire the delivered 128×128; derive
      its normal map from its own luminance; add a **tiling self-check** that compares
      column 0 against 127 and row 0 against 127 and fails on a seam.
      Test: `--selftest` proves the tiling check bites against a deliberately non-tiling
      copy; capture with `--lights-off` shows the diffuse's own drawn form.

- [ ] T433 [R399 / V3] — **The altar cloth.** Exactly 104×46 — the rest point and the
      caption both derive from that rect (P176).
      Test: capture; the inspected instrument still stands on the cloth, not beside it.

- [ ] T434 [R400 / V3] — **The rite plate.** 9-slice whose centre is a uniform field
      (TD-110's lesson, learned twice already); both states captured.
      Test: `--qm-issuable` and the not-issuable capture — subdued and gold, one object.

- [ ] T435 [R401 / V3] — **The satchel, the lantern and the banner.** The satchel is
      9-sliced, so its centre must be uniform for the same reason as T434.
      Test: `--qm-full` capture — the pack reads as leather with compartments; the lantern
      and banner read as objects.

- [ ] T436 [P179 / V8] — **Prove the degrade path.** With every briefed PNG temporarily
      renamed away, the room still builds and captures with no error.
      Test: a run with the sources absent; then restored and re-captured.

- [ ] T437 [TD-070's rule] — **Retire each generated painter only once its replacement
      has landed and been captured** — the output, the painter and its table entries
      together. Verify by grepping the generators, not by trusting the orphan list: the
      asset map cannot see producers that write through a table (the TD-113 finding).
      Test: generators re-run; nothing reappears; no live art byte changes.

## Phase 4 — Prove it

- [ ] T438 [R405 / V7] — **Containment.** `git diff` touches no `src/**`. The Contract
      Board's `keepout` readout is unchanged. `qm_budget.py --selftest`,
      `asset_map.py --selftest` and `--check` green; the node/particle count printed and
      within budget; P166 re-measured across two openings.

- [ ] T439 — **DECISION_LOG.** Add the TD-115 entry. **Separately: TD-111 through TD-114
      are cited in eleven commits and none exist in the log** — its last entry is TD-110.
      TD-113/TD-114 are this session's and get written; TD-111/TD-112 predate it and need
      whoever did that work.

## Do not re-invent

- **`Light2D` cannot reach `Control`** (TD-047, re-confirmed TD-083). Light is the
  surface shader's rig or it is baked. This spec does not relitigate that.
- **A 9-slice may only stretch a uniform centre.** The altar cloth and the record's
  divider each taught this once (TD-110); the rite plate and the satchel are the next two
  places it applies.
- **Never scale pixel art to resize it.** Rebuild it at 1:1 (TD-050/TD-055) — which is
  what T429 does.
- **Never style via a cascading `Theme`** — TD-089 re-flowed every writ on the Contract
  Board that way.
- **The grade has one door.** All author art goes through `gen_qm_furniture.py` (P178).

## Standing constraints

Render + input only (I1/I2); no `src/**` change; determinism where it is claimed (P166);
performance budgeted in `requirements.md` before building, measured in T438.
