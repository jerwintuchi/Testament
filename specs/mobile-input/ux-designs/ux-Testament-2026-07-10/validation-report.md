# Validation Report — Testament (Mobile Input)

**Spine pair:** `specs/mobile-input/ux-designs/ux-Testament-2026-07-10/{DESIGN,EXPERIENCE}.md`
**Lenses run:** rubric walker · accessibility · input-scheme & engine feasibility · canon & trust boundary
**Date:** 2026-07-10

---

## Synthesis

The spine pair is **mechanically excellent and substantively holed**. Every token resolves,
every source is on disk, section orders are canonical, and the trust-boundary claim
("zero server change") is *literally* true — no task touches `src/server` or `src/shared`,
and `MovePayload.walk` already exists on the wire. The client-side legality recompute is a
legitimately precedented render hint (`_active_station = _nearest_station()`, main.gd:677),
not I1 game logic.

What fails is not the architecture but three things the spec asserted without checking. It
**invented a testing convention** and cited it as established precedent, leaving its first
task with no real verification mechanism. It **specified a Probe button that cannot form a
legal wire message**, because `ProbePayload` requires a `stimulus` the single-slot design has
no way to choose. And its **accessibility floor does not hold**: the two colour pairs carrying
the HUD's most important state changes — the walk/run register (1.52:1) and the server-refusal
flash (1.26:1) — fail the WCAG 3:1 non-text threshold badly enough to be invisible, while the
"40 logical px ≈ 48dp" tap claim is true only at exactly integer factor 3 on a ~400dpi phone.

One deeper risk is latent rather than present. The reserved `DODGE` slot inherits the
cluster's founding doctrine — *a control exists only while its action is legal* — and
`combat.md` gates dodging on **reading the Omen**. Applied literally by a future implementer,
the button's appearance becomes the Omen tell, and the HUD performs the read the player was
supposed to earn. That is Pillar 3 defeated by an affordance. It is not a bug today (the slot
draws nothing) and it is cheap to fence off now, while the grammar is being written.

**Severity totals: 2 critical · 12 high · 15 medium · 23 low.**

| Rubric dimension | Verdict |
|---|---|
| 1. Flow coverage | strong |
| 2. Token completeness | strong |
| 3. Component coverage | **thin** |
| 4. State coverage | adequate |
| 5. Visual reference coverage | adequate |
| 6. Bloat & overspecification | adequate |
| 7. Inheritance discipline | strong |
| 8. Shape fit | strong |

---

## Critical

**C1 — The cited boot self-check precedent does not exist.** *(canon)*
`requirements.md:119` and `tasks.md` T148 hang the spec's only unit-level verification on
"the precedent set by the notice board's `keepout seed=<s> ok=<bool>`". That string appears
in exactly one place in the repo: `specs/notice-board/tasks.md:165` — an **unchecked `[ ]`,
unbuilt task**. No self-check harness exists in any client code. The spec invented a
verification mechanism and back-dated it as convention, so under `.claude/rules/spec-workflow.md`
("nothing is done without a passing test named in the task") **T148 has no real test**.
*Fix:* either build the self-check as a first, real deliverable and stop calling it precedent,
or verify `quantize8` / `next_walk` through the established MCP-playtest + `get_debug_output`
path. Do not mark T148 done against a harness the repo has never run.

**C2 — The Probe cluster button cannot produce a valid `PROBE` payload.** *(input-scheme)*
`ProbePayload = { stimulus: Stimulus }` (`fieldMessages.ts:19`), and the server gates
per-stimulus (`hasProbeKit(sender.bag, stimulus)`, `probe.ts:32`). The existing field UI
correctly draws **one button per stimulus** (`main.gd:474–478`). The design collapses this to
a single Probe slot gated on "carries any PROBE-kind item" — which has no stimulus to send.
*Failing case:* a Seeker carrying Censer(FLAME) + Salt(SALT) taps the one Probe button; the
client cannot choose, so it sends a malformed `PROBE {}` (rejected) or silently picks one.
*Fix:* either N Probe slots (one per **carried** stimulus — contradicts the "one stable slot"
grammar and eats cluster space) or a stimulus chooser on tap (reintroduces the multi-step tap
the design rejects elsewhere). **Unresolved on both spines. Must be designed before T151.**

---

## High

**H1 — The `DODGE` reserved slot points at a Pillar-3 violation.** *(canon)*
D1/R131 bind the cluster to *appearance == legality*. `combat.md:29–30,40` gates dodge on
reading the Omen. A future implementer applying R131 literally draws DODGE during the live
Omen window, making the button's presence the Omen tell — a Sign readout by another name,
forbidden by `vision.md` rule 2, Pillar 3, and the spec's own R137/P76. The safe answer is
already latent in Flow 3 ("Vidal, **who carries the perception to read it**"), but the binding
grammar says the opposite and nothing states which wins.
*Fix:* record now, in R131 or a new R — *the ATTACK/DODGE slots, when populated, are gated on
the Seeker's **capability** (kit/perception), never on the live state of any Incarnate sign.
DODGE is drawn iff the Seeker carries the perception to read the Omen; its presence is
identical whether or not an Omen is firing.*

**H2 — The octant comment will invert vertical movement.** *(input-scheme)*
`design.md` `quantize8` carries `# 0..7, E counter-clockwise`. Godot screen space is **Y-down**,
so increasing `Vector2.angle()` sweeps visually *clockwise*. *Failing case:* thumb pushed
straight down → `angle()=+PI/2` → octant `2`; a Y-up-authored table returns `Vector2i(0,-1)`
and the Seeker walks **up**. The arithmetic is right; the comment is wrong and will be trusted.
*Fix:* delete "counter-clockwise"; author `OCTANT = [E, DR, D, DL, W, UL, U, UR]` with `D=(0,1)`;
assert `quantize8(Vector2(0,10)) == Vector2i(0,1)`.

**H3 — "A held stick sends nothing" is false; direction spam is unbounded.** *(input-scheme)*
Hysteresis is applied to walk/run only, never to direction. *Failing case:* thumb resting at
≈22.5° (the E/DR boundary) micro-wobbles ±0.5° per frame; `v` alternates `(1,0)↔(1,1)` and a
`MOVE` is sent **every frame**. The keyboard has no analogue, so touch introduces a wire-spam
vector the spec claims it eliminated (R130 AC, P73).
*Fix:* add directional hysteresis — require the angle to cross an octant boundary by ±N°
before re-quantizing.

**H4 — `set_input_as_handled()` does not suppress the emulated mouse event.** *(input-scheme)*
With `emulate_mouse_from_touch` on, a finger-0 touch generates an **independent**
`InputEventMouseButton`; marking the touch handled does not cancel it. *Failing case:* Extract
implemented as a themed `Button` → one right-thumb tap sends `EXTRACT` **twice**. The scheme
works only if field-HUD controls are `mouse_filter=IGNORE` and hit-tested manually — a
discipline the spec never states.
*Fix:* state as an invariant that field-HUD controls are never Godot `Button`s wired to
`pressed`; only popup controls (behind the dimmer) may be.

**H5 — `touch_hud._input` must gate on `_menu_open`.** *(input-scheme)*
`mouse_filter` governs mouse/GUI propagation only and has **no effect on
`InputEventScreenTouch` delivery**. The popup dimmer therefore does not stop raw touch.
*Failing case:* open Quartermaster, tap the left half of the panel → a phantom stick ring
spawns *behind* the dimmer and two CanvasLayers contend for the finger.
*Fix:* early-return from `touch_hud._input` whenever `_menu_open`, mirroring the existing
`_send_move_intent` guard.

**H6 — The tap-target floor does not hold across devices.** *(accessibility)*
40 logical px is a *pixel-count* constant, but the integer factor tracks `viewport_height/360`,
not density. Verified: **48.0dp only at factor 3 + 400dpi**; **41.9dp on an iPhone 13 Pro Max**
(under Apple's 44pt); **32dp at factor 2 / 400dpi**. The authored `action_size` of 44 is only
35dp at factor 2.
*Fix:* derive the minimum at runtime from `DisplayServer.screen_get_dpi()`, clamping to
`ceil(48 * dpi/160 / factor)` logical px. Keep 40 as a lower bound, not the target.

**H7 — The refusal flash is nearly isoluminant (1.26:1).** *(accessibility)*
`action_denied` #8F2F2A on `action_face` #3C4248 = **1.26:1** against a 3:1 requirement.
Priority is inverted: the low-stakes *press* ack is ~12:1 (screams) while the high-stakes
*refusal* is a whisper. For a protanope the red collapses further toward the stone.
*Fix:* make refusal a **luminance** event, not a hue event — flash to a bright value, or
invert to a light face with a red glyph.

**H8 — The walk/run register is colour-only and fails 3:1 (1.52:1).** *(accessibility)*
`gold.dim` vs `gold.bright` = **1.52:1**. This directly contradicts `EXPERIENCE.md`'s own claim
that "colour is never the only channel," and the register feeds field pressure (D3) — it is not
cosmetic. Its stated backup is a haptic tick with no toggle (see H10).
*Fix:* give the registers a **shape/geometry** difference — solid inner ring for walk, a second
concentric or ticked rim for run — so the register clears 3:1 on form, independent of colour.

**H9 — No motor accommodations exist.** *(accessibility)*
No one-handed mode, no stick-size / deadzone / position customisation (hardcoded constants),
no remapping, no switch/AssistiveTouch path. A floating stick **requires a sustained drag**,
hostile to tremor, limited grip endurance, or one usable hand.
*Fix:* expose deadzone and radius as settings; offer a fixed-stick option; document a switch
fallback even if deferred.

**H10 — Haptics are load-bearing with no in-app control.** *(accessibility)*
`EXPERIENCE.md` Game Feel makes the boundary tick *the* way "the register is felt, not read,"
while `design.md` defers haptics to a device pass. No toggle, no intensity, no guaranteed
motor. With system haptics off, the register has **no** distinguishable cue (its visual channel
already fails at 1.52:1).
*Fix:* add an in-app haptics toggle; never let haptics solely carry a gameplay-relevant state.

**H11 — The screen-reader claim is not implementable in Godot 4.7 on mobile.** *(accessibility)*
`EXPERIENCE.md` Accessibility Floor promises captions "bound to role and state, so a screen
reader can name a control." Godot 4.7 has no TalkBack/VoiceOver bridge (its AccessKit work is
desktop-scoped), and the HUD controls are custom `_draw` Controls exposing nothing to any
accessibility tree.
*Fix:* soften to what is true — caption *text* exists per control's role/state, positioning a
future glyph-free mode — and do not count it as a satisfied line item.

**H12 — The Toast has no component row and no colour token.** *(rubric)*
It is referenced in the IA table, Voice & Tone, State Patterns, and both flows; it is the sole
channel for every server "no" — the entire P62 story. It has **no row in DESIGN.md.Components,
no row in EXPERIENCE.md.Component Patterns, and no palette**. Dwell, stacking, dismiss, and max
width are all unspecified.
*Fix:* add a `toast` component to both spines (visual: face/ink/width/duration; behavioral:
queue vs replace, auto-dismiss, tap-to-dismiss).

---

## Medium

- **M1** *(a11y)* `action_rim` passes 3:1 by only 0.17 (**3.17:1**). Redundant with
  presence + a 6.58:1 glyph, so acceptable — but never rely on the rim alone.
- **M2** *(a11y)* Tap-to-move was rejected to protect **a combat window that does not exist**.
  `ATTACK`/`DODGE` have no wire intent. An accessibility affordance is being denied today on
  the strength of an unbuilt system. *Fix:* reconsider tap-to-move as an a11y option now,
  auto-disabling once a timed dodge ships.
- **M3** *(a11y)* Nothing teaches the player the invisible left zone exists; first-run is
  unspecified. *Fix:* one-time dismissible ghost-stick cue.
- **M4** *(a11y)* The reduced-motion lever does not cover HUD control transitions — Flow 1
  has the Interact button "fade in" while DESIGN.md forbids the stick fading. Reconcile, and
  fold control transitions under the lever.
- **M5** *(a11y)* "Warm = agency" is a hue+brightness channel; keep presence/absence and shape
  as primary, treat warmth as decoration.
- **M6** *(a11y)* No path to larger text for low-vision players. Integer-only (2×/3×) caption
  scaling is the canon-compatible escape and must be sanctioned explicitly.
- **M7** *(canon)* "The stick is the only circle" never pins **how the circle renders**. A
  runtime `draw_circle` yields anti-aliased vector edges, violating Nearest/pixel canon
  (TD-033). *Fix:* palette-locked pixel assets or a deliberately pixel-stepped draw.
- **M8** *(canon)* **Resolution drift via `inherits:`** — the caption size is inherited from the
  notice-board spine, whose `min_glyph` is authored at **480×270**, superseded by TD-042's
  640×360. Every *spatial* metric was re-authored; the font token silently was not.
- **M9** *(input)* `_send_move_intent` is keyboard-hardcoded (`Input.is_physical_key_pressed`
  via `_dir_axis`); "feeds the existing send path" is not a drop-in. Needs a refactor to
  `(dir, walk, active)` plus a modality-arbitration rule, or P71's "no second MOVE producer"
  is at risk.
- **M10** *(input)* `emulate_touch_from_mouse` is **not set** in `project.godot` (default false),
  so the desktop playtest items M1/M2/M3/M5/M6 are **un-runnable as written**.
- **M11** *(rubric)* Component-list divergence: **full-screen reader** has an EXPERIENCE pattern
  but no DESIGN component; **caption** is the reverse; **toast** is in neither.
- **M12** *(rubric)* No **cold-load / first-frame** state. The cluster is 100% snapshot-driven —
  what is drawn before the first snapshot? *Fix:* no action buttons until first snapshot; the
  stick is always available (local geometry, not snapshot-gated).
- **M13** *(rubric)* No **offline / disconnect** state. Movement is server-applied; if the socket
  drops, the stick moves a Seeker that does not move, and the game reads as frozen with no
  explanation.
- **M14** *(rubric)* `inherits:` is not a legal `DESIGN.md` frontmatter key and resolves nothing
  (all values are copied). Fold into `sources:` or drop.
- **M15** *(rubric)* Cross-spine duplication: EXPERIENCE.md "HUD & Diegetic UI" re-derives
  DESIGN.md "Brand & Style". Its only new load-bearing rule is "no HUD element narrates the
  Incarnate." Cut to that rule.

---

## Low

- *(a11y)* 1px outline is 2 physical px at factor 2; consider scaling with the factor.
- *(a11y)* `stick_knob` / `stick_ring` = 3.85:1 — passes; no action.
- *(a11y)* Legality-driven appearance gives no persistent map of what is possible; acceptable
  under the mystery pillar, but it raises the new-player cognitive floor.
- *(a11y)* Haptics battery/comfort handling is otherwise sound ("nothing on movement").
- *(input)* `walk_threshold: 0.60` in DESIGN.md contradicts the implemented 0.55/0.65 band —
  the code is right; the table misleads.
- *(input)* Self-check boundary rows must respect GDScript `round()`'s half-away-from-zero
  rule; test boundary±ε, not the exact midpoint.
- *(input)* The ring reports **intent**, not server speed. Cannot desync today (no server
  walk-rejection path), but would lie if a server clamp were ever added.
- *(canon)* "Station" is used as canonical vocabulary but is not a GLOSSARY term (repo-
  established in `specs/collegium`; drift, not invention).
- *(canon)* **Extract-button-reveals-the-tile** — examined and **ruled acceptable**: Extraction
  is a visible authored site node, already position-gated server-side, and symmetric with the
  committed "Press E" station prompt.
- *(canon)* CLAUDE.md Active Work is stale (points at `specs/station-ui`); pre-existing.
- *(rubric)* No flow exercises Probe or Extract — the diagnosis loop is Testament's core verb.
- *(rubric)* Flow 3 is explicitly unreachable; label it "Reserved (not testable)" so nobody
  files it as coverage.
- *(rubric)* Action-cluster **arc geometry** is soft: radius, anchor, slot count, and the fixed
  slot order that "muscle memory is a promise" depends on are unpinned.
- *(rubric)* "Spines win on conflict with any mock" is dead boilerplate — no artifacts exist.
- *(rubric)* DESIGN.md omits the spec-required `name`/`description` (house-style deviation,
  consistent with the notice-board spine).
- *(rubric)* Cluster keyboard-focus behaviour is ambiguous: touch-only, or focusable with a ring?

---

## Verified-compliant (fenced off; do not re-litigate)

- **"Zero server change" is literally true.** No task T148–T156 touches `src/server` or
  `src/shared`. `MovePayload { dx, dy, walk? }` already carries `walk` (`fieldMessages.ts:26`).
- **Client-side legality recompute is a render hint, not I1 game logic** — same class as the
  committed `_active_station = _nearest_station()` (`main.gd:677`) driving the "Press E" prompt.
- **`next_walk` hysteresis is correct, not inverted.** The 0.55–0.65 band latches.
- **`quantize8`'s negative `& 7` two's-complement wrap is correct.** West (`+PI`) lands on
  index 4 unambiguously. *(Correctness is conditional on the Y-down table — see H2.)*
- **`display/window/handheld/orientation` is the right Godot 4.7 key** (value `"landscape"`),
  and does not conflict with `PixelScale`'s `size_changed` handler.
- **`quantize8` / `next_walk` are pure `static func`s** with no scene dependency — table-
  verifiable without instancing. T148 is feasible *as engineering*; only its cited precedent is false.
- **Extract legality is knowable client-side** (`_field_site["nodes"]` + `_nearest_station`).
- **`walk` cannot desync** under normal operation (server-authoritative speed, ordered `MOVE`).
- **Hover-raise removal (T153) targets real code** (`main.gd:1010,1408`) — runnable, not speculative.
- **Haptics and captions introduce no tool** outside the TD-033 CLOSED LIST (they are Godot
  runtime features, not authoring tools).
- **Not switching the active spec was correct** per `spec-workflow.md`; the swap plus a
  DECISION_LOG entry must land before **T148 begins**.
- **Token/source mechanics are clean:** 7/7 sources resolve, 12/12 `{token}` refs, 17/17
  backtick tokens, 8/8 inherited hexes match. Zero missing-hex, zero broken cross-refs.

---

## Canon tensions (conscious trades, not defects)

1. **Fixed logical-px sizing vs per-device dp.** The integer-scale canon makes a fixed logical
   tap target attractive, but dp then swings with density and factor. **The HUD is the one
   declared non-diegetic surface, so it need not be grid-locked** — sizing fingers from physical
   dpi is compatible with canon. Otherwise the project knowingly ships sub-standard targets on
   dense and factor-2 devices.
2. **Palette-locked Ash & Ember vs contrast thresholds.** "No new colour" forces the register and
   the refusal to be brightness steps inside one ramp, and those steps fail 3:1. The palette
   cannot buy the contrast; **shape** (register) and **luminance** (refusal) can, inside the lock.
3. **One pixel-font size vs low-vision text.** Irreducible for body text. Integer-only 2×/3×
   caption scaling preserves the grid and is the sanctioned escape — but the current wording
   ("no sub-font scaling") reads as forbidding it, so it must be named explicitly.
4. **Mystery vs first-run discoverability.** "The empty screen is the design" competes with
   teaching a new player that an invisible zone exists. A one-time dismissible cue costs the
   mystery nothing after first contact.

---

## Blocking gate before T148

1. Resolve **C1** (a real test mechanism for T148) and **C2** (the Probe/stimulus design).
2. Record **H1**'s capability-gate rule while the cluster grammar is being written.
3. Land the active-spec swap + DECISION_LOG entry; coordinate **T153** against notice-board
   **T142–T147**, which edit the same `_build_contract_board` code.


---

## Resolution ledger (amended 2026-07-10, after developer decisions D5–D8)

| ID | Finding | Status |
|---|---|---|
| **C1** | Invented self-check precedent | **Fixed** — T148 now *builds* the harness as a real first deliverable; the false precedent claim is deleted and the error recorded in `requirements.md` Verification. |
| **C2** | Probe button can't name a stimulus | **Fixed** — new **R131a**: a four-wedge Probe wheel (press → drag → release), one stable slot, `PROBE { stimulus }` always well-formed. New **P78**: no code path can send `PROBE {}`. |
| **H1** | DODGE slot → Omen tell | **Fixed** — R131 AC + `EXPERIENCE.md`: `ATTACK`/`DODGE` are **capability-gated, never sign-gated**; presence identical whether or not an Omen fires. Outranks "draw only when legal". New **P79**. |
| **H2** | Y-axis comment inverts movement | **Fixed** — `OCTANT` authored explicitly Y-down; the misleading comment is gone; P72 asserts `quantize8(Vector2(0,10)) == Vector2i(0,1)`. |
| **H3** | Direction dither spams the wire | **Fixed** — `quantize8_stable` adds directional hysteresis (`ANGLE_HYST`); R130 AC and P73 restated. |
| **H4** | Emulated-mouse double-fire | **Fixed** — invariant: no field-HUD control is a Godot `Button`; all are IGNORE + manually hit-tested. New **P80**. |
| **H5** | Raw touch reaches HUD under a popup | **Fixed** — `touch_hud._input` early-returns while `_menu_open`. |
| **H6** | Tap floor fails off factor-3 | **Fixed** — `tap_min = max(40, ceil(48 * dpi/160 / factor))`, derived at runtime. |
| **H7** | Refusal flash 1.26:1 | **Fixed** — refusal is a **luminance** spike (`action_flash`, ~12:1) settling to red. |
| **H8** | Register colour-only, 1.52:1 | **Fixed** — register encoded in **shape** (solid ring vs ticked rim). |
| **H9** | No motor accommodations | **ACCEPTED RISK (open)** — decision **D7**: press-drag-release only. Logged as a conscious exclusion in `EXPERIENCE.md` (R140 AC) with the remedy designed and costed. Revisit before a wide-audience release. |
| **H10** | Haptics load-bearing, no toggle | **Mitigated** — haptics are no longer the register's only non-visual channel (shape now carries it). An in-app toggle remains outstanding with H9. |
| **H11** | Screen-reader claim unimplementable | **Fixed** — claim softened; explicitly *not* counted as satisfied. |
| **H12** | Toast unspecified | **Fixed** — `toast` is now a component on both spines, with colours (8.9:1) and behaviour (**R138**). |
| M1–M15 | see above | Mostly fixed: contrast table stated, `inherits:` folded into `sources:`, caption re-authored at 640×360, circle rendering pinned to pixel assets, cold-load + disconnect states added (**R139**), `emulate_touch_from_mouse` enabled, diegesis section trimmed, `name`/`description` added. **M2 (tap-to-move as a11y option)** is bundled into the H9 accepted risk. |

Everything above is spec-level. **No code has been written**, and the gate before T148
(active-spec swap, DECISION_LOG entry, `_build_contract_board` coordination with the notice
board) is unchanged.
