# Spine Pair Review — Testament (Mobile Input)

## Overall verdict

A tight, self-contained control-surface spine pair: every `{token}` reference resolves, every source file is on disk, the DESIGN.md color block re-states every inherited hex (so nothing depends on cross-file resolution), and the canonical section orders are honored. The single real weakness is **component coverage of the two non-diegetic surfaces the spec invents — the Toast and the full-screen reader — which are load-bearing (the Toast is the sole channel for every server refusal, the whole P62 story) yet have no component row on either spine and no visual token at all.** Secondary gaps: no cold-load/disconnect state for a surface whose legality is entirely snapshot-driven, and a walk/run state table that reads as a single threshold while the real behavior is a hysteresis band.

## 1. Flow coverage — strong

Checked: `sources:` on EXPERIENCE.md are docs/code, not a `requirements.md` with named UJs (unlike the notice-board spine, which sourced R118–R128), so there is no R#/UJ list to map one-to-one. Validated instead that the four developer decisions (D1–D4 in `.decision-log.md`) and the implemented intents (`MOVE`, `PROBE`, `EXTRACT`, plus the reserved `ATTACK`/`DODGE`) are each exercised or accounted for. All three Key Flows have a named protagonist, numbered steps, and a climax beat; Flow 2 is a dedicated failure path.

### Findings
- **low** No flow exercises **Probe or Extract**, the two contextual buttons besides Interact (Input Schemes table, EXPERIENCE.md:187–189). The diagnosis loop (Probe) is Testament's core verb; it is demonstrated only abstractly as "same pattern as Interact." (EXPERIENCE.md Key Flows) *Fix:* fold a Probe- or Extract-button beat into Flow 1, or add a one-line note that Probe/Extract are the Interact pattern with a different legality gate.
- **low** Flow 3 (Vidal / Omen dodge) is explicitly **unreachable** ("Today the slot is empty and the flow is unreachable," EXPERIENCE.md:273). Correct to record it, but it is design-intent documentation, not a verifiable flow — a downstream test-writer cannot drive it. *Fix:* label it "Reserved (not testable until `ATTACK`/`DODGE` land on the wire)" so no one files it as coverage.

## 2. Token completeness — strong

Checked: every `colors:` entry carries a literal hex (no CRITICAL missing-hex); all twelve `{path.to.token}` refs in EXPERIENCE.md prose resolve to DESIGN.md tokens; all seventeen backtick token names in DESIGN.md prose (`glyph`, `outline`, `stick_radius`, `action_size`, …) are defined in frontmatter. The inherited color names all resolve in the parent palette: `stone.lit`=#4C545A, `parchment.base`=#CBB583, `gold.dim`=#8C6C30, `gold.bright`=#B08A3E, `stone.mid`=#3C4248, `parchment.highlight`=#E0CF9F, `wax.base`=#8F2F2A, `black`=#12100C — each matches the hex re-stated here.

### Findings
- **medium** `inherits:` (DESIGN.md:12–13) is **not a legal key** in the design.md frontmatter spec (the sanctioned keys are `name`, `description`, `colors`, `typography`, `rounded`, `spacing`, `components`; UI-system inheritance is expressed by referencing tokens by name, not by an `inherits` key). It is also purely documentary here: there are zero `{parent.token}` references and every value is copied locally, so a resolver would do nothing with it. Harmless but implies a resolution step that does not exist. *Fix:* keep it as a comment/`sources` entry (house style already uses `sources:` for exactly this), or drop it; nothing consumes it.
- **medium** The **Toast has no color token** anywhere (DESIGN.md `colors:` and the ASCII diagram at :104 name it as a zone but give it no fill/ink/border). It is the surface that renders every server refusal in words. A downstream implementer has no palette for it. *Fix:* add `toast_face`/`toast_ink` (or state it inherits a specific parent ramp) in `colors:`.
- **low** `walk_threshold: "0.60"` (DESIGN.md:50) is a nominal midpoint; the real boundary is the `0.55/0.65` hysteresis band on the same line. The EXPERIENCE.md State Patterns table (:104–105) uses `walk_threshold` as a single crisp edge, which under-specifies the directional band defined in Interaction Primitives (:141–144). *Fix:* reference the band in the state table, or annotate the token "0.60 nominal; boundary is the 0.55/0.65 band."
- **low** The one contrast target that is stated — glyph ≥4.5:1 on its own face (DESIGN.md:94) — is not extended to the **`action_denied` flash on `action_face`**: `#8F2F2A` on `#3C4248` is dark-on-dark and a weak *visual* signal. The spec correctly makes it non-load-bearing by pairing it with a toast + distinct haptic (redundancy channel), so this is not a defect, only an un-stated one. *Fix:* one line noting the red flash is intentionally redundant, not a standalone signal.

## 3. Component coverage — thin

Checked: DESIGN.md `components:` frontmatter and Components prose list four — `floating_stick`, `action_button`, `action_cluster`, `caption`. EXPERIENCE.md Component Patterns lists four — Floating stick, Action button, Action cluster, **Full-screen reader**. The lists are not identical, and two load-bearing surfaces named across the spines have no component row at all.

### Findings
- **high** The **Toast** is referenced as a first-class surface throughout — IA table (EXPERIENCE.md:48), Voice & Tone (server-refusal translation, :68–70), State Patterns (Refused → toast, :116), and both flows (:253, :264) — but has **no row in DESIGN.md.Components and no row in EXPERIENCE.md.Component Patterns.** It is the single channel for every server "no." Its behavior is entirely unspecified: dwell time, stacking of concurrent errors vs. party notices, dismiss trigger, max width against the top-centre keep-out. *Fix:* add a `toast` component to both spines (visual: face/ink/width/duration; behavioral: queue vs. replace, auto-dismiss, tap-to-dismiss).
- **medium** **Full-screen reader** has a Component Patterns row (EXPERIENCE.md:92–94) but **no DESIGN.md component and no `{components.*}` back-reference** (note the missing `(visual: …)` suffix that the other three carry). Its visual identity is presumably inherited from the notice-board spine, but that inheritance is not stated, so a consumer of *this* pair cannot resolve it. *Fix:* add a `reader` row to DESIGN.md `components:` pointing at the notice-board reader, or a one-line "visual owned by `specs/notice-board`" cite.
- **low** `caption` is a DESIGN.md component (frontmatter + prose :163) with **no EXPERIENCE.md Component Patterns row** — the only component present on one spine but absent on the other in the reverse direction. It is non-interactive, so a behavioral row is thin, but the rubric wants the lists to match. *Fix:* add a one-line Component Patterns entry ("caption: static label bound to a control's role/state; no interaction") or fold it into Action button.

## 4. State coverage — adequate

Checked each IA surface (Movement zone/stick, Action cluster/button, Toast; Reading strip is world, not a control) against empty / cold-load / focus / error / offline / permission-denied / in-flight. Stick (Absent→Engaged-dead→Walking→Running→Released) and Action button (Absent→Available→Pressed→In-flight→Refused) are both strongly covered — **in-flight and error are explicit and correctly reasoned** (in-flight stays pressed, not disabled; :115, :118). Permission-denied is legitimately N/A (a game HUD gates no OS permission).

### Findings
- **medium** **No cold-load / first-frame state.** The entire HUD's legality is "read from snapshot, never from touch" (EXPERIENCE.md:80) — so what is drawn on field entry *before the first snapshot arrives*? Undefined. For a snapshot-driven cluster this is the one state that can flash wrong controls. *Fix:* add a State Patterns line: no action buttons until first snapshot; stick is always available (it is local input geometry, not snapshot-gated).
- **medium** **No offline / disconnected state.** Movement is server-applied (I1); if the socket drops mid-field, `MOVE` goes nowhere and the stick moves a Seeker that does not move. For a *control* surface this reads as a frozen game with no explanation. Not addressed on either spine. *Fix:* state the disconnect behavior (freeze HUD + toast, or reuse the existing resync path) — even a one-liner deferring to the lobby-resilience reconnect flow.
- **low** **Toast has no state row** (empty vs. single vs. stacked). Tied to Finding 3-high. *Fix:* covered by adding the toast component.
- **low** **Cluster focus on keyboard is ambiguous.** Accessibility Floor promises "every touch affordance has a keyboard peer" (:165), but the parity table routes keyboard through `E`/kit-gated actions, not focus-traversal of the cluster. Whether the action buttons are keyboard-focusable (and need a focus ring) or are touch-only with a parallel keyboard scheme is never stated. *Fix:* one line — "the cluster is touch-only; keyboard uses its parallel scheme (no cluster focus ring)."

## 5. Visual reference coverage — adequate

Checked: `imports/` is empty; there are no `mockups/` or `wireframes/` directories. Both spine headers carry the boilerplate "Spines win on conflict with any mock, wireframe, or import" (DESIGN.md:4, EXPERIENCE.md:5) — stated once each, but against zero artifacts. No orphans possible. Judgment: for a spec whose entire thesis is an **invisible, minimal HUD**, an elaborate key-screen mock would over-specify and contradict the design; the DESIGN.md ASCII zone diagram (:102–117) plus the IA extent table (:43–48) give a downstream implementer enough to place every zone (left ~45% movement, right-thumb arc, top-centre toast, bottom-corner + centre keep-outs). The absence is defensible.

### Findings
- **low** The **action-cluster arc geometry** is the one thing a wireframe would pin and prose leaves soft: "an arc in the right-thumb zone, buttons at `action_gap` spacing" (DESIGN.md:157) does not fix the arc radius, anchor point, slot count, or the fixed slot order that "muscle memory is a promise" depends on. *Fix:* a 10-line ASCII of the cluster arc (like the HUD-zone diagram already present) showing reserved slot positions, or name the slot count and anchor in prose.
- **low** The "spines win on conflict with any mock…" line is dead boilerplate here (no mocks exist). Harmless, but a consumer may hunt for the artifacts it implies. *Fix:* drop it or note "no visual artifacts this run; the ASCII zone diagram is normative."

## 6. Bloat & overspecification — adequate

Checked DESIGN.md for pixel specs a token already covers and EXPERIENCE.md for editorial voice. DESIGN.md carries editorial voice legitimately ("candlelight on cold iron," "colder than the torch") — that is its job. Metrics are tokenized, not hardcoded in prose. No source-restatement bloat: the I1/I2 recap is flagged inherited and is load-bearing for the affordance≠authority thesis.

### Findings
- **medium** **Cross-spine duplication of the diegesis thesis.** EXPERIENCE.md "HUD & Diegetic UI" (:168–177) largely re-derives DESIGN.md "Brand & Style" (:62–71) — "only non-diegetic surface," "colder than the torch," "vanishes when it has nothing to offer." The *new* load-bearing content in that EXPERIENCE section is one behavioral rule: "no HUD element ever narrates the Incarnate" (no health bar, no sign readout). *Fix:* cut the section to that rule and cite DESIGN.md Brand & Style for the rest.
- **low** EXPERIENCE.md prose carries mild editorial voice the reference (Quill) keeps out of the experience spine: "Muscle memory is a promise" (:88), "a buzzing thumb during a walk is torture and drains battery" (:206), "The empty screen is the design, not an absence of it" (:173). These motivate real rules rather than decorate, and match the notice-board house style, so this is a note not a defect. *Fix:* none required; if trimming, push the flavor into the rule's rationale clause.

## 7. Inheritance discipline — strong

Checked every `sources:` path on disk: `CLAUDE.md`, `docs/DECISION_LOG.md`, `docs/systems/combat.md`, `docs/technical/dev-environment.md`, `docs/GLOSSARY.md`, `src/shared/src/fieldMessages.ts`, and the `inherits:` target `specs/notice-board/.../DESIGN.md` all resolve. `MovePayload { dx, dy, walk? }` is confirmed at `fieldMessages.ts:26`, so the "zero server change / reuses the wire" claim is accurate. Every EXPERIENCE.md `{token}` resolves to a DESIGN.md token by name (verified literally). Component snake_case frontmatter keys map cleanly to Title-Case prose headers within DESIGN.md.

### Findings
- **low** The only name-consistency break is the component-list mismatch already filed under §3 (Full-screen reader / caption / toast). No other drift. *Fix:* see §3.

## 8. Shape fit — strong

DESIGN.md section order is canonical and locked: Brand & Style → Colors → Layout & Spacing → Elevation & Depth → Shapes → Components → Do's and Don'ts. **Typography is omitted as a body section** (a `typography:` frontmatter block exists, no `# Typography` prose) — legitimately omittable per spec, and defensible since the face is inherited and there is one authored size. EXPERIENCE.md carries all eight required defaults (Foundation, IA, Voice and Tone, Component Patterns, State Patterns, Interaction Primitives, Accessibility Floor, Key Flows) with Key Flows last.

### Findings
- **low** Invented EXPERIENCE.md sections mostly earn their place: **Input Schemes** (the keyboard/touch parity table *is* the "peers, not a port" contract), **Game Feel & Juice** (haptics spec lives nowhere else), **Responsive & Platform** (variable logical viewport 640/780/800 + portrait lockout), and **Inspiration & Anti-patterns** (matches the reference pattern; the four rejected patterns are the design's spine) all justify themselves. Only **HUD & Diegetic UI** is padded (see §6-medium). *Fix:* trim per §6.
- **low** DESIGN.md omits the spec-**required** `name` and `description` keys, using `project`/`surface` instead (matches notice-board house style, so consistent, but technically `name` is mandatory). *Fix:* add `name` / `description`, or accept as a documented house-style deviation.

## Mechanical notes

- **All source paths resolve on disk** (7/7 including the `inherits:` target); `MovePayload` confirmed at `src/shared/src/fieldMessages.ts:26`.
- **All token references resolve:** 12/12 `{token}` refs in EXPERIENCE.md prose; 17/17 backtick token names in DESIGN.md prose; 8/8 inherited color names present in the parent palette with matching hex. **Zero missing-hex, zero broken cross-refs.**
- **Component-list divergence** between the two spines is the one structural inconsistency: DESIGN has `{floating_stick, action_button, action_cluster, caption}`; EXPERIENCE Component Patterns has `{floating stick, action button, action cluster, full-screen reader}`. Toast appears in neither components list despite being a load-bearing surface in both. (§3)
- **Frontmatter completeness:** DESIGN.md uses the house extensions `status/updated/project/surface/sources/inherits`; missing the spec-required `name`/`description`. `inherits:` is a non-spec key (§2). EXPERIENCE.md frontmatter is complete and standard (`design_md` cross-link present and resolves).
- **Non-standard-but-consistent:** the `project`/`surface`/`sources` frontmatter shape and prose-heavy EXPERIENCE voice both match the prior notice-board spine pair — deviations from the generic spec are house style, not drift.

File: `/home/jerwin/projects/Testament/specs/mobile-input/ux-designs/ux-Testament-2026-07-10/review-rubric.md`
