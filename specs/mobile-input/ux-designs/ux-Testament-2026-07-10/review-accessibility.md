# Accessibility Review — Testament Mobile Input

## Overall verdict

The floor is not level. Two of the HUD's most important state signals — the **walk/run
register** (1.52:1) and the **server-refusal flash** (1.26:1) — fail the WCAG 3:1 non-text
threshold so badly they are effectively invisible as visual changes, and the register's
only fallback is a haptic tick with no in-app off/on control. The "40 logical px ≈ 48dp"
tap-target claim is arithmetically true *only* at exactly factor 3 / 400dpi; it drops to
~42dp on a dense iPhone and to 32–40dp on factor-2 phones, so the fixed logical-px constant
does not guarantee the dp floor it claims. The spine also promises a screen-reader-nameable
control surface that Godot 4.7 cannot deliver on mobile. The pixel-art canon genuinely
blocks larger text and cheap motor accommodations, and those trades are being made without
being named as trades.

## Findings

### 1. Tap targets

- **[high]** The 40-logical-px floor is a *pixel-count* constant, but the integer scale
  factor is set by `viewport_height/360`, not by physical density — so a fixed logical size
  maps to wildly different physical dp across the device range (DESIGN.md `spacing.tap_min`;
  EXPERIENCE.md "Accessibility Floor"; requirements.md R135). Verified independently: 40
  logical px = **48.0dp only at factor 3 + 400dpi**; **41.9dp on a 1284-tall iPhone 13 Pro
  Max (458ppi, factor 3)** — under Apple's 44pt and Material's 48dp; **40dp at factor 2 /
  320dpi**; **32dp at factor 2 / 400dpi**. The authored `action_size` of 44 logical px is
  only 35dp at factor 2 / 400dpi. Tablets over-shoot (~97dp at factor 4). The floor does
  **not** hold at factor 2, and fails on high-density phones even at factor 3. *Fix:* derive
  the finger-target minimum at runtime from `DisplayServer.screen_get_dpi()` (or the physical
  safe-area size), clamping to `ceil(48 * dpi/160 / factor)` logical px, instead of hardcoding
  40. Keep 40 as a lower bound, not the target. The spec's own "(Derived; verify on device.)"
  note concedes this is unverified — treat it as a blocker until measured.
- **[low]** The 1px `outline` (`#12100C`) is 2 physical px at factor 2 — sub-0.2mm on a
  ~400dpi screen. It is high-contrast (near-black on any bright tile, so it separates the
  control from the world well), but as the *sole* edge cue it is physically thin for
  low-vision users. *Fix:* scale the outline with the integer factor (1 logical px is fine at
  factor 3; consider a 2-logical-px outline as an accessibility option).

### 2. Contrast (computed, WCAG 2.x sRGB)

| Pair | Role | Ratio | Needs | Verdict |
|---|---|---|---|---|
| glyph `#E0CF9F` / face `#3C4248` | icon (text-like) | **6.58:1** | 4.5:1 | PASS |
| glyph `#E0CF9F` / denied `#8F2F2A` | icon on refused face | **5.21:1** | 4.5:1 | PASS |
| action_rim `#B08A3E` / face `#3C4248` | component border | **3.17:1** | 3:1 | PASS (marginal) |
| stick_knob `#CBB583` / stick_ring `#4C545A` | component | **3.85:1** | 3:1 | PASS |
| action_denied `#8F2F2A` / face `#3C4248` | refusal state-change | **1.26:1** | 3:1 | **FAIL** |
| gold.dim `#8C6C30` / gold.bright `#B08A3E` | speed-register signal | **1.52:1** | 3:1 | **FAIL** |

- **[high]** **The refusal flash is nearly isoluminant with the rest face.** `action_denied`
  red on the stone face is **1.26:1** — a player watching the button will barely register
  that anything changed (DESIGN.md `colors.action_denied`; EXPERIENCE.md "Refused" state;
  Flow 2). Worse, this is *inverted priority*: the low-stakes **press** ack (`action_press`
  `#E0CF9F` on face ≈ 12:1, extremely loud) screams, while the high-stakes **refusal** is a
  whisper. The design is saved only by the co-occurring toast — which is correct redundancy
  — but the color itself carries almost no signal, and for a protanope the red darkens toward
  the stone and collapses further. *Fix:* make the refusal state a luminance event, not a hue
  event — e.g. flash the whole button to a bright value then to red, or invert to a light
  face with a red glyph, so the change clears 3:1 on luminance alone.
- **[medium]** `action_rim` availability border passes 3:1 only by 0.17 (**3.17:1**). It is
  not the sole availability cue (a legal button also *appears from absent*, plus its 6.58:1
  glyph), so availability is legible overall — but the rim as a standalone affordance is
  marginal on the darkest field tiles. *Fix:* accept it (redundant with presence+glyph) or
  lift the rim value slightly; do not rely on the rim alone.
- **[low]** `stick_knob` vs `stick_ring` = 3.85:1 — passes 3:1 for a non-text component; the
  knob is additionally distinguished by shape/motion. No action needed.
- Note: DESIGN.md guarantees only *glyph-vs-face* ≥4.5:1, which holds (6.58). It makes **no
  contrast guarantee for the rim, the knob, the register, or the refusal** — and those are
  exactly the ones that fail or run marginal. The stated "≥4.5:1 glyph" spine claim is true
  but under-scopes what needs a contrast floor.

### 3. Colour as sole channel

- **[high]** **The walk/run register is encoded by ring brightness only** (`gold.dim` vs
  `gold.bright` = **1.52:1**), which is far below 3:1 (DESIGN.md "Gold intensity = the speed
  register"; EXPERIENCE.md stick state table). A low-vision or colour-blind player cannot
  reliably tell walking from running by sight — and the register feeds field pressure
  (D3), so it is not cosmetic. This directly contradicts EXPERIENCE.md's own claim that
  "Colour is never the only channel." The stated backup — a haptic tick at the boundary — is
  a single non-visual channel with **no in-app toggle and no guaranteed availability**
  (see §7). If haptics are off, the register has *no* distinguishable cue. *Fix:* give the
  two registers a **shape/geometry** difference, not just brightness — e.g. inner ring drawn
  solid for walk, a second concentric ring or ticked rim for run — so the register clears 3:1
  on form, independent of colour and haptics.
- **[medium]** The whole "warm = agency / cold = inert" state model (DESIGN.md "Colors") is a
  hue+brightness channel. It mostly rides on *presence vs absence* (a legal control simply
  exists), which is robust — but where it leans on warmth alone it inherits the same
  low-vision risk. Keep presence/absence and shape as the primary channels; treat warmth as
  decoration.

### 4. Motor

- **[high]** **No motor accommodations exist.** No one-handed mode (two-thumb landscape grip
  is assumed throughout); no stick-size, deadzone, or position customisation (`DEADZONE`,
  `RADIUS` are hardcoded constants, design.md geometry block); no remapping; no switch /
  AssistiveTouch path. A floating stick **requires a sustained drag**, which is hostile to
  users with tremor, limited grip endurance, or one usable hand. *Fix:* expose deadzone and
  stick radius as settings; offer a fixed-position stick option; document a switch/assistive
  fallback even if deferred.
- **[medium-high]** **Tap-to-move was rejected to protect a combat window that does not
  exist.** The rejection rationale is the timed Omen dodge in `combat.md` (D2; EXPERIENCE.md
  anti-patterns) — but `ATTACK`/`DODGE` have **no wire intent** and the slots draw nothing
  (design.md "Deferred"; Flow 3 is explicitly "reserved, not built"). So an accessibility
  affordance is being denied *today* on the strength of an *unbuilt* system. Until combat
  ships, tap-to-move is a legitimate low-dexterity accommodation with no live conflict. *Fix:*
  reconsider tap-to-move as an accessibility option now, gated to auto-disable (or coexist)
  only once a timed dodge exists on the wire — rather than pre-emptively forbidding it.

### 5. Cognitive / discoverability

- **[medium]** **Nothing teaches the player the invisible left zone exists.** The design's
  intent is discovery-by-accident ("She rests her left thumb… the stick appears… She never
  looked for it", Flow 1; "invisible until touched", DESIGN.md), and first-run experience is
  entirely unspecified. A first-time or cognitively-loaded player faced with a static field
  and zero visible controls has no cue to touch the left side. The empty screen is celebrated
  as "the design," which is fine for a returning player and a real barrier for a new one.
  *Fix:* add a one-time first-field onboarding — a brief ghost stick, a zone shimmer, or a
  single "rest your thumb here" prompt — dismissible and never shown again.
- **[low]** Controls appearing/vanishing on legality (D1) gives no persistent map of what is
  possible; players learn the vocabulary only by moving into range. Acceptable given the
  mystery pillar, but note it raises the cognitive floor for new players.

### 6. Reduced motion

- **[medium]** **The reduced-motion lever (F9) does not cover HUD control transitions.**
  EXPERIENCE.md scopes F9 to torch glow ("must not dim the HUD") and says nothing about the
  controls' own motion. Meanwhile Flow 1 step 4 has the Interact button **"fade in"** — a
  peripheral animation a motion-sensitive user cannot disable — while DESIGN.md forbids the
  stick fading (framed as anti-latency, not as an a11y choice). The instant appear/remove of
  the *stick* is actually fine for vestibular safety (instant state change is not the trigger;
  fades and drifting motion are). The gap is that the **button fade and the pop-in/out of the
  cluster** are uncovered by any reduced-motion setting. *Fix:* fold HUD control transitions
  under the reduced-motion lever — instant (no fade) when it is on; and reconcile the
  DESIGN "no fade" rule with Flow 1's "fades in."

### 7. Haptics

- **[high]** (coupled with §3) **Haptics are load-bearing as the only reliable walk/run cue,
  with no in-app control.** EXPERIENCE.md "Game Feel" specifies a boundary tick as *the* way
  "the register is felt, not read," but design.md defers haptics to a device pass and there is
  **no in-game on/off toggle, no intensity control**, and reliance on OS-level settings only.
  If a player disables system haptics (battery, preference, a device without a vibration
  motor), the register loses its only non-visual channel and its visual channel already fails
  (1.52:1). *Fix:* add an in-app haptics toggle; never let haptics be the *sole* carrier of a
  gameplay-relevant state — pair every load-bearing tick with a visual (shape) cue.
- **[low]** Battery/comfort handling is otherwise good: "nothing on movement" is the right
  call and is justified. The refusal buzz + engage tick are appropriate and sparse.

### 8. Screen reader / captions

- **[high]** **The "captions bound to role and state… so a screen reader can name a control"
  claim is not implementable in Godot 4.7 on mobile.** (EXPERIENCE.md "Accessibility Floor".)
  Godot 4.7 has no TalkBack (Android) or VoiceOver (iOS) accessibility-tree bridge; its
  AccessKit-based a11y work is desktop-scoped and not wired to mobile assistive tech. Worse,
  the HUD controls are **custom `_draw` Control nodes**, which expose nothing to any a11y tree
  even where one exists, absent explicit annotation the engine can't emit here. As written the
  spine promises blind-accessible naming the engine cannot deliver. *Fix:* soften the claim to
  what is true — "caption *text* exists for each control's role/state, positioning a future
  glyph-free or a11y mode" — and remove any implication that a screen reader can currently
  operate the HUD. Do not count this as a satisfied accessibility line item.

### 9. Text size

- **[medium]** **There is no path to larger text for low-vision players.** "One authored
  pixel-font size; no sub-font scaling" (DESIGN.md typography; EXPERIENCE.md Caption) is
  correct pixel-art discipline — a pixel font only scales at integer multiples without
  breaking the Nearest grid — but it leaves low-vision users with **no lever**: OS display
  zoom is ignored by a fullscreen GL viewport, and raising the integer factor zooms the whole
  world (shrinking visible field, harming the reading pillar). Captions are short, single-line
  station/action names, so a **2× integer caption mode** would stay perfectly crisp and on-grid
  without violating the "no *sub*-font scaling" rule (2× is not sub-font). *Fix:* offer an
  optional 2×/3× integer caption size as an accessibility toggle; name it in the spine as the
  sanctioned exception. See Canon tensions.

## Canon tensions

The pixel-art canon and the accessibility floor genuinely conflict in three places. Each
should be an explicit, logged trade rather than an unstated default:

1. **Fixed logical-px sizing vs per-device dp.** The 640×360 integer-scale canon makes a
   *fixed logical* tap target attractive (it keeps the art on-grid), but dp/physical size then
   swings with density and factor, and the 48dp/44pt platform minimums are missed on real
   phones. Honest trade: either the HUD sizes fingers from physical dpi (leaving the *world*
   on the integer grid — controls are non-diegetic anyway, so they need not be grid-locked), or
   the project accepts sub-standard targets on dense/factor-2 devices. The former is
   compatible with canon because the HUD is the one declared non-diegetic surface.

2. **Palette-locked Ash & Ember vs contrast thresholds.** "No new colour" (DESIGN.md) forces
   the register and the refusal to be expressed as brightness steps *within* one ramp, and
   those steps (1.52:1, 1.26:1) fail 3:1. Colour lock cannot be reconciled with the register
   by hue alone — so the register must carry a **shape/geometry** difference and the refusal a
   **luminance** difference, both of which are achievable inside the locked palette. The trade
   is "spend layout/shape complexity to buy contrast the palette won't give."

3. **One pixel-font size vs low-vision text.** Genuine and irreducible for *body* pixel text.
   The escape hatch that preserves canon is integer-only caption scaling (2×/3×), because
   captions are short and integer multiples stay crisp — but it must be sanctioned in the
   spine, since the current wording ("no sub-font scaling") reads as forbidding any size change
   at all. Absent that, low-vision players have no text lever and this is a conscious exclusion
   that should be logged, not left implicit.

A fourth, softer tension: the **mystery pillar** ("the empty screen is the design") is in
direct competition with **first-run discoverability** of the invisible movement zone. The
resolution (a one-time, dismissible onboarding cue) costs the mystery nothing after first
contact and should be adopted rather than treated as a violation of the empty-screen ideal.
