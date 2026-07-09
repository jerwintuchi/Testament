# Art-Canon & Project-Canon Review — Notice Board Pass-2 Reskin

Reviewer scope: read-only compliance critique of `DESIGN.md`, `EXPERIENCE.md`,
`.decision-log.md` against CLAUDE.md ("Art Direction & Sanctioned Toolchain —
CLOSED LIST", Immutable Design Pillars) and `specs/notice-board/requirements.md`
(R125/P64 trait-containment + no-Incarnate-art, P65 flavor-inert).

## Overall verdict

**Sound, ship after two fixes.** The spine is disciplined and canon-aware: it
repeats the pixel-only mandate, the no-target-art rule, the locked Ash & Ember
hex ramps, size-not-tier, and solemn-not-whimsy as explicit hard don'ts, and it
keeps the board render-only with server-authoritative seal state. The HTML key
screen is correctly captioned as a CSS approximation. Two real risks could still
let an implementer drift: (1) the torch glow / cobweb are specified as **colored
screen-blend**, which contradicts CLAUDE.md's "grayscale ADD-blend VFX"
convention; and (2) the **Pillow-absent** pipeline decision is still OPEN in the
decision log and is not surfaced in the finalized spines, yet the load-bearing
torch glow and the gradient/alpha-dependent decay assets are exactly what the
stdlib PNG path makes hard. Neither touches trait-containment (P64/P65 are clean).

Findings: **2 high · 2 medium · 2 low/pass-notes.**

---

## Findings

### [high] Colored screen-blend glow/cobweb conflicts with the "grayscale ADD-blend VFX" convention
Location: `DESIGN.md` → `components.torch` ("pulsing glow pool"), Colors table
(Flame row "torch ember core / glow"), Elevation ("torch glow (screen-blend
pools)"), `components.cobweb` ("screen/overlay"); `EXPERIENCE.md` → Game Feel
("warm {colors.flame.glow} pool subtly pulses"). CLAUDE.md Art Direction lists as
a canonical convention: **"grayscale ADD-blend VFX."** A flame-ramp *colored*
screen-blend pool is a different technique and also injects intermediate colors
outside the locked 8 ramps (see palette finding).
*Fix:* Specify the glow (and any web/overlay VFX) as a **grayscale additive**
source sprite **tinted at runtime via `modulate`** to the flame ramp, Nearest,
integer-scaled — not an authored colored gradient with screen blend. If a
`Light2D` is used, state that its color is the flame ramp and that the underlying
cookie/texture is grayscale. Add this to DESIGN.md Components (torch) and Do's.

### [high] Pillow-absent pipeline is an OPEN decision and is not surfaced in the finalized spines; it threatens the load-bearing glow and the decay assets
Location: `.decision-log.md` last entry ("CONCERN (pipeline, OPEN): Pillow/numpy
are NOT installed… Decision pending: (a) install Pillow… or (b) keep stdlib PNG").
`DESIGN.md` Do's says only "PIL/stdlib generators → PNG" and does not carry the
risk forward; `EXPERIENCE.md` does not mention it. The assets that need true
alpha/gradients — the **torch glow pool** (called "load-bearing atmosphere, not
decor"), the **cobweb**, **torn/deckled** parchment edges, and **foxing/curl** —
are precisely the ones the Pass-1 `zlib`+`struct` stdlib path makes painful. An
implementer reading the finalized DESIGN.md would not know the generator for the
load-bearing asset is undecided. CLAUDE.md sanctions "Python/PIL generators," so
installing Pillow is *within* the closed list, but it is an unconfirmed env change.
*Fix:* Surface the OPEN concern in a DESIGN.md "Pipeline" note and **resolve
a-vs-b before Batch 1**. If staying on stdlib, confirm RGBA/alpha + per-pixel
gradient feasibility for glow/cobweb/deckle explicitly (stdlib can emit RGBA but
gradients are hand-rolled); if that is not viable, the load-bearing torch glow is
at risk and Pillow should be approved with the user first (toolchain change).

### [medium] Pixel integrity under seeded rotation and non-integer scaling is unaddressed
Location: `DESIGN.md` Layout ("seeded jitter/tilt… human angles"), Shapes
("Parchment: torn/deckled… Drawn at pixel size"), Elevation ("Hovering… lifts it
slightly"); `requirements.md` R122 (seeded rotation), R123 (parchment "enlarges to
center"). Arbitrary rotation and non-integer scale of pixel-art sprites break the
Nearest / integer-scale crispness mandate (edge shimmer, anti-aliased seams) — a
direct tension with CLAUDE.md ("480×270, integer-scaled; Nearest filtering").
"Drawn at pixel size" is stated but the rotation/scale technique is not.
*Fix:* Name a pixel-safe method in DESIGN.md Shapes/Layout: pre-bake a few
rotated deckle variants (seeded pick) **or** a pixel-art rotation shader; restrict
the reader enlarge and hover-lift to **integer scale steps**; state that live
notices must not sit at angles that soften the headline below the legibility floor.

### [medium] Palette-lock is directional, not absolute, and doesn't cover blend-generated intermediates
Location: `DESIGN.md` Colors + Do's ("Keep the palette locked… derive every asset
from these ramps"). This is strong guidance but stops short of an absolute
"no off-ramp pixel" rule, and screen-blend / `Light2D` / modulate math produces
colors between the 8 authored ramps. CLAUDE.md requires "palette-locked… sources."
*Fix:* Add a hard rule: *"No pixel may fall outside the Ash & Ember ramps. VFX
tint uses the flame ramp only; any blended/lit output is quantized back to the
locked palette before export."* Pairs with the glow finding above.

### [low / pass] No-Incarnate-art, trust boundary, size-not-tier, solemn-not-whimsy — all clean
- **No target art (R125/P64, vision pillar 3):** stated four times — Brand & Style
  ("no Incarnate/target art ever appears on a notice"), Components ("NO target
  art"), Do's/Don'ts, and EXPERIENCE anti-patterns. The Origin **wax seal** carries
  a *sigil* (asserted-Origin intel, allowed) and Ref-1 "drop-caps" are letters, not
  creatures — no portrait vector. No change needed.
- **Trust boundary / render-only (R126, I1/I2):** EXPERIENCE Scope note ("changes
  how the board looks, not how it works"), seal state "derived from the snapshot's
  `contract`," "affordance ≠ authority," raced `NOT_*` still surfaces; DESIGN Don'ts
  forbids logic in a reskinned scene. Clean.
- **Size-not-tier & solemn-not-whimsy (P65 spirit):** both are explicit hard don'ts
  in DESIGN Don'ts and EXPERIENCE anti-patterns. Clean.
- **P65 flavor-inert:** flavor notices are `MOUSE_FILTER_IGNORE`, dimmed, never
  selectable/acceptable, client-authored ambiance only. Clean.

### [low] "16×16-class pixel art" latitude
Location: `DESIGN.md` Brand & Style + Don'ts. The "-class" hedge is consistent
with CLAUDE.md's own "16x16-class pixel assets" wording for UI, so acceptable.
*Fix (optional):* Note that the carved frame, placard, and tacks are authored on
the 16px grid at 480×270 so the "-class" latitude doesn't become an excuse for
half-pixel detail.

---

## Confirmations (canon honored, no action)

- HTML key screen (`/.working/key-screen-board.html`) is captioned "CSS
  approximation of the pixel target — final art is 16×16-class, Nearest,
  palette-locked." The approximation is correctly flagged; its serif fonts,
  `border-radius:5px`, and `box-shadow` are mock-only and do not leak into the
  spine (DESIGN uses the pixel font and 1–3px "pixel idiom" corners).
- Toolchain stays inside the closed list: Godot 4.7 Control / Light2D /
  AnimatedSprite2D, Aseprite, PIL/stdlib generators → PNG. No outside tool is
  introduced (the only pipeline question is Pillow *within* the sanctioned "Python/
  PIL generators" line — see high finding #2).
- Concrete locked hex ramps are present for stone/wood/parchment/ink/wax/gold/
  flame/black; threat encoded by pip count (form), live/flavor by brightness — not
  by new hues.
