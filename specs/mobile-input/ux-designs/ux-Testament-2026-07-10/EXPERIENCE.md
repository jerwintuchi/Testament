---
# EXPERIENCE.md — Mobile Touch Input (Testament)
# Information architecture, input schemes, state and interaction behaviour for the
# field touch HUD. Peer contract to DESIGN.md, which owns how it looks.
# Spines win on conflict with any mock, wireframe, or import.
status: final
updated: 2026-07-10
project: Testament
surface: Field touch HUD + touch adaptation of the station popups

design_md: ./DESIGN.md          # visual identity; tokens referenced as {spacing.tap_min}
sources:
  - .decision-log.md                   # D1-D8, the developer's decisions + Reviewer Gate
  - validation-report.md               # 2 critical, 12 high; findings resolved here
  - CLAUDE.md                          # I1/I2 trust boundary; pixel canon
  - docs/DECISION_LOG.md               # TD-042 (mobile is a target; 640x360)
  - docs/systems/combat.md             # dodge is gated on reading the Omen
  - docs/GLOSSARY.md                   # Probe, Station, Extraction, Seeker
  - src/shared/src/signs.ts            # STIMULI = FLAME | COLD | SALT | LIGHT
  - src/shared/src/fieldMessages.ts    # MovePayload { dx, dy, walk? }; ProbePayload { stimulus }
---

# Foundation

**Form factor.** Landscape phone, two-thumb grip. **Orientation is locked to landscape**
— portrait is unverified (TD-042: a 1080×2400 measurement on a desktop was invalid
because Windows clamps an over-tall window) and the HUD has no portrait layout.

**Engine.** Godot 4.7, `Control` nodes. Internal resolution **640×360**, integer-scaled
to fill by the `PixelScale` autoload. Every metric in both spines is a **logical pixel**.

**Input modalities.** Touch (this spec) and keyboard (existing). They are **peers, not a
port**: both emit the same intents, and neither gains capability the other lacks. Touch
does not get analog movement, because `MOVE` is 8-directional for everyone.

**Trust boundary (inherited, non-negotiable).** The client sends *intentions*; the server
validates and applies (I1/I2). Nothing in this document lets a control authorize an
action. A button is a **hint that an action is probably legal**; the server remains free
to refuse, and the refusal must surface.

# Information Architecture

The field screen carries exactly three interactive regions and one transient one:

| Region | Extent | Owns | Visible at rest |
|---|---|---|---|
| Movement zone | left ~45% width, full height, inside safe area | the floating stick | no |
| Reading strip | centre | the world, the Seeker, the Incarnate | — |
| Action cluster | right-thumb arc, inside safe area | contextual buttons | only when legal |
| Toast | top-centre | server errors, party notices | transient |

**Nothing else is on screen.** The status line moves out of the bottom corner (thumb
occlusion) to the toast. This is the whole HUD.

**Hierarchy of attention:** the world first, the action cluster second, the stick last.
The stick is under the thumb; the player never looks at it.

# Voice and Tone

Captions use the Collegium's **sacred register**, never app-speak. The control names the
*thing*, not the gesture.

| Never | Always |
|---|---|
| "Tap to open" | "Contract Board" |
| "Use item" | "Present the relic" |
| "Exit zone" | "Extract" |
| "Button unavailable" | *(no control is drawn at all)* |

Server refusals are reported in the toast in the server's own terms, translated once:
`NOT_AT_CONTRACT_BOARD` → "You are not at the board." Never a code, never a stack.

# Component Patterns

**Floating stick** (visual: `{components.floating_stick}`)
- Invisible until a touch begins inside the movement zone.
- Spawns **centred on the touch point**, clamped so the ring stays inside the safe area.
- Tracks that finger by `index` until it lifts. Other fingers never steer it.
- Angle → one of 8 directions. Magnitude → the `walk` flag. Release → `MOVE {0,0}`.

**Action button** (visual: `{components.action_button}`)
- Exists **only while its action is legal** (D1). Legality is read from snapshot state,
  never from touch.
- Press sends the intent. The button holds its pressed look until the server answers.
- A refusal flashes `{colors.action_flash}` (a luminance spike), settles to
  `{colors.action_denied}`, and routes the reason to the toast **in words**.
- Minimum `{spacing.tap_min}` (dp-derived); authored at `{spacing.action_size}`.

**Action cluster** (visual: `{components.action_cluster}`)
- Stable slot order. A newly-legal action **never displaces** an existing button; it
  occupies its own reserved slot. Muscle memory is a promise.
- Slots exist, unused, for `ATTACK` and `DODGE`. No button is drawn for them — the wire
  has no such intent (`docs/systems/combat.md` is design, not implementation).
- **When those verbs land, they are capability-gated, never sign-gated.** A control is
  drawn because *the Seeker carries the means* (kit, perception), exactly as Probe is
  bag-gated — **never** because an Incarnate is currently doing something. A `DODGE`
  button that appears when an Omen fires would *be* the Omen tell: the HUD would perform
  the read the player is supposed to earn, defeating Pillar 3 and this spine's own rule
  that the HUD narrates the player, never the Incarnate. Its presence must be identical
  whether or not an Omen is firing. **This constraint outranks "draw only when legal."**

**Probe wheel** (visual: `{components.probe_wheel}`)
- Probe holds **one stable slot**. Touch-**down** on it opens the wheel immediately —
  **no hold timer** (dwell on the core verb is a tax, and undiscoverable).
- Four wedges at **fixed cardinal angles**, one per stimulus: `FLAME` up, `COLD` right,
  `SALT` down, `LIGHT` left. The angle never changes with the bag, so directional memory
  survives requisition. A stimulus not carried has **no wedge**.
- Drag past `{spacing.wheel_deadzone}` lights the wedge under the thumb and previews its
  caption. **Release commits** `PROBE { stimulus }`. **Release inside the deadzone cancels**,
  sending nothing.
- Cancel exists because probing **spends exposure** (`room.exposure += PROBE_EXPOSURE_COST`).
  A bare tap therefore sends nothing — safe by default. The wheel always shows the player
  what they are about to spend exposure on, which a discrete button cannot.
- This is **not** the two-stage tap rejected for the board: that was two discrete commits
  with a selection state between them. This is one continuous gesture, one commit.

**Toast** (visual: `{components.toast}`)
- The **sole channel for every server refusal** and for party notices. It is never
  suppressed, never queued behind an animation.
- **One at a time.** A new message replaces the current one and restarts its dwell — an
  error is current state, not a log entry. Auto-dismiss on dwell; tap dismisses early.
- Error toasts translate the server's code into the Collegium's words, once. Never a code.

**Full-screen reader**
- A tap on a live notice opens it (D4). The reader owns all touch while open; the stick
  is dismissed and movement is zeroed (existing `_menu_open` freeze).
- *Visual identity is owned by `specs/notice-board`; this spine only binds its behavior.*

**Caption**
- Static label bound to a control's role and state. Non-interactive.

# State Patterns

**Stick**

| State | Enter | Look | Emits |
|---|---|---|---|
| Absent | no touch in zone | nothing drawn | — |
| Engaged, dead | touch-down, within `{spacing.stick_deadzone}` | ring + centred knob | `MOVE {0,0}` |
| Walking | magnitude below the run band | **solid** ring | `MOVE {dx,dy,walk:true}` |
| Running | magnitude above the run band | ring + **ticked outer rim** | `MOVE {dx,dy,walk:false}` |
| Released | finger lifts | nothing, instantly | `MOVE {0,0}` |

The walk/run boundary is the **0.55/0.65 hysteresis band**, not a single edge — see
Interaction Primitives. The register is reported by **shape**, not brightness.

**Action button**

| State | Enter | Look |
|---|---|---|
| Absent | action illegal, **or no snapshot yet** | not drawn |
| Available | action legal | `{colors.action_rim}` |
| Pressed | finger down | `{colors.action_press}` |
| In-flight | intent sent, awaiting server | stays pressed — **never disabled** |
| Refused | server error for this intent | flash `{colors.action_flash}` → settle `{colors.action_denied}` → toast |

**In-flight is not disabled.** A disabled button after a tap reads as a dropped input on
a laggy connection. Holding the pressed state says "heard you, waiting."

**Probe wheel**

| State | Enter | Look | Emits |
|---|---|---|---|
| Closed | no touch on Probe | the Probe button only | — |
| Open, centred | touch-down on Probe | wheel; no wedge lit | — |
| Aiming | drag past `{spacing.wheel_deadzone}` | wedge in `{colors.wedge_active}` + caption | — |
| Committed | release over a wedge | wheel closes | `PROBE { stimulus }` |
| Cancelled | release inside the deadzone | wheel closes | **nothing** |

**Toast**

| State | Enter | Look |
|---|---|---|
| Absent | nothing to say | not drawn |
| Notice | party event | `{colors.toast_face}` + `{colors.toast_ink}` |
| Error | server refusal | adds the `{colors.toast_rim}` left rule |
| Replaced | a new message arrives | swaps content, dwell restarts |

**Cold load (first frame).** Legality is read from the snapshot, so **before the first
snapshot arrives no action button is drawn** — the cluster starts empty rather than guessing.
The **stick is always available**: it is local input geometry, not snapshot-gated.

**Offline / disconnected.** Movement is server-applied (I1), so if the socket drops the
stick would steer a Seeker that does not move. On disconnect the cluster clears, the stick
still draws but reports no motion, and the **toast states the connection is lost** — the
game must never read as silently frozen. Reconnection defers to the existing
`specs/lobby-resilience` resync path.

# Interaction Primitives

**Multitouch is mandatory and cannot be faked.** The stick and an action button are
routinely pressed at the same moment. Therefore:

- The field HUD consumes raw `InputEventScreenTouch` / `InputEventScreenDrag`, keyed on
  the event's **finger `index`**. It never reads mouse events.
- `emulate_mouse_from_touch` stays **on** (the station popups' `Button`s depend on it),
  but it emulates only finger 0 — so it can never express stick + action together. The
  field HUD must not be built on it.

> **Invariant — no field-HUD control is ever a Godot `Button`.** `set_input_as_handled()`
> does **not** suppress the emulated mouse event: a finger-0 touch generates an *independent*
> `InputEventMouseButton` that travels the pipeline separately. A field control wired to a
> `Button.pressed` signal therefore **fires twice** on one tap — once from the raw touch,
> once from the emulated mouse. All field-HUD controls are `mouse_filter = IGNORE` and are
> **hit-tested manually** from raw touch. Only *popup* controls, behind the dimmer, may be
> real `Button`s.

> **Invariant — the HUD's `_input` early-returns while `_menu_open`.** `mouse_filter` governs
> mouse/GUI propagation only; it has **no effect on `InputEventScreenTouch` delivery**. The
> popup dimmer therefore does not stop raw touch, and a tap on the panel's left half would
> spawn a phantom stick *behind* it. The HUD must gate on `_menu_open`, mirroring the existing
> `_send_move_intent` guard.

**Touch routing, in order.** A cluster control captures a touch that begins inside it (and,
for Probe, owns that finger until release). Otherwise, a touch beginning in the movement zone
owns the stick. A touch beginning anywhere else is ignored by the HUD.

**8-direction quantization.** `angle → round(angle / 45°) → {dx, dy} ∈ {-1,0,1}²`. The
diagonal is a first-class direction, not a two-key press. **Godot screen space is Y-down**, so
increasing angle sweeps *visually clockwise*: the octant table runs `[E, DR, D, DL, W, UL, U,
UR]` with `D = (0, +1)`. Getting this backwards inverts vertical movement.

**Speed hysteresis.** The walk/run boundary is a **band** (enter run at `0.65`, fall back to
walk at `0.55`), so a thumb resting on the threshold does not strobe the register.

**Directional hysteresis.** The *angle* needs a band too. A thumb resting exactly on an octant
boundary (≈22.5°) micro-wobbles, re-quantizes every frame, and would emit a `MOVE` every frame
— a wire-spam vector the keyboard's discrete keys cannot produce. The angle must therefore
**cross a boundary by a margin** before re-quantizing. Only with *both* bands is the claim true
that **`MOVE` is sent only on change** of `(dx, dy, walk)` and that a held stick sends nothing.

**Deadzone.** Below `{spacing.stick_deadzone}` the intent is `MOVE {0,0}`. A stationary
thumb means stand still, not drift.

**Safe area.** Both zones inset by `DisplayServer.get_display_safe_area()`. Assume a
notch and a gesture bar exist.

**Desktop verification.** `emulate_touch_from_mouse` defaults to **false** and must be enabled
for the desktop playtest, or a mouse produces no `InputEventScreenTouch` at all. It emits
finger 0 only — correct for the single-touch items, and it is why multitouch stays device-only.

# Accessibility Floor

- **Tap targets derive from physical density, not from a logical constant.**
  `{spacing.tap_min}` = `max(40, ceil(48 * dpi/160 / factor))`. A fixed 40 logical px is
  **32dp at integer factor 2** and ~42dp on a dense iPhone — under both Material's 48dp and
  Apple's 44pt. The integer factor tracks pixel *height*, not density, so only a runtime
  `DisplayServer.screen_get_dpi()` derivation can hold the floor. The HUD is the one declared
  non-diegetic surface, so it need not sit on the world's integer grid.
- **No hover anywhere.** Touch has no hover state. The board's hover-raise is removed
  (D4); nothing may depend on a pointer resting.
- **No control in a bottom corner.** Thumbs occlude both.
- **Reduced motion** (existing F9 lever) pins the torch glow to peak, freezes flicker, **and
  makes every HUD control transition instant** — no button fade-in, no cluster pop. It must
  not dim the HUD: motion is atmosphere, controls are information. (The stick's instant
  appear/remove is already vestibular-safe; instant state change is not a trigger, drifting
  motion is.)
- **Colour is never the only channel — enforced, not asserted.** The speed register is
  carried by **shape** (solid ring vs ticked rim), because gold-dim against gold-bright is
  1.52:1. Refusal is carried by a **luminance spike** and by the toast **in words**, because
  wax red against stone is 1.26:1. A colour-blind or low-vision player loses nothing.
- **Text has one integer lever.** Captions are authored at 640×360 with an optional **2×/3×
  integer** scale. Fractional scaling is forbidden (it breaks the Nearest grid), and OS
  display zoom is ignored by a fullscreen GL viewport, so this is the only path — and it must
  exist, or low-vision players have none.
- **Captions exist for every control's role and state**, positioning a future glyph-free or
  assistive mode. **This is not screen-reader support.** Godot 4.7 has no TalkBack/VoiceOver
  bridge (its AccessKit work is desktop-scoped), and these are custom `_draw` Controls that
  expose nothing to an accessibility tree. Do not count this as satisfied.
- **Every touch affordance has a keyboard peer**, and vice versa. The action cluster itself is
  **touch-only** — keyboard uses its parallel scheme (`E`, kit-gated actions), so there is no
  cluster focus ring.

> **Known exclusion — motor (accessibility finding H9, accepted 2026-07-10).** Both the stick
> and the Probe wheel require a **sustained press-and-drag**. There is no one-handed mode, no
> stick-size/deadzone customisation, no switch or AssistiveTouch path, and a slipped thumb on
> the wheel costs exposure. This is a **conscious trade**, not an oversight: the single-gesture
> grammar is the design. The remedy is designed and costed — a latching "sticky" wheel (tap to
> open, tap a wedge, tap centre to cancel) and exposed deadzone/radius settings — and can be
> added later **without any wire change**. Revisit before a wide-audience mobile release.

# HUD & Diegetic UI

Visual thesis and rationale: DESIGN.md, *Brand & Style*. The behavioral rule it yields:

**No HUD element ever narrates the Incarnate.** No health bar for it, no sign readout, no
"weakness: fire", no control whose *presence* reports what the Incarnate is doing. The HUD
reports the player's capability and nothing about the thing being studied (vision.md, "no
knowledge as a number"). This is why the future `DODGE` control is capability-gated rather
than Omen-gated — see Component Patterns, Action cluster.

# Input Schemes

Parity table. Every row is the same intent on the wire.

| Intent | Keyboard | Touch |
|---|---|---|
| Move | `WASD` / arrows | floating stick, 8-way |
| Walk register | hold `Shift` | stick inside the walk ring |
| Interact with station | `E` (proximity prompt) | Interact button (proximity-drawn) |
| Probe | one button per stimulus (kit-gated) | Probe **wheel**: press, drag to a wedge, release |
| Extract | position-gated action | Extract button (position-gated) |
| Close popup | `Esc` | Back button / tap outside |
| Attack, Dodge | *(unbuilt)* | *(reserved slot, unbuilt)* |

**Prompt glyph adaptation.** The proximity prompt reads `Press E — Contract Board` on
keyboard and draws the Interact **button plus caption** on touch. Same trigger
(`_active_station`), same intent, different glyph. The prompt string is never hardcoded
per platform; it is selected from the active input scheme, which flips on the **last
input event seen**, not on the platform — so a phone with a Bluetooth keyboard behaves.

# Game Feel & Juice

- **The stick appears instantly.** No spawn animation, no ease-in. Any delay between
  thumb and ring is felt as input latency, and this is a game about reading a fraction of
  a second (the Omen dodge window).
- **Release is instant too.** No fade. A ghost ring reads as a dropped input.
- **Haptics, sparingly.** A light tick on stick engage; a light tick on an action press;
  a *distinct* buzz on `action_denied`. Nothing on movement — a buzzing thumb during a
  walk is torture and drains battery.
- **The register is felt, not read.** Crossing into the run ring gives the tick, so the
  player learns the boundary without looking at the stick.
- **Never shake the screen for a control.** Screen shake belongs to the world.

# Responsive & Platform

- **Logical viewport varies with the device** (`PixelScale`): 640×360 on a 16:9 phone,
  780×360 on a 19.5:9, 800×360 on a 20:9. The HUD **anchors**, never assumes 640 width:
  the movement zone is a *fraction*, the action cluster is anchored to the right inset.
- `MAX_LOGICAL` (1280×720) caps how much field a wide device reveals.
- **The extra width on a tall-aspect phone is field, not HUD.** Controls stay thumb-sized
  and thumb-placed; the world gets the pixels.
- **Portrait: unsupported and locked out.** Revisit only with a device-verified layout.

# Inspiration & Anti-patterns

**Draw from** the floating-stick grammar of modern touch ARPGs, where the stick is a
transient consequence of a thumb rather than a widget on a screen.

**Reject**
- **The revealed-by-touch button** (the developer's first instinct, and a common one):
  cause and effect invert — the press that shows it also fires it.
- **The always-on gamepad overlay.** Six translucent buttons over a 640×360 pixel scene
  is most of the scene. Testament's mystery lives in what you can see.
- **The disabled-but-visible button.** If an action is illegal, the control is absent. A
  greyed button teaches the player to ignore the cluster.
- **Analog movement on touch only.** It would hand mobile a different game than the
  keyboard plays, and `stepPlayer` does not accept it.

# Key Flows

## Flow 1 — Maret takes a contract (her third expedition, on a train)

1. Maret opens Testament one-handed; the app is landscape-locked, so nothing rotates.
2. She rests her left thumb anywhere on the left of the screen. **The stick appears under
   it.** She never looked for it.
3. She pushes the thumb halfway toward the board. The ring glows dim gold: she is
   **walking**, quietly, which is how she always moves in the Collegium.
4. The Contract Board comes into range. **An Interact button appears** at her right thumb,
   captioned *Contract Board*. Nothing else is on screen. (It appears; it does not fade —
   see Accessibility Floor, reduced motion.)
5. She taps it. The board opens; the stick vanishes; her Seeker stops.
6. She taps a notice. It opens **full-screen** — no hover, no hunting for a 20px card.
7. She taps the wax seal to stamp it. The button holds pressed for 200ms of train
   latency, then the party toast reads *Maret has sealed the charge*. **Climax beat:** she
   has committed the party's Surety with one thumb, on a moving train, and never once
   looked at a control.
8. She backs out. The board closes; the stick is gone; the screen is the Collegium again.

## Flow 1b — Maret presents a relic (the core verb, in the field)

1. In the field, Maret's bag carries the Censer of Embers and Consecrated Salt. A single
   **Probe** button sits in her cluster — not two.
2. She presses it. **The wheel blooms under her thumb**: a wedge up (`FLAME`) and a wedge
   down (`SALT`). `COLD` and `LIGHT` have no wedges; she did not pack them.
3. She drags up. The `FLAME` wedge lights and the caption previews *Present the relic —
   FLAME*. **Climax beat:** she is about to spend exposure, and she can see exactly what on,
   before she has committed to anything.
4. She thinks better of it, slides back to centre, and releases. **Nothing is sent.** No
   exposure spent.
5. She presses again, drags down, releases. `PROBE { stimulus: SALT }`. The Incarnate's
   reaction arrives on the channel she can read; the theory changes.

## Flow 2 — Kestrel is refused (a raced gate)

1. Kestrel stands at the edge of the Deploy Gate. The Deploy button is drawn — the client
   believes he is in range.
2. He taps. The button **holds pressed**; the intent is on the wire.
3. Meanwhile the server has already seen him step off the tile. It answers `NOT_AT_DEPLOY_GATE`.
4. The button flashes wax red; the toast says *You are not at the gate.* A short, distinct
   haptic buzz.
5. **The affordance was wrong and the server was right.** Nothing in the client authorized
   anything. This is P62, felt through a thumb.

## Flow 3 — Vidal reads an Omen — RESERVED (not testable until ATTACK/DODGE reach the wire)

1. In the field, the Incarnate telegraphs its lethal attack: the **Omen** sign.
2. Vidal, who carries the perception to read it, has a `DODGE` control in the reserved
   slot — *once that verb exists on the wire*.
3. Today the slot is empty and the flow is unreachable. It is recorded here so the cluster
   is designed for it, and so no one ships a dodge button before `stepPlayer` can honour it.
