# Design — Mobile Touch Input v1

> Satisfies R129–R137. **Client-only.** No new wire message, no new server handler, no
> shared-type change: the stick reuses `MovePayload { dx, dy, walk? }`, and the action
> cluster reuses `PROBE` / `EXTRACT` / the existing station-popup opens. Trust boundary
> unchanged — the client renders snapshot state and emits intents (I1/I2).
>
> Visual identity: `ux-designs/ux-Testament-2026-07-10/DESIGN.md`.
> Behaviour: `ux-designs/ux-Testament-2026-07-10/EXPERIENCE.md`. Spines win.

---

## Why nothing crosses the wire

`walk` is already an optional flag on `MovePayload`; the server samples it once per
field tick and applies `WALK_SPEED` (I1 — the client asks, it never decides speed). A
stick's magnitude therefore expresses walk/run with **zero protocol change**. Its angle
quantizes to the 8 directions `stepPlayer` already accepts. Analog direction would need
a server change and is explicitly out of scope (touch must not out-resolve the keyboard).

## Client structure

```
client/scripts/input/
  touch_hud.gd        # CanvasLayer; owns routing, the stick, the cluster, the wheel
  floating_stick.gd   # pure geometry + draw; emits (dir: Vector2i, walk: bool)
  action_cluster.gd   # legality -> controls; stable slots; press/in-flight/refused
  probe_wheel.gd      # pure geometry + draw; press-drag-release; centre cancels
  input_scheme.gd     # KEYBOARD | TOUCH, flipped by the last input event
  geometry_selftest.gd# boot-time table assertions (T148) — the repo's first client check
```

**`_send_move_intent` must be refactored, not "fed".** Today it reads the keyboard directly
(`Input.is_physical_key_pressed` via `_dir_axis`, main.gd:626-645); there is no seam to inject
a touch vector. Change it to take `(dir: Vector2i, walk: bool, active: bool)` from whichever
producer the current input scheme owns, keeping the **single `send_message(MOVE, …)` call
site**. Without that refactor, "one send path, two producers" (P71) is a claim, not a fact.

**Controls are drawn, not `Button`s.** `set_input_as_handled()` does not suppress the
emulated mouse event, so every field-HUD control is `mouse_filter = IGNORE` and manually
hit-tested; a real `Button` would fire twice on finger 0. `touch_hud._input` also early-returns
while `_menu_open` — `mouse_filter` does not stop raw `InputEventScreenTouch`, so the popup
dimmer alone would let a tap spawn a phantom stick behind the panel.

### Geometry (pure, testable)

```gdscript
# floating_stick.gd — no node access, no state; verified by the boot self-check (T148).
const DEADZONE  := 6.0
const RADIUS    := 28.0
const RUN_IN    := 0.65   # cross outward -> run
const RUN_OUT   := 0.55   # fall back inward -> walk
const ANGLE_HYST := 6.0   # degrees a boundary must be crossed by before re-quantizing

# Godot screen space is Y-DOWN: increasing Vector2.angle() sweeps VISUALLY CLOCKWISE.
# Index 0 is East; index 2 must therefore be DOWN, not up. Getting this backwards
# inverts vertical movement, and the code will look correct while doing it.
const OCTANT := [
    Vector2i( 1,  0),  # 0  E
    Vector2i( 1,  1),  # 1  down-right
    Vector2i( 0,  1),  # 2  DOWN   (+y is down)
    Vector2i(-1,  1),  # 3  down-left
    Vector2i(-1,  0),  # 4  W      (angle == +PI)
    Vector2i(-1, -1),  # 5  up-left
    Vector2i( 0, -1),  # 6  UP
    Vector2i( 1, -1),  # 7  up-right
]

static func quantize8(offset: Vector2) -> Vector2i:
    if offset.length() <= DEADZONE: return Vector2i.ZERO
    # round() is half-away-from-zero; & 7 wraps -4..4 into 0..7 via two's complement.
    return OCTANT[int(round(offset.angle() / (PI / 4.0))) & 7]

# Direction needs a band as well as speed: a thumb parked on a 22.5 deg boundary would
# otherwise re-quantize every frame and emit a MOVE every frame. Keep the previous
# direction until the thumb is more than half an octant PLUS the band away from it.
static func quantize8_stable(offset: Vector2, last: Vector2i) -> Vector2i:
    var fresh := quantize8(offset)
    if fresh == last or last == Vector2i.ZERO or fresh == Vector2i.ZERO: return fresh
    var drift := absf(rad_to_deg(angle_difference(offset.angle(), Vector2(last).angle())))
    return fresh if drift > 22.5 + ANGLE_HYST else last

static func next_walk(magnitude_ratio: float, was_walking: bool) -> bool:
    if was_walking:  return magnitude_ratio < RUN_IN          # stay walking until 0.65
    return magnitude_ratio < RUN_OUT                          # stay running until 0.55
```

Both hystereses are functions of the *previous* state, which is why they stay pure —
`(offset, last_dir)` and `(ratio, was_walking)` — and can be table-verified without a scene.

### Probe wheel geometry (pure)

```gdscript
# probe_wheel.gd — one stable cluster slot; STIMULI is exactly four (signs.ts:27).
const WHEEL_RADIUS   := 44.0
const WHEEL_DEADZONE := 10.0
# Fixed angle per stimulus, independent of the bag: "salt is down" survives requisition.
const WEDGE := { "FLAME": Vector2i(0,-1), "COLD": Vector2i(1,0),
                 "SALT":  Vector2i(0, 1), "LIGHT": Vector2i(-1,0) }

static func wedge_at(offset: Vector2, carried: Array) -> String:
    if offset.length() <= WHEEL_DEADZONE: return ""      # centre => CANCEL, send nothing
    var dir := quantize4(offset)                          # cardinal only, never diagonal
    for stim in carried:
        if WEDGE[stim] == dir: return stim
    return ""                                             # no wedge there: also cancel
```

Release maps `wedge_at(...)` to either `PROBE { stimulus }` or nothing. Probing spends
exposure (`probe.ts:41`), so "nothing" must be the easy outcome.

### Touch routing

```
_input(event):
  ScreenTouch(pressed):
     if cluster.button_at(pos): cluster.capture(index, button); return handled
     if movement_zone.has_point(pos) and stick.finger == -1: stick.begin(index, pos)
  ScreenDrag:  if index == stick.finger: stick.drag(pos)
  ScreenTouch(released):
     if index == stick.finger: stick.end()
     else: cluster.release(index)
```

Keyed on `index` throughout, so stick + action coexist. The HUD root is
`mouse_filter = IGNORE`; `emulate_mouse_from_touch` remains **on** so the station popups'
`Button`s keep working, and its emulated events pass through the HUD without effect.

### Legality → cluster

```
Interact : snapshot._active_station != ""        (already computed for the "Press E" prompt)
Probe    : bag contains >=1 PROBE-kind item      -> ONE slot; the wheel picks the stimulus
Extract  : phase == FIELD and Seeker on the extraction tile
Attack   : RESERVED SLOT — draws nothing (no ATTACK intent exists)
Dodge    : RESERVED SLOT — draws nothing (no DODGE intent exists)
           WHEN IT LANDS: gated on the Seeker's CAPABILITY (does she carry the perception
           to read the Omen?), NEVER on a live Omen. A control that appears when the sign
           fires IS the sign. This outranks "draw only when legal".
```

Legality is a **render hint recomputed from the snapshot**. It duplicates the server's
gate for display only; the server re-checks and may refuse. On refusal
(`LOBBY_ERROR` / field error naming this intent) the button flashes and the toast
carries a translated reason.

## Correctness Properties

- **P71 (no new authority, R129–R132 / I1,I2):** touch adds no message and no state
  mutation. Every touch path terminates in an existing `send_message` call; a grep for
  state writes under `scripts/input/` finds none.
- **P72 (quantization is pure + deterministic + Y-down, R130):** `quantize8` is a pure
  function of the offset; an authored table maps each octant's centre and both boundaries
  (±ε, never the exact midpoint — `round()` is half-away-from-zero) to the expected
  `Vector2i`. **`quantize8(Vector2(0,10)) == Vector2i(0,1)`**: pushing down walks down.
- **P73 (the wire is quiet, R130):** `MOVE` is emitted only when `(dx,dy,walk)` changes.
  A stick held anywhere — on the walk/run threshold **or on an octant boundary** — sends
  nothing, because *both* the register and the angle are hysteretic. Verified by the
  self-check plus a message counter.
- **P78 (a probe always names a stimulus, R131a):** every `PROBE` the client emits carries a
  `stimulus` drawn from the Seeker's own bag; releasing in the wheel's centre, or over an
  absent wedge, emits **nothing**. No code path can send `PROBE {}`.
- **P79 (no control reports an Incarnate, R131/R137):** no control's *presence* is a function
  of any Incarnate state — only of the Seeker's position, bag, or perception. Asserted for
  the reserved `ATTACK`/`DODGE` slots too, so the Omen never leaks through an affordance.
- **P80 (no double-fire, R134):** no field-HUD control is a Godot `Button`; a single finger-0
  tap emits exactly one intent.
- **P74 (multitouch independence, R134):** stick and action are keyed on distinct finger
  indices; neither steals nor cancels the other. **Device-verified only.**
- **P75 (affordance ≠ authority, R132 / P62 heritage):** hiding or showing a control
  never authorizes; every raced `NOT_*` still surfaces on the toast, and the button is
  never disabled while in-flight.
- **P76 (the HUD narrates the player, R137 / I3,I5):** no control, caption, or readout
  carries an Incarnate trait axis, sign, or derived number.
- **P77 (parity, R136):** the set of intents reachable by touch equals the set reachable
  by keyboard. A table in the self-check asserts both maps have identical keys.

## Wire Protocol Summary

**None.** No message added, removed, or changed. `MovePayload { dx, dy, walk? }`,
`PROBE`, `EXTRACT` are reused verbatim. No shared type changes. No server file is
touched by this spec.

## Deferred (explicitly, not silently)

- **Portrait orientation.** Locked out. TD-042's portrait measurement was invalid
  (Windows clamps an over-tall window); a real layout needs a device.
- **`ATTACK` / `DODGE`.** Slots reserved, grammar defined, **no button drawn** until the
  verbs exist on the wire. `combat.md` is design, not implementation.
- **Board layout at 640×360.** The notice board's Pass-2 layout and its `min_glyph` were
  authored against 480×270 and are unverified at the new base (TD-042). The 40px tap
  floor tightens it further. Belongs to the notice-board spec, not this one.
- **Haptics.** Specified in EXPERIENCE.md (`Game Feel`); Godot's mobile haptic API is a
  device-only surface and lands with the device pass.
