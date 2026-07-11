# Playtest — Mobile Touch Input v1

> Items **M1–M10**. Desktop items run under Godot's `emulate_touch_from_mouse` with the
> `DebugCapture` harness (`docs/technical/dev-environment.md`), against a backgrounded
> `pnpm dev:server`. **M4 and M7 are device-only.** A desktop run cannot observe two
> fingers or a notch; marking them green from a desktop is a lie and is forbidden.
>
> ```bash
> pnpm dev:server &                                   # ws://localhost:3001
> GODOT='/mnt/d/Godot_v4.7-stable_win64.exe'
> CLIENT='\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client'
> "$GODOT" --path "$CLIENT" --quit-after 3600         # F12 captures a frame
> ```
>
> `input_devices/pointing/emulate_touch_from_mouse` must be **enabled** (default false) or a
> desktop mouse emits no `InputEventScreenTouch` and every desktop item below observes nothing.

---

## Desktop-verifiable

**M1 — the stick is where the thumb is** (T149, R129)
- At rest nothing is drawn in the left zone. Capture confirms an empty HUD.
- Press anywhere in the left ~45%: the ring appears **centred on that point**, not at a
  fixed spot. Press near the screen edge: the ring **clamps** inside the safe area.
- Drag: the Seeker moves in the matching one of 8 directions, diagonals included.
- Release: the stick disappears **instantly** (no fade); `MOVE {0,0}` is sent.
- Open a station popup: the stick vanishes and the Seeker stops.
- Pass: `touch stick spawn=<x,y> dir=<dx,dy>` logs; capture shows no ghost ring.

**M2 — the ring is the speedometer** (T150, R130 / P73)
- Push the stick partway: the ring is **solid**, the Seeker **walks** (server applies
  `WALK_SPEED`; the client never sets speed).
- Push to the edge: the ring grows a **ticked outer rim**, the Seeker **runs**. The register
  is legible by **shape**, not by brightness (gold-dim vs gold-bright is 1.52:1).
- Rest the thumb exactly on the walk/run boundary and hold: the register **does not strobe**.
- Rest the thumb exactly on an **octant boundary** (~22.5°) and hold: the direction **does not
  dither**, and the `MOVE` counter does not grow.
- Push straight **down**: the Seeker walks **down** (Y-down octant table).
- Pass: `touch selftest dirs=<n>/<n> hyst=true dir_hyst=true ok=true` at boot;
  `move sends=<n>` shows no growth while held.

**M3 — controls exist only when legal** (T151, R131 / P76)
- With nothing in range: the right side is **empty**. No greyed buttons, no placeholders.
- Walk into Contract Board range: an **Interact** button appears (it does **not** fade —
  reduced motion makes control transitions instant), captioned *Contract Board*, at least
  `max(40, ceil(48 * dpi/160 / factor))` logical px, not in a bottom corner.
- Walk out: it disappears.
- No `ATTACK` or `DODGE` button is drawn anywhere, in any state.
- No HUD element shows an Incarnate trait, sign, health bar, or any number about the target.
- Pass: `cluster legal=[INTERACT]` logs; capture shows an empty right zone at rest.

**M5 — a refusal is the server's, and it shows** (T152, R132 / P75) — *two clients*
- Stand at the edge of a station so the client draws Interact, then step off as you tap.
- The button **holds pressed** while in-flight; it is **never disabled**.
- The server answers `NOT_AT_*`: the button flashes to a **bright luminance spike**, settles
  to wax red, and the **toast reads the reason in words** (not a code). The flash must be
  visible as a *brightness* change — red-on-stone alone is 1.26:1 and would be invisible.
  No client state changed.
- Repeat for a kit-gated Probe: the refusal surfaces identically.
- Pass: `intent <NAME> refused=<CODE>` logs; toast visible in the capture.

**M6 — the board works without hover** (T153, R133)
- A **single tap** on a live notice opens the full-screen reader. No intermediate select.
- Tapping where two notices overlap opens the **topmost** live one.
- Tapping a flavor notice does **nothing**.
- `grep -rn "mouse_entered\|hover" client/scripts/main.gd client/scripts/ui/` returns no
  board hover-raise path.
- Pass: `board tap open=<contractId>` logs; reader fills the screen.

**M8 — the prompt follows the last input** (T155, R136 / P77)
- With touch: the proximity prompt renders the **Interact button + caption**.
- Press a key: the prompt becomes **`Press E — <Station>`** without restarting.
- Touch again: it reverts. The trigger (`_active_station`) never changed.
- Pass: `scheme=<TOUCH|KEYBOARD>` logs on each flip; `touch parity ok=true` at boot.

**M9 — the Probe wheel** (T151a, R131a / P78)
- Carry exactly two probe items (e.g. Censer of Embers + Consecrated Salt). The cluster shows
  **one** Probe control, not two.
- Press it: the wheel opens **immediately** — no hold delay. Two wedges: `FLAME` up, `SALT`
  down. `COLD` and `LIGHT` have **no wedges**.
- Drag up: the `FLAME` wedge lights and the caption previews it. Release → `PROBE {FLAME}`.
- Press again, slide back to the **centre**, release: **nothing is sent**, and the exposure
  readout is **unchanged**. A bare tap likewise sends nothing.
- Drag over an absent wedge (`COLD`) and release: nothing is sent.
- Pass: `probe wheel wedges=2 selftest ok=true`; a `PROBE` without a `stimulus` never appears
  in the server log.

**M10 — cold load and disconnect** (T152, R139)
- Enter the field: **no action button is drawn** until the first snapshot arrives. The stick
  is available immediately.
- Kill the server mid-field: the cluster **clears** and the toast states the connection is
  lost. The stick still draws but the Seeker does not move — the game never reads as a
  silent freeze.
- Pass: `cluster legal=[]` before first snapshot; toast visible in the capture.

---

## Device / emulator only — **do not mark green from a desktop run**

**M4 — two thumbs at once** (T154, R134 / P74)
- Hold the stick with the left thumb **while** pressing an action button with the right.
- Neither cancels the other: the Seeker keeps moving and the intent is sent.
- Lift either finger independently; the other continues to work.
- Open a station popup and tap its `Button`s: they still respond
  (`emulate_mouse_from_touch` is on).
- Pass: simultaneous `MOVE` and the action intent in the same log window.

**M7 — the phone's real shape** (T155, R135)
- Orientation is **locked landscape**; rotating the device does not rotate the game.
- Both zones inset by `DisplayServer.get_display_safe_area()`; nothing sits under a notch
  or the gesture bar.
- **No control or readout in either bottom corner** (thumbs occlude them).
- On a 19.5:9 phone the logical viewport is ~780×360 and on 20:9 ~800×360: the HUD is
  anchored by fraction/inset and the **extra width goes to the field**, not the controls.
- Every finger-operable control measures ≥40 logical px.
- Pass: on-device screenshots at two aspect ratios; `pixelscale win=<w>x<h> logical=<w>x<h>`
  logs the expected pair.

---

## Sign-off

Complete when M1, M2, M3, M5, M6, M8, M9, M10 pass on desktop **and** M4, M7 pass on a device,
GDScript is error-free under `get_debug_output`, and the server + shared suites still pass
untouched (this spec changes no server file).
