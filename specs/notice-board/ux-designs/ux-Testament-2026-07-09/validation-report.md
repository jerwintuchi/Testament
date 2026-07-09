# Validation Report — Testament Notice Board (Pass 2 Reskin)

- **DESIGN.md:** `specs/notice-board/ux-designs/ux-Testament-2026-07-09/DESIGN.md`
- **EXPERIENCE.md:** `specs/notice-board/ux-designs/ux-Testament-2026-07-09/EXPERIENCE.md`
- **Run at:** 2026-07-09
- **Lenses:** rubric walker · legibility-under-gloom · art-canon compliance · behavior-drift

## Overall verdict

A **strong, tightly-distilled spine pair** — palette fully hex-locked, every `{token}`
resolves, all sources and reused components exist, canonical shape intact; a downstream
implementer can source-extract cleanly. The gaps are at the edges, not the spine.

But the **legibility lens materially sharpens the central risk**: the candlelit-gloom mood
the reskin is built on is *asserted, not guaranteed*. The notice headline — the loudest
string — is wax red `#8F2F2A`, the lowest-luminance ink; it fails WCAG on all but torch-lit
paper and collapses to ~1.5:1 under gloom. Threat pips fail the 3:1 graphical floor,
undermining the "threat = pip count" non-color cue. No numeric floor / mandated live-notice
tone makes any of it testable. **Behavior-drift passed clean** (look-not-behavior holds;
terminology byte-identical). **Art-canon** is sound but flags colored-screen-blend-vs-
grayscale-ADD-blend and the unresolved Pillow pipeline.

## Category verdicts

- Flow coverage — adequate
- Token completeness — strong
- Component coverage — adequate
- State coverage — adequate
- Visual reference coverage — thin
- Bloat & overspecification — strong
- Inheritance discipline — strong
- Shape fit — strong
- *Legibility (lens)* — asserted-not-guaranteed
- *Art-canon (lens)* — sound after 2 fixes
- *Behavior-drift (lens)* — PASS

## Findings by severity

### Critical (2)

**[Legibility]** Headline is wax-red, the worst-contrast ink, with no tone floor (DESIGN.md Typography §2 / Colors)
The sacred verb is painted in the lowest-luminance ink: passes only on torch-lit highlight paper, fails on base (4.0:1), invisible under gloom (1.5:1).
Fix: render the headline in ink body `#2A2115`; demote wax to a non-text accent. If wax is kept, hard-AC it onto ≥highlight paper + 1px `#12100C` outline, measured ≥4.5:1.

**[Legibility]** No numeric floor + no mandated live-notice paper tone (DESIGN.md Do's; EXPERIENCE.md Accessibility)
Live-vs-flavor is a brightness axis, permitting a live notice at shadow tone — body ink 2.9:1, wax headline 1.5:1 there.
Fix: "A live notice renders at ≥ `parchment.base`, never shadow, with a torch/glow contribution; body & headline ≥ 4.5:1 vs composited local backing." Add a framebuffer-luminance AC to `playtest.md` on a worst-case seed.

### High (5)

**[Token completeness / Legibility]** No numeric contrast target committed (DESIGN.md Do's; EXPERIENCE.md Accessibility)
Legibility is a "hard floor" in prose but never bound to a ratio — unverifiable downstream. (Expanded by the two criticals above.)
Fix: commit the ratio; mirror as a measured `playtest.md` AC.

**[Legibility]** Torch coverage of the four live anchor slots not guaranteed (DESIGN.md Layout)
Two edge sources, but live notices scatter across the whole board (key-screen RITE OF BANISHMENT sits between the pools). Legibility depends on torch reach with nothing binding live anchors to the lit region.
Fix: constrain live anchors to a guaranteed-lit envelope, or give each live notice its own local backlight independent of the wall torches.

**[Legibility]** Threat pips fail 3:1 — the non-color threat cue is invisible (DESIGN.md Colors/Shapes)
Gold-on-parchment is 1.6–3.2:1; empty pip outlined even lower. If pips can't resolve, "state never by color alone" is defeated.
Fix: 1px `#12100C` outline on every pip; empty pip = outlined-hollow diamond.

**[Art-canon]** Colored screen-blend glow/cobweb vs "grayscale ADD-blend VFX" (DESIGN.md torch/cobweb; EXPERIENCE.md Game Feel)
A flame-colored screen-blend pool is a different technique from CLAUDE.md's canonical grayscale ADD-blend, and injects off-ramp intermediates.
Fix: grayscale additive source tinted at runtime via `modulate` to the flame ramp (or Light2D w/ flame-ramp color over a grayscale cookie), Nearest, integer-scaled.

**[Art-canon]** Pillow-absent pipeline is OPEN and unsurfaced; threatens the load-bearing glow (.decision-log.md; DESIGN.md Do's)
Torch glow, cobweb, deckle, foxing are exactly the alpha/gradient assets the stdlib PNG path makes painful — and DESIGN doesn't carry the risk.
Fix: surface in a DESIGN.md "Pipeline" note; resolve stdlib-vs-Pillow before Batch 1 (Pillow is within the sanctioned toolchain but an env change needing the user's ok).

### Medium (12)

- **[Flow]** Deselect / lift-the-seal journey has no flow (EXPERIENCE.md Key Flow). Fix: a step-4b lift beat with the un-accepted toast.
- **[Flow]** Non-leader co-op experience never walked (EXPERIENCE.md State Patterns). Fix: a one-paragraph non-leader companion flow.
- **[Component]** `threat_pips` has no behavioral entry (EXPERIENCE.md State Patterns). Fix: one State-Patterns line.
- **[State]** No empty-board state (EXPERIENCE.md). Fix: state the empty presentation or assert pool ≥1.
- **[State]** No error visual surface committed (EXPERIENCE.md Accessibility). Fix: name the surface (top-centre toast / status line).
- **[Visual refs]** Key-screen mock is orphaned (`.working/key-screen-board.html`). Fix: link from DESIGN.md; promote to `mockups/`.
- **[Legibility]** "Legibility beats mood" not enforceable against occlusion (DESIGN.md Don'ts). Fix: deterministic keep-out rect around each live headline band; bind decay props to empty corners.
- **[Legibility]** Reduced-motion fallback may freeze the glow at its dim trough (EXPERIENCE.md Game Feel). Fix: static pool at peak-equivalent brightness; re-sample luminance with motion off.
- **[Legibility]** Flavor readability ambiguous — lore or wallpaper? (DESIGN.md Colors). Fix: pick (a) deliberately sub-threshold atmosphere or (b) ≥4.5:1 readable; not the middle.
- **[Legibility]** No focus/keyboard floor; live hit-target can fall below minimum (EXPERIENCE.md Foundation). Fix: focusable notices + gold focus ring + Enter/Space; enforce ≥44×44 un-occluded live footprint.
- **[Art-canon]** Pixel integrity under seeded rotation / non-integer scale unaddressed (DESIGN.md Layout/Shapes). Fix: pre-baked rotated deckle variants or a pixel-rotation shader; integer scale steps only.
- **[Art-canon]** Palette-lock directional, not absolute (DESIGN.md Colors/Do's). Fix: no-off-ramp rule; quantize blended/lit output back to the locked palette before export.

### Low (12)

- **[Flow]** Raced-error path unrendered — name the error surface.
- **[Token]** No minimum glyph size for the 480×270 res — name one.
- **[Component]** Decor components lack a "static/inert" note — one-word marker each.
- **[State]** No pressed/in-flight seal state — optionally note transient feedback.
- **[Visual refs]** Palette-candidates provenance breadcrumb missing in DESIGN.md Colors.
- **[Inheritance]** Mixed path bases in sources — state base = repo-root except `imports/`.
- **[Legibility]** Origin colorblind cue + faint-seal visibility unstated — sigil-shape cue; keep faint-seal ring at full strength.
- **[Art-canon]** "16×16-class" latitude — note frame/placard/tacks on the 16px grid.
- **[Behavior-drift]** "AUTHORIZED"-style wax settle is off-register — drop the word, describe in register.
- **[Behavior-drift]** Key Flow narrates only the commit half of two-stage DEPLOY — add a launch-stage clause.
- **[Behavior-drift]** Seal captions listed flat without role/state binding — annotate or point to R124.
- *(art-canon confirmations: no-Incarnate-art, trust boundary, size-not-tier, solemn-not-whimsy, P65 flavor-inert — all clean, no action.)*

## The one fix cluster

Most load-bearing findings converge on a single spec change, applied to both spines and
mirrored as ACs in `specs/notice-board/playtest.md`:

> A **live notice** renders at **≥ `parchment.base`** tone (never `shadow`) with a
> guaranteed torch/local-glow contribution; its **headline in ink `#2A2115`** (wax demoted
> to non-text accent) and its **body** each measure **≥ 4.5:1** against the composited
> post-gloom local backing on a worst-case seed; **pips carry a 1px black outline**; and a
> deterministic **keep-out rectangle** protects each live headline/target/seal/pip band from
> overlap by any notice or decay prop. Reduced-motion pins the glow to peak brightness.

## Reviewer files

- `review-rubric.md`
- `review-legibility.md`
- `review-art-canon.md`
- `review-behavior-drift.md`
