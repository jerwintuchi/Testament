---
# DESIGN.md — Mobile Touch HUD (Testament)
# Visual identity for the touch control surface. Distilled from .decision-log.md.
# Spines win on conflict with any mock, wireframe, or import.
name: Testament Mobile Touch HUD
description: >
  Visual identity for Testament's field touch controls on landscape phones — a
  floating movement stick, a legality-driven action cluster, a Probe wheel, and
  the toast that carries every server refusal. Palette-locked to Ash & Ember.
status: final
updated: 2026-07-10
project: Testament
surface: Field touch HUD (movement stick + contextual action cluster + Probe wheel), landscape phone

sources:
  - CLAUDE.md                          # trust boundary; pixel canon; 640x360 (TD-042)
  - docs/DECISION_LOG.md               # TD-042 mobile target + resolution
  - docs/systems/combat.md             # melee core; dodge gated on the Omen read
  - docs/technical/dev-environment.md  # PixelScale, capture harness
  # Ash & Ember palette + pixel canon. Every hex below is re-stated locally, so
  # nothing resolves through this reference; it is provenance, not inheritance.
  - specs/notice-board/ux-designs/ux-Testament-2026-07-09/DESIGN.md

# Selected from the Ash & Ember ramps. No new hues.
# Contrast is stated for every load-bearing pair; measured, not assumed.
colors:
  stick_ring:    "#4C545A"   # stone.lit — the base ring, cold, recedes
  stick_knob:    "#CBB583"   # parchment.base — 3.85:1 on stick_ring
  action_face:   "#3C4248"   # stone.mid — button body
  action_rim:    "#B08A3E"   # gold.bright — available; 3.17:1 on action_face
  action_press:  "#E0CF9F"   # parchment.highlight — pressed
  action_flash:  "#E0CF9F"   # parchment.highlight — the REFUSAL flash (luminance, ~12:1)
  action_denied: "#8F2F2A"   # wax.base — refusal SETTLE colour; never the signal itself
  glyph:         "#E0CF9F"   # parchment.highlight — 6.58:1 on action_face
  glyph_denied:  "#E0CF9F"   # 5.21:1 on action_denied
  wedge_face:    "#3C4248"   # stone.mid — Probe wheel wedge at rest
  wedge_active:  "#B08A3E"   # gold.bright — the wedge the thumb is over
  outline:       "#12100C"   # black — 1px, every control, non-negotiable
  toast_face:    "#2B2F33"   # stone.deep — toast body
  toast_ink:     "#E0CF9F"   # parchment.highlight — 8.9:1 on toast_face
  toast_rim:     "#8F2F2A"   # wax.base — left rule on an error toast only

typography:
  face: "Testament pixel UI font (Nearest, crisp import settings)"
  caption: "authored at 640x360 (NOT inherited from the 480x270 board spine — TD-042)"
  caption_scale: "1x default; optional 2x/3x INTEGER accessibility scale (never fractional)"
  register: "Sacred — the Collegium's voice (EXPERIENCE.md Voice and Tone)"

rounded: { stick: "round", action: "2px" }   # the stick is the only circle in the game

# ALL metrics are LOGICAL pixels at the 640x360 internal resolution (TD-042),
# EXCEPT tap_min, which is derived at runtime from physical density (see below).
spacing:
  internal_res:  "640x360, integer-scaled to fill (PixelScale)"
  tap_min:       "max(40, ceil(48 * dpi/160 / factor))  # dp-derived; 40 is a FLOOR, not a target"
  action_size:   "max(44, tap_min)"
  action_gap:    "10"
  stick_radius:  "28"
  stick_knob_r:  "11"
  stick_deadzone: "6"
  walk_threshold: "0.60 nominal; the real boundary is the 0.55/0.65 hysteresis band"
  wheel_radius:  "44  # Probe wheel; wedges are angular targets, not squares"
  wheel_deadzone: "10  # release inside this = CANCEL"
  safe_inset:    "from DisplayServer.get_display_safe_area(); never assume zero"

components:
  floating_stick: "invisible until touched; spawns centred under the thumb"
  action_button:  "contextual button; exists only while its action is legal"
  action_cluster: "right-thumb arc; slots reserved for unbuilt combat verbs"
  probe_wheel:    "four cardinal wedges; press-drag-release; centre cancels"
  toast:          "top-centre transient; the sole channel for every server refusal"
  caption:        "one-line name under a button or wedge; sacred register"
---

# Brand & Style

The touch HUD is the one **non-diegetic** surface in a game that otherwise hides its
interface inside the fiction. The notice board is a board; the Quartermaster is a
counter. The stick and the action cluster are not objects in the Collegium — they are
the player's hands. So they must be **quiet enough to forget and legible enough to
trust**, and they must never compete with the scene for attention. Mystery is the
mechanic; a control that draws the eye steals a reading.

The felt idea is **candlelight on cold iron**. Controls are cold stone that recede
into the field; the parts the thumb owns catch the gold of the flame ramp. Nothing on
the HUD is ever warmer than the torch.

Two inherited rules bind before taste does. The HUD is **16×16-class pixel art**,
Nearest-filtered, palette-locked to Ash & Ember. And **affordance is never authority**:
a control's appearance is a hint, never a permission — the server decides.

# Colors

No new colour is introduced. The HUD draws entirely from the Ash & Ember ramps, using
the warm/cold split as a **state channel**:

- **Cold = present but inert.** `stick_ring`, `action_face` are stone. At rest the HUD
  is nearly invisible against the field.
- **Warm = the player's agency.** `stick_knob` is parchment, `action_rim` is gold. Warmth
  appears exactly where a finger can act, and nowhere else.
- **Presence, not warmth, is the primary channel.** A legal control *exists*; an illegal
  one is *absent*. Treat hue as decoration layered on that binary — never as the carrier.

**Colour cannot carry the speed register, and does not.** The obvious encoding — gold-dim
for walk, gold-bright for run — measures **1.52:1**, far under the 3:1 floor for a non-text
signal. Inside a locked palette no pair of golds can buy that contrast. So the register is
encoded in **shape**: the walk ring is drawn **solid**; the run ring adds a **second
concentric rim with tick marks**. Form clears 3:1 on its own, independent of colour, of
haptics, and of colour-vision. (See Shapes.)

**Refusal is a luminance event, not a hue event.** Wax red on stone measures **1.26:1** —
effectively invisible as a change. So a server refusal flashes the button to `action_flash`
(parchment highlight, ~12:1 against the face) and *then* settles to `action_denied` red.
The eye catches the luminance spike; the red only names what happened. Red alone is never
the signal, and it is never used for a merely-unavailable control — an unavailable control
is not drawn at all.

**Contrast floor (measured, not assumed).** Every control composites over unknown field
tiles, so none may rely on the background. Each carries a 1px `outline` (`#12100C`).

| Pair | Role | Ratio | Floor |
|---|---|---|---|
| `glyph` on `action_face` | icon | 6.58:1 | 4.5:1 |
| `glyph_denied` on `action_denied` | icon on refused face | 5.21:1 | 4.5:1 |
| `toast_ink` on `toast_face` | body text | 8.9:1 | 4.5:1 |
| `stick_knob` on `stick_ring` | component | 3.85:1 | 3:1 |
| `action_rim` on `action_face` | border | 3.17:1 | 3:1 |
| `action_flash` on `action_face` | refusal spike | ~12:1 | 3:1 |

`action_rim` clears 3:1 by only 0.17, so it is **never the sole availability cue** — a legal
button also appears from absent and carries a 6.58:1 glyph.

# Layout & Spacing

All metrics are **logical pixels at 640×360**. On a 2340×1080 phone the integer factor
is 3, so one logical pixel is three physical pixels and the 40px floor is ~120 physical
px — about 48dp. Any control smaller than 40 logical px is untappable and forbidden.

```
 640 logical px, landscape, safe-area inset
┌─────────────────────────────────────────────────────┐
│  toast (top-centre, transient)                      │  ← never occluded
│                                                     │
│ ░░░░░░░░░░░░░░░░░                                   │
│ ░ movement zone ░                     ╭────╮        │
│ ░  (invisible)  ░                     │ 44 │ action │
│ ░      ╭──╮     ░                     ╰────╯        │
│ ░     ( ●  )    ░              ╭────╮               │
│ ░      ╰──╯     ░              │ 44 │               │
│ ░░░░░░░░░░░░░░░░░              ╰────╯               │
│  ~45% width          ← keep-out →     right thumb   │
└─────────────────────────────────────────────────────┘
  bottom corners: THUMB OCCLUSION — no readouts, ever
```

The **bottom corners are occluded by the thumbs** in a landscape grip. No status text,
no counter, no critical readout may live there. (The status line does today; it moves.)

The **centre strip is keep-out** for both control zones: it is where the Seeker and the
Incarnate are, and it is what the player is reading.

# Elevation & Depth

Three layers, back to front: **world** → **HUD controls** → **popups/reader**. Controls
never overlap a popup; opening a station popup dismisses the stick and zeroes movement
(the existing `_menu_open` freeze). The reader is full-screen and owns all touch.

The stick casts no shadow — it is the player's hand, not an object in the world. Action
buttons carry a 1px dark underline only, enough to lift them off a bright tile.

# Shapes

**The stick and the Probe wheel are the only circles in Testament.** Everything else —
notices, seals, pips, panels — is square, deckled, or diamond. The circle is reserved for
the control surface precisely because it belongs to the player and not to the world.

**How the circle is drawn is not a free choice.** A runtime `draw_circle` / `draw_arc`
produces anti-aliased vector edges and would violate the Nearest-filtered pixel canon this
same file swears to (CLAUDE.md, TD-033). The ring, knob, and wheel are **palette-locked
pixel assets** (Aseprite, or a `gen_*.py` sheet) blitted with Nearest — or, if drawn at
runtime, deliberately **pixel-stepped** with no anti-aliasing. Never a smooth primitive.

**Shape carries the speed register** (see Colors), because the palette cannot:

```
      walk                         run
    ╭───────╮                  ╭┈┬┈┬┈┬┈╮        outer rim added,
   ╱         ╲                ╱ ╰─────╯ ╲       ticked, +1px gap
  │   ╭───╮   │              │   ╭───╮   │
  │   │ ● │   │              │   │ ● │   │      knob unchanged
  │   ╰───╯   │              │   ╰───╯   │
   ╲         ╱                ╲ ╭─────╮ ╱
    ╰───────╯                  ╰┈┴┈┴┈┴┈╯
   solid ring                 ring + ticked rim
```

Action buttons are near-square (`2px` corners), matching the panel idiom, so they read
as Collegium furniture rather than as world objects. Probe **wedges** are angular sectors —
effectively infinite-depth targets, which is why the wheel is *more* forgiving than a row
of buttons despite its smaller footprint.

# Components

**Floating stick.** Invisible at rest. On touch-down anywhere in the movement zone it
appears centred under the thumb: a `stick_radius` ring in `stick_ring`, a `stick_knob_r`
knob in `stick_knob`. Drag moves the knob; the ring stays put. Beyond `stick_deadzone`
the knob's angle snaps to one of **8 directions**, and the ring's **shape** reports the
register (solid = walk, ticked outer rim = run). Release dismisses both, instantly, with no
fade (a lingering ghost reads as input lag).

**Action button.** `action_size` square, `action_rim` border, `glyph` icon, optional
one-line `caption` beneath. It is **drawn only while its action is legal**. Pressed →
`action_press`. In-flight (intent sent, no server answer yet) → held pressed, not
disabled. Server refusal → flash to `action_flash`, settle to `action_denied`, toast
carries the reason.

**Action cluster.** An arc in the right-thumb zone, buttons at `action_gap` spacing.
Slot order is stable so muscle memory survives: a button never moves because a
different one appeared. Slots for `ATTACK` and `DODGE` are **reserved and unused** —
those verbs do not exist on the wire yet (`docs/systems/combat.md` is design, not
implementation). When they do land they are **instant-press**, never wheeled.

**Probe wheel.** Probe occupies **one stable slot**. Touch-down on it — *no hold timer* —
blooms a `wheel_radius` wheel centred on the thumb, with **four cardinal wedges at fixed
angles**: `FLAME` up, `COLD` right, `SALT` down, `LIGHT` left. The angle of a stimulus never
changes, so "salt is down" survives every requisition; a stimulus the Seeker does not carry
simply **has no wedge** (absent, never greyed). Dragging past `wheel_deadzone` lights the
wedge under the thumb in `wedge_active` and previews its `caption`. **Release commits**;
**release inside `wheel_deadzone` cancels** and sends nothing. Probing spends exposure, so
the wheel always shows the player what they are about to spend it on.

**Toast.** Top-centre, transient, `toast_face` body with `toast_ink` text and a 1px
`outline`. An **error** toast carries a `toast_rim` left rule; a party notice does not.
Max width is the safe-area width minus twice `action_gap`; it never enters the bottom
corners or the centre reading strip. One toast at a time: a new message **replaces** the
current one and restarts its dwell (errors are current state, not a log). Auto-dismisses
after its dwell; a tap dismisses it early. **It is the sole channel for every server
refusal**, so it is never suppressed and never queued behind an animation.

**Caption.** Names the station, action, or stimulus in the sacred register ("Present the
relic", not "Use item"). One authored size at 640×360, with an optional **integer** 2×/3×
accessibility scale — integer only, because a pixel font at a fractional size breaks the
Nearest grid.

# Do's and Don'ts

**Do**
- Size finger targets from **physical density** (`tap_min`), not from a fixed logical
  constant — 40 logical px is 32dp at integer factor 2, and that is not a tap target.
- Draw a control **only when its action is legal**, and still let the **server refuse it**.
- Encode the speed register in **shape**; the palette cannot carry it (1.52:1).
- Make refusal a **luminance spike**, then settle to red. Red alone is 1.26:1 — invisible.
- Inset everything by `DisplayServer.get_display_safe_area()`; assume a notch exists.
- Keep the HUD **colder than the torch**. It is furniture, not drama.
- Draw circles as **pixel-stepped or blitted pixel assets**. Never a smooth primitive.

**Don't**
- **Don't reveal a control by touching where it would be.** The revealing press is the
  activating press. Controls are bound to game state, never to touch. *(The Probe wheel is
  not an exception: the Probe button is always visible when legal; only its wedges are
  progressive disclosure, after a deliberate press.)*
- **Don't put a readout in a bottom corner.** A thumb is already there.
- **Don't fade the stick out on release.** It reads as latency.
- **Don't put a hold timer on the wheel.** Dwell on the core verb is a tax, and invisible.
- **Don't draw a button for `ATTACK` or `DODGE`.** The server has no such intent; a
  control that cannot be honoured is a lie. And when they land, they are **capability-gated**
  (does the Seeker carry the perception?), **never gated on a live Incarnate sign** — a
  dodge button that appears when an Omen fires *is* the Omen tell, and destroys the read.
- **Don't use `action_denied` red as the refusal signal.** It is the settle colour. The
  signal is the luminance flash. And never use it for "unavailable" — unavailable is absent.
- **Don't rely on hover.** It does not exist. (The board's hover-raise must go.)
- **Don't wheel anything but Probe.** The wheel exists because Probe is a *choice among
  carried stimuli*. Everything else is a single verb, and takes a single press.
