# Spine Pair Review — Testament Notice Board

## Overall verdict

A strong, tightly-distilled spine pair: the palette is fully hex-locked, every prose
`{token}` resolves, all four named sources exist on disk, and both reused components
(`WaxSeal`, `ThreatPips`) are real files. A downstream implementer can source-extract
the visual identity and the behavioral delta cleanly. The gaps are at the edges, not
the spine: no *numeric* contrast target is committed for the load-bearing "ink on
parchment under gloom" combination the reskin's whole thesis rests on, the key-screen
mockup in `.working/` is an unreferenced orphan, and several stateful/secondary
journeys (deselect/lift, non-leader read-only, raced-error surface, empty board) are
mentioned but never given their own flow or visual state.

## 1. Flow coverage — adequate

Checked EXPERIENCE.md for a Key Flow per user-journey/requirement: named protagonist,
numbered steps, explicit climax. One flow present — "Wren takes up a charge" — with a
named leader (Wren), steps 1–5, and an explicit `**Climax:**` beat at step 4 (pressing
the seal). It cleanly covers the primary journey: open → glance-read → take-down → seal
→ return. Scope note legitimately narrows this to the reskin *delta*, so a single happy-
path flow is defensible; but TD-041's headline feature is *reversibility*, and the
reversal/secondary journeys never get their own numbered beats.

### Findings
- **medium** The **deselect / lift-the-seal** journey — the load-bearing half of the
  reversible-seal design (R124, R127, `DESELECT_CONTRACT`) — has no flow; it survives
  only as a passing clause in step 4 ("She could lift it just as easily") (EXPERIENCE.md
  Key Flow, l.103). *Fix:* add a short flow or a step-4b beat showing a lift: firm→faint
  seal, `CONTRACT_SELECTION { accepted:false }` toast to the party.
- **medium** The **non-leader** experience (read-only seal, "Awaiting the leader's seal",
  toast-on-notify — R124) is captured in State Patterns but never walked as a flow, so the
  two-client co-op path a playtester must verify has no journey (EXPERIENCE.md l.76, 121).
  *Fix:* a one-paragraph companion flow from a non-leader's seat watching Wren seal.
- **low** No flow touches the **raced-error** path (`NOT_LEADER`/`WRONG_PHASE`/
  `NOT_AT_CONTRACT_BOARD`) even though affordance≠authority (P66) is called out; the
  reader never sees where that error lands on screen. *Fix:* name the surface (see §4).

## 2. Token completeness — strong

Extracted all YAML frontmatter tokens (colors, typography, rounded, spacing, components)
and every `{path.to.token}` in EXPERIENCE prose. Every color role carries a hex triplet
or value — **no color token is missing a hex** (no CRITICAL). Prose refs
`{colors.flame.glow}` → `#F0B25F` and `{components.wax_seal}` both resolve to DESIGN.md
frontmatter. Semantic-vs-accent rules (gold = accent, wax = Origin identity not severity,
threat = pip count not hue) are committed.

### Findings
- **high** No **numeric contrast target** is stated for the load-bearing "notice text on
  parchment under gloom" combination. Both spines make legibility a "hard floor" in prose
  (DESIGN.md Do's l.177; EXPERIENCE.md Accessibility l.80–83) but never bind it to a
  ratio, so "readable contrast" is unverifiable and untestable downstream — the playtest
  can't assert it. The ink ramp (`#2A2115`/`#5A4A34`) on parchment (`#A8946A` shadow →
  `#E0CF9F` hi) is plausibly high-contrast, which makes committing a number cheap. *Fix:*
  state a target (e.g. live-notice headline vs its parchment ≥ 4.5:1 even at the
  `#A8946A` shadow weight; flavor text exempt) so it can be measured.
- **low** `typography.face` defers entirely to "existing Testament pixel UI font" with no
  size/leading floor for the internal 480×270 res; "comfortably legible" (l.113) is
  qualitative. *Fix:* name a minimum glyph size for running notice/headline text.

## 3. Component coverage — adequate

Cross-checked every component named in either spine for a visual spec (DESIGN.md
Components/Shapes) AND a behavioral spec (EXPERIENCE.md). Interactive/stateful pieces are
well-paired: **notice** (visual: Batch 2 + Shapes; behavior: State Patterns live/hover/
flavor/open), **wax_seal** (visual + Shapes; behavior: Seal states + Seal feedback),
**torch** (visual: Batch 1; behavior: single-loop + reduced-motion). Names are stable
across files (snake_case keys `wax_seal`/`threat_pips` in frontmatter, Title-case in
prose — consistent enough to resolve).

### Findings
- **medium** **`threat_pips`** has a visual spec (DESIGN.md Shapes, Components) but **no
  behavioral entry** in EXPERIENCE.md's State Patterns — it's a reused, load-bearing threat
  cue (the non-hue channel for tier) yet its "N filled/empty from tier, no trait value,
  static" behavior is never restated on the behavior spine. *Fix:* one State-Patterns line.
- **low** Several DESIGN components have a visual spec but no behavioral counterpart:
  `frame`, `backing`, `placard`, `surround`, `tack`, `cobweb`, `votive`, `foxing/curl`
  (DESIGN.md Components l.154–172). Most are legitimately inert decor, but `placard` carries
  the board's title voice and `tack` is a per-notice seeded variant — worth a one-word
  "static, non-interactive" note so a consumer isn't left guessing whether they animate.

## 4. State coverage — adequate

Walked each surface (board, notice, seal, torch) against idle/hover/empty/error/non-leader/
reduced-motion. Covered: notice idle+hover+flavor+open; seal faint/firm/read-only; torch
loop + reduced-motion pause (EXPERIENCE.md State Patterns, Accessibility). "State never by
color alone" is explicit and each cue has a non-hue form. Gaps are the empty and error ends.

### Findings
- **medium** No **empty state** for the board is specified — what renders if the live-
  contract pool is 0 (or the flavor table only). The notice *reader* has an honest empty
  line ("No prior testament on record.", l.51) but the board surface itself has no empty
  case. *Fix:* state the empty-board presentation (e.g. placard + bare plank + torches, an
  "awaiting petitions" scrap) or assert the pool is always ≥1 so the case can't arise.
- **medium** No **error visual state / surface** is committed. Both spines say a raced
  `NOT_*`/`WRONG_PHASE` "still surfaces" (DESIGN.md l.191 via EXPERIENCE; EXPERIENCE.md
  Accessibility), but where — a status line? a toast? — is never named, unlike the success
  toast which is pinned to top-centre. *Fix:* name the error surface (reuse the top-centre
  `_show_toast`, or the status line) so the raced path is renderable.
- **low** Seal has no explicit **pressed/in-flight** state between click and the
  authoritative snapshot rebuild; the "faint→firm press/settle" is described as feedback
  but not as a distinct optimistic-vs-confirmed state. Low, since the snapshot is the truth.

## 5. Visual reference coverage — thin

Every file in `imports/` and `.working/` checked for a spine link + a named illustration
purpose. `imports/notice-board-1.jpg` (content/density) and `notice-board-2.jpg`
(structure) are both cited and correctly captioned in DESIGN.md sources and EXPERIENCE.md
Inspiration. The `.working/` artifacts fare worse.

### Findings
- **medium** `.working/key-screen-board.html` (`<title>Notice Board — Key Screen (Ash &
  Ember)</title>`) is a full composed key-screen mockup and is **orphaned** — referenced by
  neither spine nor the decision log. It's the single most useful visual a consumer could
  extract from, and it's invisible. *Fix:* link it from DESIGN.md (e.g. a "Key screen"
  reference under sources or Layout) naming it as the composed mockup of the locked palette.
- **low** `.working/palette-candidates.html` is referenced **only** in `.decision-log.md`
  (l.51), not in either spine. Since the palette is fully inlined into DESIGN.md this is
  acceptable, but a "palette derived from `.working/palette-candidates.html` (Direction A)"
  breadcrumb in DESIGN.md Colors would close the provenance loop. *Fix:* one-line cite.

## Mechanical notes

- **Frontmatter completeness:** DESIGN.md has full status/updated/project/surface/sources
  + colors/typography/rounded/spacing/components. EXPERIENCE.md has status/updated/project/
  engine/sources. Both well-formed.
- **Sources resolve:** all four DESIGN sources exist — `specs/notice-board/requirements.md`,
  `specs/notice-board/design.md`, `docs/art.md`, `CLAUDE.md`; both `imports/*.jpg` present.
  EXPERIENCE's four sources (requirements/design/playtest/DESIGN.md) all exist. Reused
  components `client/scripts/ui/wax_seal.gd` and `threat_pips.gd` are real.
- **Cross-file name consistency:** component and helper names match across spines and match
  the source design.md (`_build_contract_board`, `_build_notice_reader`, `_seal_block`,
  `WaxSeal`, `ThreatPips`). No divergent naming found.
- **Path-base nit (low):** DESIGN.md sources mix bases — `imports/*.jpg` is dir-relative
  while `specs/notice-board/…` and `docs/art.md` are repo-relative. Unambiguous here, but a
  consumer resolving programmatically should be told the base is repo-root except `imports/`.
- **Cross-ref accuracy:** EXPERIENCE cites the server messages by the exact names the source
  design.md defines (`SELECT_CONTRACT`/`DESELECT_CONTRACT`/`CONTRACT_SELECTION`/two-stage
  `DEPLOY`/`NO_CONTRACT_SELECTED`); no dangling protocol reference.
- **Shape fit:** DESIGN.md follows canonical order (Brand & Style → Colors → Typography →
  Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts). EXPERIENCE.md
  carries all required sections (Foundation, IA, Voice & Tone, Game Feel, State Patterns,
  Accessibility Floor, Key Flow, Inspiration & Anti-patterns). Both conformant.
