# Tasks — The Quartermaster as a Room (TD-101)

> T# continues global from T368. Phases follow the author's brief.
> **Presentation + interaction only.** No `src/**` change; no second inventory.

## Phase 1 — Audit *(done before any code)*

- [x] T369 — **Audit the existing implementation and report.** Finding: the architecture is already
      right and three of the brief's phases are already built — `pack.fly_in()` runs at the brief's
      own timings, removal-by-click works, and `seal_rite.gd` is already a wax ceremony reusing
      TD-063's vocabulary. `lore.gd` already holds the ledger prose. So this is **the room, the
      objects, the counter and the frame** — not a rewrite.
      Three conflicts recorded with their resolutions: the reference is painted (composition only,
      per TD-075); `PROVISIONS/RELICS/TOOLS` do not exist (two real kinds); `Uses/Weight/Load` would
      reintroduce what TD-091 cut.

## Phase 2 — Environment structure

- [x] T370 [R361 / V1] — **The frame becomes full-screen.** One branch in `main.gd`'s station-popup
      sizing; every other station keeps the shared inset frame. Esc still steps back one layer (T146)
      and the pause menu still covers it (P146).
      Test: `--quartermaster` capture — no clipped text, no sliced row.
      **Done.** One `elif` branch; `CONTRACT_BOARD` and every other station are untouched.

- [x] T371 [R361] — **`gen_qm_room.py` emits the modular set**: wall, shelf frame, board, label
      plate, counter, stock atlas, prop atlas. Authored at display size on the Ash & Ember ramps
      (`navestone` reused, so this room and the Great Hall are the same building), `assert_on_palette`
      green. **No single painted room** (brief §17; TD-072 recorded that failure).
      Test: generator runs clean; `assert_on_palette` passes; headless `--import` registers the PNGs.
      **Done — 7 PNGs, all imported.** Four defects were caught by LOOKING at a 4× contact
      sheet before any code consumed them, which is the cheap place to catch them: the counter
      front was a polka-dot field (a modulo on `x*3+y` scatters dots; grain must run in lines),
      the label plate was diagonally hatched (an `(x+y)` modulo draws stripes), the scale's pans
      were one row tall and vanished, and two stock pieces used the cold `stone` ramp, which reads
      blue in a lamp-lit wooden room and pulled the eye harder than the real instruments.

- [x] T372 [R361] — **`room.gd` composes the environment** — wall, floor, two shelving units, the
      counter body, one lamp. Static after build; the lamp's flicker is a looping tween on `modulate`,
      not a particle emitter and not `_process`.
      Test: `--quartermaster` capture reads as a location, not a panel.
      **Done.** Tiling `navestone` ashlar, two shelving units, the counter, four props, one
      vignette. The candle flickers on a looping tween; **no `_process` and no emitter anywhere
      in the feature** (`grep` finds the words only inside comments).

## Phase 3 — Storage interaction

- [x] T373 [R362, R363, P166, P167] — **`shelf.gd` places objects.** The 10 instruments at positions
      **derived from catalog order** (never per-id), standing on boards with contact shadows;
      seeded non-interactive stock around them, visibly subordinate and refusing hover/focus.
      Test: capture shows 10 lit instruments among dimmer stock; a check asserts stock nodes have
      `MOUSE_FILTER_IGNORE` and `FOCUS_NONE` (P167), and that two openings render identically (P166).
      **Done, after one instructive bug:** the stock did not appear at all in the first build.
      `move_child(t, 0)` was meant to put it behind the instruments and put it behind the **wall**
      — index 0 is the backdrop, not the back of the shelf. Fixed by BUILD ORDER (stock first,
      instruments after), which is the predictable tool; z-shuffling after the fact is not.
      A second, upper board per unit carries stock only — one row left a band of dead black that
      read as an empty rack rather than a store.

- [x] T374 [R364, P164] — **Hover reads as being noticed** — small lift, slight brighten, shadow
      shift, name nearby. No outline, no glow, no particles. State is Godot state (`item_state`),
      never baked into a texture.
      Test: capture with a hovered instrument; the state machine's transitions are unit-checkable via
      a pure `next_state()` helper.
      **Built; not capture-verified** — an unattended capture cannot hover. `next_state()` is a
      pure function precisely so the machine is checkable without a scene.

- [x] T375 [R365, P165] — **Selecting carries the object to the counter** — lift 0.12 / carry 0.28 /
      settle 0.12, eased as a handled object. It leaves its shelf slot while on the counter, and
      selecting a second instrument **returns the first to its exact position** before carrying the
      new one. Reduced motion renders end states only.
      Test: `--qm-pick` capture; a second selection restores the first to the same pixel.
      **Done, and the first capture caught a real defect in the TEST, not the feature:**
      `--qm-pick` set `sel` and called `refresh()`, bypassing the carry — so the capture showed a
      filled record beside an object still standing on its shelf. The flag now calls the real
      `select()` path, and the capture proves the prism leaves its shelf slot and stands on the
      counter. Selection updates the record and the moved object only; the room is never rebuilt.
      **Must not rebuild the screen** — this is the defect TD-064, TD-065 and TD-068 each fixed once
      already; the Quartermaster must not become the fourth.

## Phase 4 — Inspection

- [x] T376 [R366 / V4] — **`record.gd` re-laid as a ledger entry**: icon, name, class, the question,
      the field note, the care line — all from `lore.gd`, **kept verbatim**. Carries the existing
      party fact and gate reason. **No Uses, no Weight, no Load** (TD-091, loadout-economy
      non-negotiable 2).
      Test: capture — authored prose present, no fabricated statistic anywhere.
      **Done.** `lore.gd` untouched. The body now scrolls inside the sheet with the action pinned
      beneath — and the sheet is a **PanelContainer, not a Panel**: a Panel does not lay out its
      children, so the first pass's anchored column ignored the content margin and the record's
      text ran off both edges of the paper. That is the trap `pack.gd` already carries a comment
      about, hit again in a new file.

## Phase 5 — Packing

- [x] T377 [R367] — **Pack flies from the counter**, not from the shelf row: `fly_in`'s origin is the
      object resting on the counter. Count updates when it **lands** (already the behaviour —
      preserve). Removing returns the instrument to its shelf position rather than blinking it out.
      Test: `--qm-full` capture; remove-then-reselect proves the object came back.
      **Done.** The flight starts from the counter, where the object actually is. A packed
      instrument is HIDDEN from its shelf rather than dimmed — the room is physical, and a thing
      cannot be in two places. The pack's compartments were also turned to run ACROSS: stacked,
      the case was half again as tall as its band and drew straight through the tally, and the
      clasp sitting inside the row read as a fifth slot.

## Phase 6 — Seal

- [x] T378 [R368] — **Preserve the seal ritual** — wax press, squash, BACK settle, rite banner. It
      commits **the pack**, not deployment; `seal_rite.gd` already says so and is correct. Re-aim the
      press at the new pack's clasp if the clasp moves.
      Test: seal capture unchanged in behaviour.
      **Done, and capture-verified.** `seal_rite.gd` is untouched; the wax presses onto the clasp
      in its new position beneath the compartments and the PACK SEALED banner rises.
      **The first attempt fired past a shut gate, and the capture said so.** `--qm-issuable` staged
      a contract but not a PHASE — `_station_open` reads both, and with no server there is no
      snapshot at all — so the counter was still closed while the rite played. The give-away was in
      the frame: the gate message was still printed under a sealed pack. Staging the phase too opens
      the counter properly (`SEAL & DEPART` enabled, gate message gone), which is the state a player
      actually seals from. New flags: `--qm-issuable`, `--qm-seal`.

## Phase 7 — Polish

- [x] T379 [budget / V6] — **Restrained atmosphere + the budget made real.** ≤20 dust particles in
      the lamp light, 0 full-frame additive layers, no `_process`, ≤90 nodes. `tools/qm_budget.py`
      enforces it with structural checks that bite against a broken copy (the `world_budget.py`
      pattern), not just a printed number.
      Test: `--selftest` proves each check fails when violated; live run reports within budget.
      **Done — `tools/qm_budget.py`, seven checks, `--selftest` green and each check proven to bite
      against a broken copy.** The node count is MEASURED at run time (`qm nodes=148/220`) because a
      static count of `.new()` calls misses every loop; the tool enforces that the ceiling exists,
      that the room compares itself against it, and that the number is printed at all.
      **The estimate in `requirements.md` was wrong and is corrected rather than excused:** ≤90 was
      a guess, 148 is the measurement, and the ceiling is now the measurement plus headroom.
      Structural checks: no `_process` anywhere in the feature, no full-frame additive layer, no
      undeclared emitter, and — the one this project keeps relearning — **`_select` must not
      re-enter `build()`** (TD-064, TD-065, TD-068 are three separate fixes for that same defect).
      It also carries a **coverage** check across the trust boundary: every catalog instrument has a
      record and the record table invents none. That seam is unreachable from either suite (the
      catalog is TypeScript, the prose is GDScript) and `Record.show_item` falls back to an EMPTY
      entry, so a missing record would ship as a silently blank ledger — the same shape of hole
      `lexicon_check.py` closes for signs.

## Phase 8 — Test

- [x] T380 [R369 / V6, V7] — **Prove containment.** `git diff` touches no `src/**`. The **Contract
      Board is captured from a stashed clean tree at HEAD and diffed** (control floor ≈ 0.47%) rather
      than judged by eye — TD-089 is why. Every item selected, packed, removed; full and empty pack;
      reopened twice; keyboard focus reaches shelf and pack.
      Test: suites still green (untouched), board diff within the noise floor, captures for each case.
      **Done.** `git diff` touches **no `src/**`**.
      **The clean-tree pixel diff was run properly**: a git worktree at the pre-TD-101 commit
      (`fe6b576`), imported and captured, against the current tree. **0.109% of pixels differ, and
      every one of them falls in x-bands 0 and 15 — the two torch gutters.** That is particle noise
      against a ~0.47% control floor, and the spatial confinement is the proof: not one differing
      pixel lies on a writ.
      **P166 measured, not asserted:** two openings of the room in separate runs differ by 155
      pixels, ALL of them in rows 716–719 — the shell's status line at the very bottom of the
      frame. The room itself is **pixel-identical**, so the seeded stock and derived placement do
      what they claim.
      **Still needs a human:** hover feedback and click-through of every item, because a capture
      cannot hover or click. That is the same standing gap TD-074 recorded for the board's seal
      split, not a new one.

## Do not re-invent

- **The inventory architecture already works.** `GEAR_CATALOG` → codegen → `Catalog` is the single
  source; nothing about an item is hard-coded in the presentation (R369).
- **The flight, the removal and the seal already exist** and are at the brief's own timings. Re-aim
  them; do not rewrite them.
- **`Light2D` cannot reach `Control`** (TD-047, re-confirmed TD-083). Light is baked; the lamp
  flickers via a looping tween.
- **The reference image is composition only** (TD-075). Testament renders at 640×360 NEAREST; TD-055
  already rejected hi-res/LINEAR UI art.
- **No Uses / Weight / Load.** TD-091 cut the Stipend; gear are keys, not power levels.
- **Never style via a cascading `Theme`** — TD-089 re-flowed every writ on the Contract Board that way.

## Standing constraints

Render + input only (I1/I2); no `src/**` change; determinism where it is claimed (P166); performance
budgeted in `requirements.md` before building, measured in T379.
