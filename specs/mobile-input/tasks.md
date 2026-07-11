# Tasks — Mobile Touch Input v1

> T# continues from T147 (notice-board). Order is dependency order (A → B → C); each
> phase is shippable. **Client-only** — no server or shared file is touched, so there is
> no Vitest file to name. Each task names either a **boot self-check log** (read via
> `get_debug_output`) or a **`playtest.md` item`**. The self-check harness does **not** exist
> yet — T148 builds it. Nothing is done without its named check passing.
>
> Metrics are **logical pixels at 640×360** (TD-042). Spines:
> `ux-designs/ux-Testament-2026-07-10/{DESIGN,EXPERIENCE}.md`. Findings from the Reviewer
> Gate (`validation-report.md`, 2 critical / 12 high) are folded in below.
>
> **Gate before T148 starts:** the notice board reaches a shippable stop, `CLAUDE.md`'s
> Active Work swaps to `specs/mobile-input`, and a DECISION_LOG entry records the switch.
> **T153 and notice-board T142–T147 both edit `_build_contract_board`** — coordinate.

## Phase A — Movement

- [ ] T148 [R130 / P72, P73] — **Build the boot self-check, then the geometry.**
      `client/scripts/input/geometry_selftest.gd` is a *real* new deliverable: the repo has
      **no client unit harness**, and an earlier draft of this spec wrongly cited one as
      precedent (`keepout seed=… ok=…` exists only in an unbuilt notice-board task).
      Then `client/scripts/input/floating_stick.gd`: `quantize8`, `quantize8_stable`
      (directional hysteresis), `next_walk`. Pure `static func`s, no node access.
      **The `OCTANT` table is authored for Y-down** — index 2 is DOWN.
      Test: `geometry_selftest.gd` asserts at boot in a debug build —
      `quantize8(Vector2(0,10)) == Vector2i(0,1)` (**push down, walk down**); every octant
      centre and both boundaries **±ε** (never the exact midpoint — `round()` is
      half-away-from-zero); below-deadzone → `ZERO`; a ratio swept 0.55→0.65→0.55 flips the
      register exactly **once** each way; an angle wobbling ±0.5° across a boundary does
      **not** change direction. Logs `touch selftest dirs=<n>/<n> hyst=true dir_hyst=true ok=true`.

- [ ] T149 [R129 / P71] — `client/scripts/input/touch_hud.gd` (CanvasLayer) + the stick's
      draw/lifecycle: invisible at rest; spawns centred on touch-down inside the left
      movement zone, clamped to the safe area; tracks that finger's `index`; instant
      removal on release. Emits into the single `MOVE` send path (refactored in T150) — no
      second `MOVE` producer. Dismissed on `_menu_open`.
      Verify: playtest **M1** (stick spawns under the thumb, steers 8-way, vanishes on
      release, `MOVE {0,0}` on release; opening a popup freezes the Seeker).

- [ ] T150 [R130 / P73, P71] — **Refactor `_send_move_intent`** to take
      `(dir, walk, active)` from whichever producer the input scheme owns, keeping the single
      `send_message(MOVE, …)` call site (it currently reads the keyboard directly via
      `_dir_axis`, so touch cannot "feed" it). Wire magnitude → the existing `walk` flag.
      Verify: playtest **M2** — the walk ring is **solid** and the Seeker slows; the run ring
      grows a **ticked outer rim**; a message counter over 5s of a held stick reads **0**
      sends, including with the thumb parked on an octant boundary.

## Phase B — Actions

- [ ] T151 [R131 / P76, P79] — `client/scripts/input/action_cluster.gd`: legality→controls
      from snapshot state (Interact / Probe / Extract), stable reserved slots, **no control
      drawn for an illegal action**, `ATTACK` + `DODGE` slots reserved and empty. Targets sized
      from `max(40, ceil(48 * screen_get_dpi()/160 / factor))`, 10px gaps, anchored to the
      right safe inset, out of the bottom corner. **No control is a Godot `Button`** (P80).
      Verify: playtest **M3** (walk into station range → Interact appears and is captioned;
      leave → it disappears; no greyed buttons; no Incarnate readout anywhere on the HUD).

- [ ] T151a [R131a / P78] — `client/scripts/input/probe_wheel.gd`: one stable Probe slot;
      touch-down opens the wheel (**no hold timer**) with one wedge per **carried** stimulus at
      fixed cardinal angles (`FLAME` up, `COLD` right, `SALT` down, `LIGHT` left); drag
      highlights + previews the caption; **release commits** `PROBE { stimulus }`; **release in
      the centre cancels**. Probe-only — never the cluster's default interaction.
      Test: extend `geometry_selftest.gd` — `wedge_at()` returns the right stimulus per
      cardinal, `""` inside the deadzone, `""` over an uncarried wedge; **no input produces a
      `PROBE` without a stimulus**. Logs `probe wheel wedges=<n> selftest ok=true`.
      Verify: playtest **M9** (two stimuli carried → two wedges; drag+release probes; centre
      release spends **no exposure**; an uncarried stimulus has no wedge).

- [ ] T152 [R132, R138, R139 / P75] — Press → send the existing intent; hold the **pressed**
      look while in-flight (never disabled); on a server refusal flash `action_flash`
      (**luminance**, ~12:1), settle to `action_denied`, and route a **translated** reason to
      the toast. Build the **toast component** (one at a time, replace + restart dwell,
      auto-dismiss, tap-to-dismiss, error rule). Move the status line out of the bottom corner.
      Implement **cold-load** (no buttons before the first snapshot; the stick is always
      available) and **disconnect** (cluster clears, toast states the connection is lost).
      Verify: playtest **M5** (two clients: a raced `NOT_AT_*` flashes the button and the
      toast reads it in words; the button was never disabled; no client state changed) and
      **M10** (kill the server mid-field → toast, cluster clears, no silent freeze).

## Phase C — Touch adaptation

- [ ] T153 [R133] — Contract Board without hover: a **single tap** on a live notice opens
      the full-screen reader; **remove the hover-raise**; topmost live notice wins an
      overlapping tap; flavor notices stay inert.
      Verify: playtest **M6** (tap opens the reader directly; no hover code path remains —
      a grep for `mouse_entered` in the board finds none; flavor tap does nothing).

- [ ] T154 [R134 / P74, P80] — Explicit routing: raw `InputEventScreenTouch`/`ScreenDrag`
      keyed on finger `index`; a control captures a touch beginning inside it, else the movement
      zone owns it; HUD root `mouse_filter = IGNORE`; **no field control is a `Button`** (the
      emulated mouse event is independent and would double-fire); `_input` **early-returns while
      `_menu_open`** (mouse_filter does not stop raw touch); enable
      `input_devices/pointing/emulate_touch_from_mouse` so the desktop items are runnable at all.
      Verify: playtest **M4** (**device or emulator only**) — stick and an action button
      held simultaneously by two fingers, neither cancelling the other; popup buttons still
      respond to a tap.

- [ ] T155 [R135, R136, R140 / P77] — Platform envelope + parity + a11y floor: landscape lock
      (`display/window/handheld/orientation="landscape"`), `get_display_safe_area()` insets,
      **dp-derived** targets, fraction/inset anchoring (never assume 640 width), reduced motion
      makes every HUD control transition **instant**, optional **integer** 2×/3× caption scale,
      and `input_scheme.gd` flipping on the **last input event** so the proximity prompt renders
      `Press E` or the Interact button from the same trigger.
      Verify: playtest **M7** (**device only**: safe-area insets, no control in a bottom
      corner) and **M8** (a Bluetooth keyboard on a phone flips the prompt back to `Press E`).
      Self-check asserts the touch-intent map and the keyboard-intent map have identical
      keys: logs `touch parity ok=true`.

## Cross-cutting

- [ ] T156 [R129–R137] — Full pass. Desktop items (M1, M2, M3, M5, M6, M8) via
      `emulate_touch_from_mouse` + `DebugCapture` against `pnpm dev:server`, two clients for
      M5. **M4 and M7 are device-only and must be run on a phone or emulator — they are not
      to be marked green from a desktop run.** Fix any GDScript errors; clean `stop_project`.
      Verify: `playtest.md` all items green (M4/M7 on device); server + shared suites still
      pass untouched (this spec changes no server file); `pnpm build` passes.
