# Input Scheme & Engine Feasibility Review — Testament Mobile Input

## Overall verdict

The two pure functions (`quantize8`, `next_walk`) are arithmetically sound — the
hysteresis band is *not* inverted and the `& 7` two's-complement wrap on a negative
octant *is* correct, contrary to the usual suspicion. The danger is not the math; it
is (a) an unmodelled **Probe→stimulus** gap that makes the Probe cluster button
unable to form a legal wire message, (b) a **Y-axis sign trap** baked into a
misleading code comment, (c) **directional dither** at octant boundaries that
falsifies the "a held stick sends nothing" claim, and (d) several
multitouch/mouse-emulation assumptions that are true only under an implementation
discipline the spec never states. Ship-blocking items exist; the geometry does not.

## Findings

- **[critical]** The **Probe cluster button cannot produce a valid `PROBE` payload.**
  (design.md "Legality → cluster": `Probe : local bag contains any PROBE-kind item`;
  EXPERIENCE.md Input Schemes row "Probe"). `ProbePayload = { stimulus: Stimulus }`
  (fieldMessages.ts:19) — every probe *must* name a stimulus, and the server gates per
  stimulus (you may present `FLAME` only if you carry `censer-of-embers`, gear.ts:26-29).
  The existing field UI correctly draws **one button per stimulus** (main.gd:474-478,
  `for stim in Catalog.STIMULI`). Collapsing that to a single "Probe" slot with a
  "carries any PROBE item" gate loses the stimulus dimension: the button has no
  stimulus to send. *Failing case:* Seeker carries Censer(FLAME)+Salt(SALT); taps the
  one "Probe" button → the client has no way to choose FLAME vs SALT, so it either
  sends a malformed `PROBE {}` (server rejects) or silently picks one. *Fix:* either
  keep N Probe slots (one per **carried** stimulus, contradicting the "one stable
  slot" grammar and eating cluster space) or specify that tapping Probe opens a
  stimulus chooser — which reintroduces the multi-step tap the design elsewhere
  rejects. This is unresolved in both spines and the design.md legality table; it must
  be designed before T151.

- **[high]** **8-way OCTANT table will invert vertical movement if authored to the
  code comment.** (design.md `quantize8`: `# 0..7, E counter-clockwise`). Godot screen
  space is **Y-down**, so increasing `Vector2.angle()` sweeps *visually clockwise*, not
  counter-clockwise. The arithmetic is correct and yields these indices: `0=E(+x),
  1=(+x,+y)=down-right, 2=(0,+y)=DOWN, 3=down-left, 4=W, 5=up-left, 6=(0,-y)=UP,
  7=up-right`. An implementer who trusts the "counter-clockwise" comment will author
  index 1/2 as up-right/UP and index 6 as DOWN, **swapping the whole vertical axis**.
  *Failing case:* thumb pushed straight down (`offset=(0,+10)`), `angle()=+PI/2`,
  quotient `2.0`, octant `2`; a Y-up-authored table returns `Vector2i(0,-1)` and the
  Seeker walks *up*. *Fix:* delete "counter-clockwise" from the comment; author `OCTANT`
  explicitly against Y-down (`[E, DR, D, DL, W, UL, U, UR]` with `D=(0,1)`), and make
  the boot self-check assert `quantize8(Vector2(0,10)) == Vector2i(0,1)`.

- **[high]** **"A held stick sends nothing" is false on an octant boundary — direction
  spam is unbounded.** (requirements.md R130 AC "A held stick sends nothing"; design.md
  P73; main.gd:641 `if v != _last_intent ...`). Hysteresis is applied **only** to
  walk/run (`next_walk`), never to direction. `quantize8` depends on `offset.angle()`,
  which near a 22.5° octant boundary flips octant under sub-pixel thumb jitter.
  *Failing case:* thumb rests at `angle ≈ 22.5°` (E/DR boundary) and micro-wobbles ±0.5°
  each frame; `v` alternates `(1,0)↔(1,1)` every frame → a `MOVE` every frame at the
  20 Hz-plus input rate. The keyboard has no analogue (discrete keys), so touch
  introduces a wire-spam vector the spec claims it eliminated. *Fix:* add directional
  hysteresis — a small angular deadband around the last-chosen octant boundary (e.g.
  require the angle to cross the boundary by ±N° before re-quantizing), or debounce `v`.

- **[high]** **Emulated-mouse double-fire / `set_input_as_handled` does not suppress the
  emulated event.** (EXPERIENCE.md Interaction Primitives; requirements.md R134;
  design.md "Touch routing"). With `emulate_mouse_from_touch` ON (Godot default true),
  a finger-0 `InputEventScreenTouch` generates an **independent** `InputEventMouseButton`;
  the two travel the pipeline separately, and marking the touch handled in `_input`
  does **not** cancel the already-queued emulated mouse event. The scheme only works if
  every field-HUD action control is `mouse_filter=IGNORE` and hit-tested **manually**
  from raw touch (as the `cluster.button_at`/`cluster.capture` pseudocode implies). If
  an implementer instead uses a real `Button` with a `pressed` signal (the obvious,
  simpler choice), a finger-0 press fires **twice** — once via `cluster.capture(raw
  touch)` and once via the emulated-mouse `pressed`. *Failing case:* Extract implemented
  as a themed `Button`; one right-thumb tap sends `EXTRACT` twice. *Fix:* state as an
  invariant that field-HUD controls are IGNORE + manually hit-tested and are **never**
  Godot `Button`s wired to `pressed`; only the *popup* controls (behind the STOP dimmer)
  may be real Buttons.

- **[high]** **`touch_hud._input` must gate on `_menu_open`; the popup dimmer's
  `mouse_filter` does not stop raw touch.** (main.gd:163 `_popup_dim` MOUSE_FILTER_STOP;
  design.md "Touch routing" shows no `_menu_open` guard). `mouse_filter` governs *mouse/
  GUI* propagation only — it has **no effect on `InputEventScreenTouch` delivery to
  `_input`**. So while a station popup is open, a left-side tap still reaches
  `touch_hud._input` and spawns a stick *behind* the dimmer, and both CanvasLayers
  compete for the same finger. Movement itself is safe (main.gd:627 `_send_move_intent`
  early-returns `{0,0}` under `_menu_open`), but a ghost ring is drawn and the touch is
  ambiguously owned. *Failing case:* open Quartermaster, tap a checkbox on the left half
  of the panel → a phantom stick ring flashes under the panel. *Fix:* `touch_hud._input`
  must early-return whenever `_menu_open` (and on non-walkable phases), mirroring the
  existing `_send_move_intent` guard.

- **[medium]** **`_send_move_intent` is keyboard-hardcoded; "feeds the existing send
  path" is not a drop-in.** (main.gd:626-645; design.md "One send path, two producers").
  `_send_move_intent` computes `v` directly from `Input.is_physical_key_pressed` via
  `_dir_axis` — there is no seam to inject a touch vector. Touch cannot "feed" it without
  a refactor (member-var handoff or a merged producer), **and** an arbitration rule when
  both modalities are active (last-input-wins, per input_scheme). Neither the refactor
  nor the arbitration is specified, and P71's "no second `MOVE` producer" is at risk if
  it is done naively. *Fix:* refactor `_send_move_intent` to take `(dir, walk, active)`
  from whichever producer the input scheme currently owns; keep the single
  `send_message(MOVE, …)` call site.

- **[medium]** **Desktop playtest cannot exercise the touch path until
  `emulate_touch_from_mouse` is enabled — it is not set.** (project.godot has neither
  emulate flag; playtest.md/tasks.md rely on `emulate_touch_from_mouse`). Default is
  `false`, so as shipped a desktop mouse produces no `InputEventScreenTouch` and M1/M2/
  M3/M5/M6 observe nothing. When enabled it emits **index 0 only**, which is fine for the
  single-touch desktop items and correctly leaves M4 device-only (already acknowledged).
  *Fix:* set `input_devices/pointing/emulate_touch_from_mouse=true` in project.godot (or
  a debug-only toggle) as part of T154/T156, or the desktop items are un-runnable.

- **[low]** **DESIGN.md's single `walk_threshold: 0.60` contradicts the implemented
  hysteretic 0.55/0.65 band.** (DESIGN.md spacing + State Patterns table using one 0.60
  edge). Not a bug — `next_walk` is correct — but the state table describes a
  non-hysteretic register and will mislead a reader diffing spine vs code. *Fix:* state
  the band (0.55/0.65) in the table, or mark 0.60 as the nominal centre only.

- **[low]** **Self-check octant-boundary rows must match GDScript `round()`'s
  half-away-from-zero rule.** (tasks.md T148 "both boundaries map to the expected
  `Vector2i`"). `round(0.5)=1`, `round(-0.5)=-1`; an exact octant midpoint is
  deterministic but resolves to *one* neighbour. The authored 24-row table must encode
  that tie direction, or a "both boundaries" assertion will spuriously fail. *Fix:* test
  boundary±epsilon, not the exact midpoint, for the two neighbours; test the midpoint
  once against `round()`'s actual result.

- **[low]** **The ring colour reports *intent*, not server speed.** (EXPERIENCE.md "The
  register is felt"; DESIGN.md gold-intensity = register). The walk/run ring is a local
  guess; the server owns speed. This cannot desync in practice — `walk` rides on the
  ordered, reliable `MOVE` and the server has no walk-rejection path — but if a future
  server clamp is ever added, the ring would lie. Note only.

## Verified-correct claims

- **`next_walk` hysteresis is correct, not inverted.** Walking persists until
  `ratio ≥ 0.65`; running persists until `ratio < 0.55`; the 0.55–0.65 band latches the
  previous register. The band does latch.
- **`quantize8` arithmetic incl. the negative `& 7` is correct.** Octants `-4..4` map
  under two's-complement to `0..7` with West (`+PI`) landing on index 4 unambiguously;
  `Vector2.angle()`'s `(-PI, PI]` range is handled. (Correctness is conditional on the
  Y-down OCTANT table above.)
- **`display/window/handheld/orientation` is the correct Godot 4.7 setting key** for the
  landscape lock; in Godot 4 its value is the string `"landscape"`. It affects handheld
  exports only (desktop ignores it, so M7 is rightly device-only) and does not conflict
  with `PixelScale`'s `size_changed` handler.
- **`quantize8`/`next_walk` are pure `static func`s with no node/scene dependency** and
  can read script-level `const OCTANT`/thresholds from static context — the boot
  self-check can table-verify them without instancing (T148 is feasible).
- **`emulate_mouse_from_touch` is ON by default and does drive the popup `Button`s;**
  keeping it on for the popups while the field HUD reads raw touch is the right split.
- **Extract legality is knowable client-side:** the EXTRACTION node is in
  `_field_site["nodes"]` and `_nearest_station` (main.gd:698-702) already computes the
  on-tile proximity; Interact legality already exists via `_active_station`.
- **`walk` cannot desync under normal operation:** server-authoritative speed, `walk`
  carried on the ordered `MOVE`, no server rejection path.
