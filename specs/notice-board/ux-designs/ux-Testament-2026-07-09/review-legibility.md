# Legibility / Accessibility Review — Notice Board Pass-2 Reskin

> Read-only critique of the candlelit-gloom legibility risk. Scope: DESIGN.md,
> EXPERIENCE.md, .decision-log.md, the two rendered mocks
> (`.working/palette-candidates.html`, `.working/key-screen-board.html`), and the
> import references. Spines are **not** modified here. All fixes are phrased as
> testable ACs to add to `DESIGN.md` Do's/Don'ts, `EXPERIENCE.md` Accessibility
> Floor, and `specs/notice-board/playtest.md`.

## Overall verdict

**Legibility is asserted, not guaranteed.** The spec correctly *names* every risk —
"torchlight must reach the live papers," "legibility wins on conflict," "state never
by color alone," reduced-motion gating — but it stops at prose assertion. There is
**no numeric contrast floor, no minimum parchment tone for live notices, no
guarantee a torch pool actually covers all four live anchor slots, and no measurable
playtest AC** — every legibility check in `playtest.md` is eyeball-only. Because the
mood is literally "most of the board in shadow," the composited (gloom-multiplied)
render of a live notice that lands *outside* a torch pool drops load-bearing text
well below WCAG floors, even though the raw palette tokens pass. The single worst
offender is structural, not accidental: the **notice headline — the loudest, most
load-bearing text — is specified in wax red, the lowest-luminance ink in the
palette**, so it fails 4.5:1 on *base* parchment and collapses to ~1.5:1 once gloom
touches it.

This is a fixable spec, not a broken one. It needs: (1) a numeric contrast floor
with a mandated live-notice tone, (2) the headline moved off pure wax, (3) a
deterministic keep-out guarantee in the scatter layout, and (4) playtest ACs that
*measure* rather than eyeball. Findings below, most severe first.

## Computed contrast ratios (WCAG 2.x, relative-luminance method)

Text floors: **4.5:1** normal body, **3:1** large/bold (≥24px normal / ≥18.66px
bold — note the pixel-UI headline at the 480×270 internal res is **not** large text,
so it must meet 4.5:1). Non-text/graphical objects (pips, seal): **3:1** (WCAG 1.4.11).

| Foreground | Background | Ratio | Floor | Verdict |
|---|---|---:|---:|---|
| Ink body `#2A2115` | Parchment **highlight** `#E0CF9F` (torch-lit) | **10.2** | 4.5 | PASS |
| Ink body `#2A2115` | Parchment **base** `#CBB583` | **7.9** | 4.5 | PASS |
| Ink body `#2A2115` | Parchment **shadow** `#A8946A` (nominal token) | **5.4** | 4.5 | PASS (thin) |
| Ink body `#2A2115` | Parchment shadow **× gloom 0.7** ≈`#756A4A` | **2.9** | 4.5 | **FAIL** |
| Headline **wax** `#8F2F2A` | Parchment **highlight** | **5.2** | 4.5 | PASS |
| Headline **wax** `#8F2F2A` | Parchment **base** | **4.0** | 4.5 | **FAIL (thin)** |
| Headline **wax** `#8F2F2A` | Parchment **shadow** | **2.7** | 4.5 | **FAIL** |
| Headline **wax** `#8F2F2A` | Parchment shadow **× gloom 0.7** | **1.5** | 4.5 | **FAIL (severe)** |
| Ink faded `#5A4A34` | Parchment shadow (flavor, nominal) | **2.9** | 4.5 | FAIL* |
| Gold pip `#B08A3E` | Parchment base (fill vs paper) | **1.6** | 3 | **FAIL** |
| Gold pip dim `#8C6C30` | Parchment highlight | **3.2** | 3 | PASS (thin) |
| Placard gold `#B08A3E` | Wood edge `#3A2617` | **4.5** | 4.5/3 | borderline |
| Placard gold `#B08A3E` | Wood base `#5A3D28` | **3.1** | 3 (lg) | PASS (large only) |

*Flavor is permitted to be dimmer, so its own failure is acceptable *iff* flavor
text is genuinely non-informational — see [medium] Flavor readability below. The
`× gloom 0.7` rows model the spec's own "most of the board in shadow" darkening plus
the mocks' `inset 0 0 40px rgba(0,0,0,.6)` / `linear-gradient(...rgba(0,0,0,.15))`
composited multiply; 0.7 is a conservative estimate of "in shadow, no torch reach."

---

## Findings

### [critical] The notice headline is wax-red — the worst-contrast ink — with no tone floor
**Location:** DESIGN.md Typography §2 ("Notice headline … the loudest ink"), Colors
table (`wax` = "Origin seal body / highlight"); mocks render `.note .h { color: var(--wax) }`.
The headline (the sacred verb: `SANCTION` / `INQUIRY` / `CONTAINMENT ORDER` / `RITE
OF BANISHMENT`) is the single most load-bearing string on a live notice, and it is
painted in `#8F2F2A`, whose luminance (0.080) is barely above the ink body (0.016).
It passes only on **highlight**-tone parchment (5.2:1); it **fails on base (4.0)**,
fails on shadow (2.7), and is effectively invisible (1.5) once gloom multiplies the
paper. Nothing in the spec guarantees a headline ever sits on highlight-tone paper.
*Fix:* In DESIGN.md, stop using wax as a **text** color. Render the headline in
**ink body `#2A2115`** (10.2:1 even on highlight, 5.4:1 worst nominal), and demote
wax to a non-text accent only (seal, a rule/underline, a drop-cap flourish). If the
wax headline is retained for identity, add a hard AC: *every live headline glyph
renders on parchment ≥ `highlight` tone with a torch-glow contribution and a 1px
`#12100C` outline, measured ≥ 4.5:1 against its local backing on the worst-case
seed.* Add to `playtest.md` as a measured item, not eyeball.

### [critical] No numeric contrast floor + no mandated live-notice parchment tone
**Location:** DESIGN.md Do's ("Keep live notices legible … torchlight must reach the
live papers"); EXPERIENCE.md Accessibility Floor ("never drop … below readable
contrast"). "Readable" and "must reach" are undefined and untestable. The palette
even *names* a `shadow` parchment tone (`#A8946A`) and defines live-vs-flavor as a
**brightness** axis — which permits a live notice to be rendered at shadow tone. At
shadow tone under gloom, body ink is 2.9:1 (fail) and a wax headline is 1.5:1.
*Fix:* Add a load-bearing rule to DESIGN.md + EXPERIENCE.md: **"A live notice's paper
renders at ≥ `parchment.base` (`#CBB583`) tone, never `shadow`, and receives a torch/
ambient glow contribution; `shadow` tone is reserved for flavor scraps."** Add the
numeric floor explicitly: **body ink ≥ 4.5:1, headline ≥ 4.5:1, against the notice's
*composited* (post-gloom, post-shadow-overlay) local backing.** Add a `playtest.md`
AC that samples the rendered framebuffer luminance at a headline glyph and a body
glyph on each of the four live notices on a worst-case seed and asserts the ratio —
this is the only way "torchlight reaches the papers" becomes falsifiable.

### [high] Torch coverage of the four live anchor slots is not guaranteed
**Location:** DESIGN.md Layout ("torches flank left and right … glow pools reach onto
the board edges"; live notices placed by "quadrant anchor slots + seeded jitter");
mock torches are edge-mounted with ~230px pools. The lighting model is two **edge**
sources, but live notices scatter across the **whole** board including center-bottom
and the far corners the pools don't reach (see the key-screen mock: the `RITE OF
BANISHMENT` notice sits bottom-center, between/below both pools). Legibility is made
to depend on torch reach, but nothing binds the live **anchor slots** to the lit
region. *Fix:* Either (a) constrain the four live anchor slots to lie within a
guaranteed-lit envelope (define the envelope as a function of torch position and pool
radius, and assert every live anchor ∈ envelope in the layout unit/test), or (b) give
every live notice its **own** local glow/backlight contribution independent of the
two wall torches (a per-notice "lit paper" term), so live legibility never depends on
where the seeded scatter dropped it. Add a `playtest.md` AC on the worst-case seed.

### [high] Threat pips (the non-color threat cue) fail 3:1 against parchment
**Location:** DESIGN.md Colors ("threat pips" = gold), Shapes ("filled/empty
diamonds"); EXPERIENCE.md Accessibility Floor ("Threat = pip count"). The entire
color-independent threat encoding rests on counting gold diamonds on parchment — but
gold-on-parchment is **1.6:1** (bright gold on base) to **3.2:1** (dim gold on
highlight), and the *empty* pip is outlined in `parchment.shadow` (even lower). Under
gloom the filled/empty distinction — and the count itself — becomes hard to resolve,
which silently defeats the "state never by color alone" guarantee: if you can't see
the pips, the non-hue cue is gone. *Fix:* Require every pip (filled and empty) to
carry a **1px `#12100C` (black) outline** so the diamond's *edge* meets ≥3:1 against
any parchment tone regardless of fill, and specify the empty pip as an
outlined-hollow diamond (edge-only), not a faint interior. Add an AC to `playtest.md`
item 2 (eyeball is fine here, but state the outline requirement).

### [medium] "Legibility beats mood" is stated but not enforceable against occlusion
**Location:** DESIGN.md Don'ts ("Don't let decay … occlude a live notice's
headline/target"); EXPERIENCE.md ("If mood and legibility conflict, legibility
wins"). The principle is present and correct — but it is enforced only by an
eyeball line in `playtest.md` item 2 ("headline/target is readable … not
occluded"). Meanwhile the layout *invites* occlusion: notices "overlap at corners,"
live notices raise to front only **on hover** (so at rest one live notice's headline
can sit under another's corner), the cobweb is a "one-corner" strand and the votive
sits bottom-left — both can land over a live notice. *Fix:* Make the guarantee
structural in the scatter algorithm: **reserve each live notice's headline + target +
seal + pip band as a keep-out rectangle that no other notice, cobweb, foxing, or
votive may overlap** (deterministic per seed; unit-testable in the layout function).
Bind decay props (cobweb, votive) to corners/edges proven empty of live anchors. Add
a layout unit test + a `playtest.md` worst-case-seed AC ("no live headline rectangle
intersects any other notice or decay quad").

### [medium] Reduced-motion static fallback may drop the light that legibility needs
**Location:** EXPERIENCE.md Accessibility Floor + Game Feel ("torch flicker + glow
pulse gated behind a reduced-motion setting … disabling them leaves a fully legible
static board … motion carries none"); mock uses `@media(prefers-reduced-motion)
{ .flame,.pool { animation:none } }`. The claim "motion carries no information" is
true for the *pulse*, but the glow **pool** is the load-bearing *light* that makes
parchment legible — and the mock's `breathe` animation oscillates the pool opacity
`.85→1`. `animation:none` freezes it at the CSS **base** value, which is the dim end,
not the bright end; a naive Godot port could leave the reduced-motion board *darker*
than the animated one. Also note Godot has no automatic `prefers-reduced-motion`; the
setting must be an explicit in-game toggle (correctly implied but not specified as a
concrete control). *Fix:* Specify that **with motion off, the glow pool renders at a
fixed, adequate (peak-equivalent) brightness** — never its trough — so the static
board is *at least* as legible as the animated one; and state that the pool's static
presence is load-bearing while only its *pulse* is decorative. Add a `playtest.md`
AC: toggle reduced-motion, re-sample the same headline/body luminance from the
[critical] floor above, assert it still passes.

### [medium] Flavor scrap readability is ambiguous — informational or decoration?
**Location:** DESIGN.md Colors (flavor is `A8946A`-weighted, dimmer/greyer);
mock `.flavor { filter:brightness(.72) saturate(.7); color:var(--ink-faded) }`;
EXPERIENCE.md Voice ("penitents' pleas … a warning nailed over a warning"). Flavor
text is `ink-faded` on `parchment-shadow` = **2.9:1 before** the `.72` brightness
cut — i.e. genuinely unreadable after it. That is fine **if** flavor is purely
atmospheric wallpaper, but the authored microcopy ("Pray for the soul of Almoner
Hald, who did not return") reads as intended-to-be-read solemn lore, which sets a
legibility expectation the render can't meet. *Fix:* Decide and state the intent in
DESIGN.md: either **(a)** flavor is explicitly non-informational atmosphere — then
document that its text is *deliberately* sub-threshold and carries nothing a player
must read (and keep flavor strings free of anything load-bearing); or **(b)** flavor
is readable lore — then hold it to ≥ 4.5:1 (raise flavor paper to `base`, drop the
`ink-faded`+brightness stack). Do not leave it in the middle.

### [medium] No focus / keyboard-accessibility floor for the popup
**Location:** EXPERIENCE.md Foundation ("PC, keyboard + mouse"; notices are
"mouse-picked"); State Patterns lists idle/hover/flavor/open but **no focus state**.
The popup is keyboard-reachable (opened with **E**) yet offers no keyboard traversal
of notices, no focus-visible ring, and the seal (the primary action, a Godot button)
has no specified focus state. For a keyboard+mouse PC title this is a missing floor
item (and Godot Control focus is free to wire). *Fix:* Add to EXPERIENCE.md
Accessibility Floor: **live notices are focusable (Tab order = reading order), a
visible focus ring (gold `#B08A3E` 2px inset or equivalent, ≥3:1 against parchment
and wood) marks the focused notice and the seal button, Enter/Space activates.**
Add a `playtest.md` (eyeball) item: Tab cycles live notices, focus ring visible,
Enter opens the reader, seal is focus-reachable.

### [medium] Live click-targets can be smaller than the minimum hit size
**Location:** DESIGN.md Layout ("Live sizes vary dramatically — small note → large
poster"), Spacing (`seal: 46×46 reader, 18×18 card tack`). The *reader* seal at
46×46 comfortably meets the 44px target guideline — good. But on the **board** the
clickable target is the whole notice, and a "small note" scatter variant may fall
below the ~24×24 (WCAG 2.5.8) / preferred 44×44 minimum, making a low-tier live
petition a fiddly mouse target — especially tilted and partially overlapped. *Fix:*
Specify a **minimum live-notice clickable footprint** (e.g. ≥ 44×44 logical px of
un-occluded hit area, enforced in the scatter/layout function) so "size is aesthetic"
never shrinks a live target below the floor. Unit-testable on the layout output.

### [low] Origin seal color-independence (colorblind safety) is unstated in the floor
**Location:** DESIGN.md components (`wax_seal: Origin-keyed Belief/Sin/Relic`),
Colors ("wax red is *identity* (Origin)"); EXPERIENCE.md "State never by color alone"
lists threat / selection / live-flavor but **omits Origin**. If the three Origins are
distinguished by seal **hue**, that is a color-only cue (and the locked palette
defines only one wax ramp, so the hues would be off-palette anyway); the reused
`WaxSeal` is described elsewhere as "colour + sigil," but this spine never states the
**sigil (shape) is the load-bearing Origin cue**. *Fix:* Add Origin to the
"state never by color alone" list in EXPERIENCE.md: **Origin = sigil glyph
(Belief/Sin/Relic each a distinct pressed shape), color is redundant reinforcement
only.** Confirm the three sigils are shape-distinguishable at the 46×46 reader seal
and legible at the 18×18 board tack.

### [low] "Faint" unsealed seal risks being invisible in gloom
**Location:** EXPERIENCE.md State Patterns ("Seal: faint-unsealed · firm-sealed");
Game Feel ("from faint → firm"). Selection-by-firmness is a good non-hue cue, but a
*faint* wax seal on a gloom-dimmed parchment could read as *no seal at all*,
collapsing the "awaiting seal" affordance. *Fix:* Specify a minimum-visibility floor
for the faint state — the seal **ring/outline** stays at full strength (≥3:1 edge
contrast) while only the *fill/emboss* is faint — so faint-unsealed is always
distinguishable from firm-sealed **and** from bare parchment.

---

## Answers to the five focus questions (summary)

1. **Contrast:** Palette tokens pass at nominal values, but the load-bearing cases
   fail once the spec's own gloom is composited. Body ink survives to shadow tone
   (5.4) but not shadow×gloom (2.9). The **wax headline is the real failure** — 4.0
   on base, 2.7 on shadow, 1.5 under gloom. The worst case (live notice outside a
   torch pool) is unaddressed. **Torch reach is not required in a testable way** —
   see [critical] and [high].
2. **State-not-by-color:** Threat (pips), selection (firmness), live/flavor
   (brightness) each nominally have a non-hue cue — but the pip cue itself fails 3:1
   ([high]) and **Origin is missing** from the list ([low]). No state is *purely*
   hue-coded, but the pip visibility gap silently undermines the guarantee.
3. **Reduced motion:** Gating is specified; the gap is that the **static fallback may
   freeze the glow at its dim trough**, dropping the very light legibility depends on
   ([medium]). Fix by pinning the static pool to peak brightness.
4. **Gloom vs occlusion:** "Legibility beats mood" **is** stated (DESIGN Don'ts +
   EXPERIENCE) — but enforced only by eyeball. Make it a **deterministic keep-out
   rectangle** in the layout function ([medium]).
5. **Missing floor items:** focus/keyboard states ([medium]), minimum live hit-target
   ([medium]), Origin sigil colorblind cue ([low]), faint-seal visibility ([low]).

## Severity counts
- critical: 2
- high: 2
- medium: 4
- low: 2

**Single most important fix:** Add a numeric, measurable legibility floor and mandate
the live-notice paper tone — *"a live notice renders at ≥ `parchment.base` with a
torch/glow contribution and its body **and headline** measure ≥ 4.5:1 against the
composited (post-gloom) local backing, verified on a worst-case seed"* — and move the
headline off pure wax red (or outline+highlight-back it). This converts "torchlight
must reach the live papers" from an assertion into a testable guarantee and kills the
two critical failures at once. Add the corresponding framebuffer-luminance AC to
`specs/notice-board/playtest.md`.
