# Requirements — Mobile Touch Input v1

> Phase 5, spec 6. Testament runs on landscape phones (DECISION_LOG **TD-042**, the
> first record of mobile as a target). This spec gives the field a **floating movement
> stick** and a **contextual action cluster**, and adapts the station popups to a
> pointer that has no hover.
>
> **Canon this spec honors (do not re-litigate):**
> - *The client sends intentions; the server validates* (I1/I2). Touch introduces
>   **no new message** and **no new authority**.
> - *Affordance ≠ authority* (P62 heritage). A drawn button is a hint; a raced
>   `NOT_AT_*` / kit-gate refusal must still surface.
> - *`MOVE` is 8-directional for everyone.* Touch gains no precision the keyboard
>   lacks. `MovePayload { dx, dy, walk? }` is unchanged — **zero server change**.
> - *No knowledge as a number* (vision.md). The HUD reports the player's capability,
>   never the Incarnate's state.
>
> Design spines: `specs/mobile-input/ux-designs/ux-Testament-2026-07-10/DESIGN.md`
> (looks) + `EXPERIENCE.md` (works). Spines win on conflict. Numbering continues:
> **R129+** (plus R131a), correctness **P71+**, tasks **T148+**. All metrics are **logical pixels
> at 640×360** (TD-042).

---

## Phase A — Movement

**R129** (client): a **floating stick** owns the left movement zone and is invisible
until touched.
- AC: nothing is drawn in the zone at rest; on a touch beginning inside the zone the
  ring spawns **centred on the touch point**, clamped to stay inside the safe area.
- AC: the stick tracks **that finger's `index`** until it lifts; a second finger
  elsewhere never steers it.
- AC: release removes the stick **immediately** (no fade) and emits `MOVE {0,0}`.
- AC: opening any station popup dismisses the stick and zeroes movement (existing
  `_menu_open` freeze).

**R130** (client): stick geometry maps onto the **existing** `MovePayload`.
- AC: magnitude ≤ `STICK_DEADZONE` → `MOVE {dx:0, dy:0}` (a resting thumb stands still).
- AC: beyond the deadzone, angle quantizes to **one of 8 directions**:
  `dx, dy ∈ {-1,0,1}`, diagonals first-class. Pure function of the angle.
- AC: magnitude drives `walk`: inside the walk ring → `walk:true`; beyond → `walk:false`.
  A **hysteresis band** (enter run at 0.65 of radius, fall back at 0.55) prevents a
  thumb on the boundary from strobing the register.
- AC: the **angle** is hysteretic too — it must cross an octant boundary by a margin
  before re-quantizing. Without this, a thumb resting at ~22.5° dithers between two
  directions and emits a `MOVE` every frame (a wire-spam vector the keyboard cannot produce).
- AC: `MOVE` is emitted **only on change** of `(dx, dy, walk)` — the existing
  `_last_intent` / `_last_walk` diff. A held stick, **including one resting on an octant
  boundary or on the walk/run threshold**, sends nothing.
- AC: the octant table is authored for Godot's **Y-down** screen space:
  `[E, DR, D, DL, W, UL, U, UR]` with `D = (0, +1)`. `quantize8(Vector2(0, 10))` is
  `Vector2i(0, 1)` — the Seeker walks **down**.

## Phase B — Actions

**R131** (client): the **action cluster** draws a control only while its action is legal.
- AC: Interact exists iff a station is in range (`_active_station != ""`); **Probe** exists
  iff the bag carries **at least one** `PROBE`-kind item; Extract exists iff the Seeker is on
  the extraction tile.
- AC: legality is read from **snapshot state**, never from touch. No control is ever
  revealed by touching where it would be.
- AC: an illegal action draws **no control at all** (never a disabled or greyed button).
- AC: slot order is stable — a newly-legal action occupies its own reserved slot and
  **never displaces** an existing button.
- AC: slots for `ATTACK` and `DODGE` are reserved and **draw nothing**; no such intent
  exists on the wire (`docs/systems/combat.md` is design, not implementation).
- AC (**canon gate, outranks the legality rule**): when `ATTACK`/`DODGE` are populated they
  are gated on the **Seeker's capability** (kit/perception), **never** on the live state of
  any Incarnate sign. A `DODGE` control's presence must be **identical whether or not an Omen
  is firing** — otherwise the button's appearance *is* the Omen tell and the HUD performs the
  read the player must earn (Pillar 3; vision.md rule 2; R137/P76).

**R131a** (client): **Probe is a radial wheel on one stable slot.**
- AC: `ProbePayload` requires a `stimulus` and the server gates per-stimulus, so a Probe
  control **must name one**. A single slot with no stimulus is not implementable.
- AC: touch-**down** on the Probe button opens the wheel immediately — **no hold timer**.
- AC: exactly one wedge per **carried** stimulus, at **fixed cardinal angles** independent of
  bag contents: `FLAME` up, `COLD` right, `SALT` down, `LIGHT` left (`STIMULI`, `signs.ts:27`).
  An uncarried stimulus has **no wedge** (absent, never greyed).
- AC: dragging past `WHEEL_DEADZONE` highlights the wedge under the thumb and previews its
  caption; **release commits** `PROBE { stimulus }`.
- AC: **release inside `WHEEL_DEADZONE` cancels and sends nothing.** Probing spends exposure
  (`probe.ts:41`), so a bare tap must not spend it.
- AC: the wheel is **Probe-only**. `ATTACK`/`DODGE`, when they land, are instant-press.

**R132** (client): **affordance is not authority**.
- AC: pressing a control sends the existing intent and holds the **pressed** look until
  the server answers — it is **never disabled** while in-flight.
- AC: a server refusal (`NOT_AT_*`, `WRONG_PHASE`, kit gate, `NO_CONTRACT_SELECTED`)
  flashes the control to a **luminance** spike (`action_flash`, ~12:1), settles to
  `action_denied`, and routes the reason to the **toast**, in words, never a code. Wax red on
  stone is **1.26:1** and is never the signal by itself.
- AC: no client path mutates game state on press; only the intent is sent (I1/I2).

## Phase C — Touch adaptation of existing UI

**R133** (client): the Contract Board works without hover.
- AC: a **single tap** on a live notice opens the full-screen reader; there is no
  intermediate selection state.
- AC: the **hover-raise** interaction is removed; nothing depends on a resting pointer.
- AC: overlapping notices resolve by draw order — the topmost live notice wins the tap.
- AC: inert flavor notices remain inert under touch.

**R134** (client): multitouch routing is explicit.
- AC: the field HUD consumes raw `InputEventScreenTouch` / `InputEventScreenDrag`, keyed
  on finger `index`; it reads **no mouse events**.
- AC: stick and an action button can be held **simultaneously**, by different fingers.
- AC: `emulate_mouse_from_touch` stays enabled (station popup `Button`s depend on it).
  `set_input_as_handled()` does **not** suppress the independently-emitted emulated mouse
  event, so **no field-HUD control is ever a Godot `Button` wired to `pressed`** — all are
  `mouse_filter = IGNORE` and hit-tested manually from raw touch. Only popup controls, behind
  the dimmer, may be real `Button`s. (Otherwise one finger-0 tap fires the intent twice.)
- AC: the HUD's `_input` **early-returns while `_menu_open`**. `mouse_filter` does not stop
  `InputEventScreenTouch`, so the popup dimmer alone would let a tap spawn a phantom stick
  behind the panel.
- AC: `input_devices/pointing/emulate_touch_from_mouse` is **enabled** (default false), or the
  desktop playtest observes no touch events at all.
- AC: a touch beginning inside an action button is captured by it; otherwise a touch
  beginning in the movement zone owns the stick; touches elsewhere are ignored.

## Cross-cutting

**R135** (client / project): platform envelope.
- AC: orientation is **locked to landscape** (portrait is unverified — TD-042 — and has
  no layout).
- AC: both zones inset by `DisplayServer.get_display_safe_area()`; a notch is assumed.
- AC: every finger-operable control is at least
  `max(40, ceil(48 * screen_get_dpi()/160 / factor))` **logical px**, spaced ≥ 10. A fixed
  40 is **32dp at integer factor 2** and ~42dp on a dense iPhone — under both Material's 48dp
  and Apple's 44pt. The integer factor tracks pixel *height*, not density, so the floor must
  be derived at runtime. 40 is a lower bound, not a target.
- AC: **no control or readout occupies a bottom corner** (thumb occlusion). The status
  line moves to the toast.
- AC: the HUD anchors to fractions/insets and never assumes a 640px width — `PixelScale`
  yields 780×360 on a 19.5:9 phone, 800×360 on 20:9.

**R136** (client): input-scheme parity.
- AC: every touch affordance has a keyboard peer and vice versa; neither modality gains
  an intent the other lacks.
- AC: the proximity prompt renders `Press E — <Station>` under keyboard and the Interact
  button + caption under touch, from the **same** `_active_station` trigger.
- AC: the active scheme flips on the **last input event seen**, not on the platform (a
  phone with a Bluetooth keyboard behaves; a desktop with a touchscreen behaves).

**R138** (client): the **toast** is a specified component, not an assumption.
- AC: it is the **sole channel** for every server refusal, and is never suppressed or queued.
- AC: **one at a time** — a new message replaces the current and restarts its dwell (an error
  is current state, not a log). Auto-dismiss on dwell; a tap dismisses early.
- AC: it renders top-centre, within the safe area, never in a bottom corner, never over the
  centre reading strip; error toasts carry a `toast_rim` left rule, party notices do not.
- AC: `toast_ink` on `toast_face` is ≥ 4.5:1 (measured 8.9:1).

**R139** (client): cold-load and disconnect are defined states.
- AC: **before the first snapshot arrives, no action button is drawn** (legality is
  snapshot-derived; the cluster must not guess). The **stick is always available** — it is
  local input geometry, not snapshot-gated.
- AC: on socket loss the cluster clears, and the **toast states the connection is lost**.
  Movement is server-applied, so a stick that steers a Seeker who does not move must never
  read as a silently frozen game. Reconnection defers to `specs/lobby-resilience`.

**R140** (client / accessibility): the floor is measured, and its exclusions are named.
- AC: the walk/run register is distinguishable **by shape** (solid ring vs ticked outer rim),
  clearing 3:1 on form alone — gold-dim against gold-bright is **1.52:1** and cannot carry it.
- AC: reduced motion (F9) makes **every HUD control transition instant** — no button fade.
- AC: captions support an optional **integer** 2×/3× scale; fractional scaling is forbidden.
- AC: caption copy exists for each control's role/state. This is **not** screen-reader support
  — Godot 4.7 has no mobile a11y bridge, and these are custom `_draw` Controls. It must not be
  claimed as satisfied.
- AC (**named exclusion**): the stick and the wheel require a sustained press-and-drag. No
  one-handed mode, no deadzone/radius customisation, no switch path. This is a **conscious
  trade** (decision D7); the remedy (a latching "sticky" wheel + exposed settings) is designed
  and costed and needs **no wire change**. It is recorded, not hidden.

**R137** (trust / containment, standing I3/I5): the HUD narrates the player, never the
Incarnate.
- AC: no touch control or caption displays an Incarnate trait, sign readout, health bar,
  or any derived number about the target. The cluster reports capability only.

---

## Verification

The repo has **no GDScript unit harness today** — every prior client spec verified through
MCP playtests and `get_debug_output` logs. This spec **builds one** (T148) rather than citing
a convention that does not exist. Two mechanisms, both named in the tasks below:

1. **A boot self-check, built here as a first deliverable.** `quantize8` and `next_walk` are
   pure `static func`s with no scene dependency, so they are table-verifiable without
   instancing. In a debug build they assert against an authored table and log
   `touch selftest dirs=<n>/<n> hyst=<bool> ok=<bool>`. *(An earlier draft of this spec cited
   the notice board's `keepout seed=<s> ok=<bool>` as established precedent. It is not: that
   string appears only in `specs/notice-board/tasks.md` T145, which is unchecked and unbuilt.
   Recorded so the error is not repeated.)*
2. **An MCP-driven playtest**, `specs/mobile-input/playtest.md` items **M1–M8**, run
   against `pnpm dev:server`. Desktop verification of touch uses Godot's
   `emulate_touch_from_mouse` plus the `DebugCapture` harness
   (`docs/technical/dev-environment.md`); **multitouch (M4) and safe-area (M7) cannot be
   verified on desktop and require a device or emulator** — they are explicitly deferred
   to a device pass, not silently marked green.
