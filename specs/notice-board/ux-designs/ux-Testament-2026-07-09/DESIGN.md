---
# DESIGN.md — Notice Board Pass-2 Reskin (Testament)
# Visual identity spine for the Contract Notice Board station popup. Distilled from
# .decision-log.md. Spines win on conflict with any mock, wireframe, or import.
status: final
updated: 2026-07-09
project: Testament
surface: Contract Notice Board (Collegium station popup)
# Path base is repo-root, EXCEPT imports/ and mockups/ which are run-folder-relative.
sources:
  - specs/notice-board/requirements.md
  - specs/notice-board/design.md
  - specs/notice-board/playtest.md          # Pass-2 legibility/accessibility ACs live here too
  - imports/notice-board-1.jpg              # content/density reference
  - imports/notice-board-2.jpg              # structural reference (carved frame, placard, torches)
  - mockups/key-screen-board.html           # composed key screen of the locked Ash & Ember palette
  - mockups/palette-candidates.html         # palette exploration; Direction A locked below
  - docs/art.md                             # gothic ecclesiastical dark fantasy
  - CLAUDE.md                               # closed toolchain; pixel-art canon; grayscale ADD-blend VFX

# Palette-locked source: Direction A "Ash & Ember" (warm/cold candlelit-gloom).
colors:
  stone:      { deep: "#2B2F33", mid: "#3C4248", lit: "#4C545A" }
  wood:       { edge: "#3A2617", base: "#5A3D28", bevel: "#7A5334" }
  parchment:  { shadow: "#A8946A", base: "#CBB583", highlight: "#E0CF9F" }
  ink:        { body: "#2A2115", faded: "#5A4A34" }   # notice text on parchment
  wax:        { base: "#8F2F2A", highlight: "#C65A4E" }
  gold:       { dim: "#8C6C30", bright: "#B08A3E" }    # placard text, threat pips, seal rim
  flame:      { ember: "#E8973C", glow: "#F0B25F" }
  black:      "#12100C"                                # outline / deepest shadow

typography:
  face: "Testament pixel UI font (existing; crisp+legible import settings, Nearest)"
  register: "Sacred — the Collegium's bulletin voice (see EXPERIENCE.md Voice & Tone)"
  headline_ink: "#2A2115"        # NOT wax — wax is the palette's lowest-luminance ink (fails contrast)
  min_glyph: "one authored pixel-font size for running notice/headline text at 480×270; no sub-font scaling"

rounded: { note: "1px", frame: "3px", placard: "2px" }   # near-square; pixel-art idiom

pipeline:
  generator: "stdlib PNG (zlib+struct), NO Pillow"   # settled 2026-07-09; env has no pip, Pillow needs sudo apt
  vfx: "grayscale additive source PNGs, modulate-tinted to the flame ramp at runtime (canon: grayscale ADD-blend)"
  palette_lock: "absolute — no pixel outside the Ash & Ember ramps; blended/lit output quantized back before export"

spacing:
  internal_res: "480×270 (integer-scaled, Nearest)"
  tile: "16px"
  seal: "46×46 (reader), 18×18 (card tack)"

components:
  frame:      "9-slice carved wood + mitred corner joints"
  backing:    "plank field (vertical grain), 9-slice-safe"
  placard:    "hanging routed sign, top-centre, gold-on-dark-wood"
  surround:   "stone/mortar wall, ambient-candlelit (recognizable, not black)"
  torch:      "flanking wall sconce: flame anim loop + pulsing glow pool"
  notice:     "torn/deckled parchment; live (clickable) vs flavor (inert, aged)"
  wax_seal:   "WaxSeal.gd — Origin-keyed (Belief/Sin/Relic); reused"
  threat_pips:"ThreatPips — gold diamonds from tier; reused"
  tack:       "nail · wax · pin · ribbon (seeded per notice)"
  cobweb:     "one-corner ambient decay strand"
  votive:     "dead votive candle prop (Batch 2)"
---

# Brand & Style

The Contract Notice Board is a **diegetic Collegium fixture**: the wall in the
staging site where petitions against Manifestations are posted for Seekers to take
up. Pass 1 shipped it functional in greybox; Pass 2 gives it the studio's gothic
ecclesiastical dark-fantasy identity (Blasphemous · Castlevania · Dante · Witcher):
cathedral wood and stone, sacred decay, candlelight.

The felt idea is **candlelit gloom, aged but in use**. A carved wooden board sits in
a stone-and-mortar wall, most of it in shadow; flanking wall torches throw the only
strong warmth, so parchment glows and the wood recedes. The board is *tended* — old
notices layer under new, a cobweb clings to one corner, wax has dripped and set — but
never derelict: a live petition is always legible. The register is **sacred, never
tavern-whimsy** (the references' comedic notes are translated to penitents' pleas,
faded rite-notices, and Collegium bulletins).

Two hard canon rules shape the look before any taste does: it is **16×16-class pixel
art**, Nearest-filtered and palette-locked (not the painterly references); and **no
Incarnate/target art ever appears on a notice** — mystery is the mechanic. A notice
carries text, an Origin wax seal, and threat pips; never a portrait of the thing.

# Colors

Palette-locked to **Direction A "Ash & Ember"** (chosen from
[palette-candidates.html](mockups/palette-candidates.html)) — a deliberate warm/cold
split that *is* the candlelit-gloom thesis. Cold desaturated **stone** falls to shadow;
the **flame** ramp carries nearly all the warmth; **parchment** reads as bone that glows
where torchlight reaches it. Neutrals are hue-biased, never pure grey: stone leans
cold blue-slate, wood and parchment lean warm.

**Palette-lock is absolute** (not directional): no rendered pixel may fall outside the
ramps below. VFX tinting uses the **flame** ramp only; any blended, lit, or
`modulate`-tinted output is **quantized back to the locked palette before export**
(a `Light2D`/screen-blend must not leave off-ramp intermediates on the board).

| Role | Ramp (dark → light) | Use |
|------|--------------------|-----|
| Stone | `#2B2F33` · `#3C4248` · `#4C545A` | mortar wall surround; kept recognizable under ambient candlelight |
| Wood | `#3A2617` · `#5A3D28` · `#7A5334` | frame edge / plank base / carved bevel |
| Parchment | `#A8946A` · `#CBB583` · `#E0CF9F` | notice paper — shadow / base / torch-lit highlight |
| Ink | `#2A2115` · `#5A4A34` | notice **headline AND body** text / faded text |
| Wax | `#8F2F2A` · `#C65A4E` | Origin seal body / highlight — **non-text accent only** (seal, a rule, a drop-cap); **never notice headline/body text** |
| Gold | `#8C6C30` · `#B08A3E` | placard lettering, threat pips (with black outline), seal rim — **tarnished brass, not bright** |
| Flame | `#E8973C` · `#F0B25F` | torch ember core / glow (grayscale source, modulate-tinted) |
| Black | `#12100C` | outline (pips, glyphs, faint-seal ring), deepest shadow |

**Semantic vs. accent.** Gold is the accent; wax red is *identity* (Origin), not a
severity signal. Threat is encoded by **pip count** (form), never by hue — a high-tier
notice is not "redder." Live-vs-flavor is encoded by **brightness + saturation**
(flavor is dimmer, greyer, `A8946A`-weighted), not by a different accent. **Origin** is
encoded by the seal's **sigil shape** (Belief/Sin/Relic each distinct), colour redundant.

**Contrast floor (load-bearing — the candlelit-gloom risk).** Palette tokens pass at
nominal values but the mood's own gloom composites them down; the floor is measured
against the **composited (post-gloom, post-overlay) local backing**, not the raw token:

- A **live** notice's paper renders at **≥ `parchment.base` (`#CBB583`)**, never `shadow`
  tone, and receives a torch/local-glow contribution (see Layout — every live notice has
  its own backlight so legibility never depends on where the scatter dropped it).
- **Headline and body ink** each measure **≥ 4.5:1** against that composited backing
  (headline is `#2A2115`, hence the wax demotion above — wax `#8F2F2A` is 4.0:1 on base,
  1.5:1 under gloom, and is retired as a text colour).
- **Threat pips** (a graphical object, WCAG 3:1) carry a **1px `#12100C` outline** so the
  diamond edge meets 3:1 on any parchment tone regardless of fill.
- **Flavor** scraps are exempt (deliberately dim atmosphere; their text carries nothing
  load-bearing — see Do's/Don'ts).

These are verified by measured ACs in `specs/notice-board/playtest.md` (framebuffer
luminance sampled at a headline and a body glyph on each live notice, worst-case seed).

# Typography

The game renders UI in the existing **Testament pixel font** (crisp+legible import,
Nearest) — Pass 2 does not introduce a new face. Typographic identity comes from
**treatment**, in this order of emphasis:

1. **Placard lettering** — the hanging sign reads `PETITIONS BEFORE THE COLLEGIUM` in
   dim gold on dark wood, letter-spaced, the board's title voice.
2. **Notice headline** — the sacred register per verb (`INQUIRY`, `SANCTION`,
   `CONTAINMENT ORDER`, `RITE OF BANISHMENT`), the loudest text on the parchment,
   rendered in **ink `#2A2115`** (NOT wax — see the Colors contrast floor). Identity
   flourish (a wax rule under it, a drop-cap) may carry wax; the letters do not.
3. **Notice body / charge / signature** — smaller ink; the signature line italic-feel,
   set apart (`— <name>, <role> of <place>`).

Running notice/headline text uses **one authored pixel-font size** at the 480×270
internal resolution (no sub-font scaling); name that size in the font resource. Flavor
notices may use a slightly smaller / more faded ink to read as older. The **legibility
floor beats period flavor** when they conflict (see Colors contrast floor + Do's/Don'ts).

# Layout & Spacing

- **Popup** fills the screen with the wood skin; the board is a fixed **canvas** (no
  ScrollContainer). Internal design resolution 480×270, integer-scaled.
- **Scatter, not a grid.** The 4 live contracts + N flavor scraps are placed by
  **quadrant anchor slots + seeded jitter/tilt** (deterministic per `contractId`),
  filling the whole board at human angles, overlapping at corners. Live sizes vary
  dramatically (small note → large poster) — **aesthetic only, never tier-encoding**.
- **Live legibility is scatter-independent.** Every live notice carries **its own local
  backlight/glow** (a per-notice lit-paper term), so a live notice reads at its floor
  tone *wherever* the seed drops it — legibility never depends on a wall torch reaching
  that spot. (The two wall torches remain the mood light; they are not the guarantee.)
- **Keep-out for live content.** Each live notice's **headline + target + seal + pip
  band** is a **deterministic keep-out rectangle** that no other notice, cobweb, votive,
  or foxing may overlap (computed per seed, unit-testable in the layout function). Decay
  props are bound to corners/edges proven empty of any live anchor. At-rest overlap is
  allowed only outside these bands.
- **Minimum live hit-target.** A live notice presents **≥ 44×44 logical px of
  un-occluded clickable area** regardless of its aesthetic size/tilt (enforced in the
  layout function) — "size is aesthetic" never shrinks a live target below the floor.
- **Pixel integrity.** Seeded tilt uses **pre-baked rotated deckle variants** (a seeded
  pick from a few authored angles) or a pixel-art rotation shader — never arbitrary
  runtime rotation that softens edges. Hover-lift and the reader enlarge use **integer
  scale steps only** (Nearest, no sub-pixel), and no live notice sits at an angle that
  drops its headline below the contrast floor.
- **Placard** hangs top-centre on two nails, straddling the frame's top rail.
- **Torches** flank left and right on the stone surround; their glow pools reach onto
  the board edges (mood, not the legibility guarantee — see local backlight above).
- **Stone surround** frames the wooden board on all sides — enough ambient candlelight
  that mortar lines stay readable.

# Elevation & Depth

Depth reads as candlelit layering, front to back: **torch glow** (grayscale-additive,
flame-tinted) + each live notice's **own local backlight** › **live notices** (clickable,
paper ≥ base tone, drop shadow) › **flavor scraps** (dimmer, `MOUSE_FILTER_IGNORE`, so
overlap never steals a live click) › **plank backing** › **carved frame** (raised bevel +
mitred joints, inset shadow) › **stone surround** (recessed, darkest). Hovering a live
notice **raises it to front** (integer lift). The reader ("take down to read") floats the
enlarged parchment centre-screen (integer scale) over a **dim scrim** of the board.

# Shapes

- **Carved frame:** rectangular, `3px`-cornered, mitred **corner joints**; 9-slice so
  detail lives in fixed corners/edges, the stretchable centres are near-uniform grain.
- **Parchment:** torn/**deckled** edges (organic, per-seed), not clean rectangles;
  slight curl/foxing on aged ones. Drawn at pixel size (not 9-sliced) so tears survive.
  A few **pre-rotated variants** are baked per angle (pixel-safe tilt — see Layout).
- **Wax seal:** a pressed circle with an Origin **sigil** (existing `WaxSeal`); the
  sigil *shape* is the Origin cue (colour redundant). The **faint (unsealed)** state
  keeps its ring/outline at full strength (≥3:1 edge) while only the fill is faint, so
  it never reads as bare parchment.
- **Threat pips:** filled/empty **diamonds** (existing `ThreatPips`), each with a **1px
  `#12100C` outline**; the empty pip is an **outlined-hollow** diamond (edge-only), not a
  faint interior — so the count reads regardless of fill or gloom.
- **Tacks:** nail (round head), wax (blob), pin (thin), ribbon (folded) — small, at a
  notice's top edge.

# Components

Batch order per the build plan (structure first, then detail):

All are **static/inert render** unless noted "interactive/animated." Only the **notice**
(live), the **wax seal** (leader), and the **torch** (animated) carry state/motion;
frame, backing, placard, surround, tack, cobweb, votive, foxing are decor.

**Batch 1 — structure**
- **Frame** — 9-slice carved wood, mitred corners, iron-stud accents in the fixed
  corner regions. Palette: wood ramp + black outline. *Static.*
- **Plank backing** — vertical-grain wood field, 9-slice-safe (uniform centre). *Static.*
- **Hanging placard** — routed dark-wood sign, dim-gold lettering, two nail hangs.
  Carries the board's title voice. *Static.*
- **Stone/mortar surround** — brick field, ambient-candlelit; the board's ground. *Static.*
- **Torch** — wall sconce; **flame animation loop** + **glow pulse**. The glow is a
  **grayscale additive source PNG `modulate`-tinted to the flame ramp** at runtime
  (canon: grayscale ADD-blend VFX — *not* an authored colored screen-blend), Nearest,
  integer-scaled; a `Light2D` cookie, if used, is grayscale with a flame-ramp colour.
  Mood light, not the legibility guarantee. **Reduced-motion:** the glow renders at a
  fixed **peak-equivalent** brightness (never the pulse trough), so the static board is
  at least as legible as the animated one; only the *pulse* is decorative.

**Batch 2 — detail**
- **Notice / parchment** — torn/deckled variants; **live** (paper ≥ `base` tone, its
  **own local backlight**, clickable, focusable, drop shadow, hover-raise) vs **flavor**
  (dim, greyed, inert). Carries headline (ink) + charge + seal + pips + signature; NO
  target art. *Live = interactive.*
- **Wax seal** (reuse `WaxSeal`, Origin-keyed **sigil**) — *leader-interactive*, states
  faint/firm/read-only, faint keeps a full-strength ring. **Threat pips** (reuse
  `ThreatPips`) — N filled/empty **outlined** diamonds from tier, no trait value. *Static.*
- **Tacks** — nail · wax · pin · ribbon, seeded per notice. *Static.*
- **Cobweb** — one-corner decay strand, **grayscale additive** (same VFX rule as the
  glow), bound to a corner proven empty of live anchors. *Static.*
- **Dead votive candle** — spent prop; sacred-decay flavor. *Static.*
- **Foxing / curl** — parchment aging overlays on flavor scraps. *Static.*

**Pipeline (settled).** Assets are generated by the **stdlib PNG generator** (`zlib`+
`struct`, no Pillow — the env has no `pip`; Pillow would need `sudo apt` and adds a
dependency). Pass-1 `gen_board.py` already proves the idiom (per-pixel RGBA, distance
gradients, value noise, organic deckled alpha); the torch glow is a radial alpha
falloff, the cobweb thin alpha strands, foxing blotch noise — all authored grayscale and
tinted in Godot. Pillow stays a sanctioned fallback if generator complexity demands it.

# Do's and Don'ts

**Do**
- Keep the palette **absolutely locked** to Ash & Ember — no off-ramp pixel; quantize any
  blended/lit/`modulate` output back to the ramps before export.
- Render **headline AND body in ink `#2A2115`**; wax is a non-text accent only.
- Guarantee **live-notice legibility by construction**: paper ≥ `parchment.base`, a
  per-notice local backlight, headline+body ≥ 4.5:1 against the composited backing —
  measured on a worst-case seed, not eyeballed.
- **Outline every threat pip** (1px `#12100C`; empty = hollow diamond); encode threat by
  **count**, live/flavor by **brightness**, Origin by **sigil shape** — never by hue alone.
- Make VFX **grayscale additive**, `modulate`-tinted to the flame ramp (glow, cobweb).
- Keep pixels crisp: **pre-baked rotated variants** for tilt, **integer scale** for
  hover/reader; reduced-motion pins the glow to **peak** brightness.
- Reserve a **keep-out rectangle** around each live headline/target/seal/pip band; bind
  decay props to corners empty of live anchors; keep live hit-targets ≥ 44×44.
- Author on the sanctioned toolchain only (**stdlib PNG generator** → PNG, Aseprite,
  Godot Control/Light2D/AnimatedSprite2D).

**Don't**
- Don't put any **Incarnate/target portrait** on a notice (mystery is the mechanic).
- Don't use **wax red as text** — it fails contrast (4.0:1 base, 1.5:1 under gloom).
- Don't render a **live** notice at `shadow` parchment tone, or let its legibility depend
  on a wall torch reaching its scatter spot.
- Don't let notice **size imply tier** — size is aesthetic scatter only.
- Don't drift into **tavern whimsy** — flavor stays solemn gothic (pleas, rites, bulletins).
- Don't go **painterly/HD** — 16×16-class pixel, Nearest, palette-locked; no arbitrary
  runtime rotation or sub-pixel scale.
- Don't ship **colored screen-blend** VFX (canon is grayscale ADD-blend).
- Don't let decay (cobweb, foxing, gloom) **occlude a live notice's headline/target**.
- Don't move game logic into any reskinned scene — render-only; behavior is unchanged
  (see EXPERIENCE.md; `specs/notice-board` owns the flow).
