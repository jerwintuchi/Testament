---
# EXPERIENCE.md — Notice Board Pass-2 Reskin (Testament)
# Behavior / IA / interaction spine. Cross-references DESIGN.md tokens as
# {colors.role.shade} / {components.name}. Spines win on conflict with any mock.
status: final
updated: 2026-07-09
project: Testament
engine: Godot 4.7 (Control nodes; Light2D / AnimatedSprite2D for torches)
sources:
  - specs/notice-board/requirements.md   # R118–R128 — behavior (authoritative)
  - specs/notice-board/design.md         # server/client flow
  - specs/notice-board/playtest.md       # verification
  - DESIGN.md                            # visual identity (peer spine)
---

> **Scope note.** Pass 2 changes *how the board looks*, not *how it works*. The
> board's behavior — the reversible leader seal (`SELECT_CONTRACT`/`DESELECT_CONTRACT`),
> take-down-to-read, the two-stage `DEPLOY`, trait containment — is already specified
> and tested in `specs/notice-board` (R118–R128) and is **unchanged**. This file
> captures only the behavioral *delta* the reskin introduces: candlelight game-feel,
> the legibility floor under gloom, and hover/seal feedback tied to the new visuals.

# Foundation

- **Form factor / input:** PC, keyboard + mouse (existing). The board is a station
  popup opened with **E** at the Contract Board; notices are mouse-picked.
- **UI system:** Godot 4.7 Control nodes over the existing `main.gd`
  `_build_contract_board` / `_build_notice_reader` / `_seal_block`. Torch flame is an
  `AnimatedSprite2D`; the glow pool is a `Light2D` or a pulsing modulated sprite.
- **Diegesis:** the board is **diegetic in-world UI** — a physical wall the Seeker
  stands at — not a HUD overlay. It renders in the world's candlelight, which is why
  lighting is a first-class concern here and not on other menus.

# Information Architecture (unchanged; restated for the reskin)

Board (scatter of live + flavor notices) → click a **live** notice → **reader**
(enlarged parchment over dim scrim) → leader **stamps the seal** (reversible) →
[later, at the Deploy Gate] **commit** → DEPLOYING. Flavor notices are inert. The
reskin must preserve this path exactly; no new navigation.

# Voice & Tone (microcopy)

Sacred register, the Collegium's bulletin voice (brand voice lives in DESIGN.md):
- Placard: `PETITIONS BEFORE THE COLLEGIUM`.
- Headlines by verb: `INQUIRY` / `SANCTION` / `CONTAINMENT ORDER` / `RITE OF BANISHMENT`.
- Seal captions, bound to role/state (authoritative mapping: R124):
  - **leader, unsealed** → "Stamp your seal to take up this charge."
  - **sealed** (both roles) → "Sealed. The charge is taken up."
  - **non-leader, unsealed** → "Awaiting the leader's seal."
- Toasts: "<who> sealed the charge: <target>" / "<who> lifted the seal on <target>".
- Empty Archive line: "No prior testament on record."
- Empty board (no live petitions): "The wall stands empty. No petitions before the Collegium."
- Flavor notices: solemn only — penitents' pleas, faded rite-notices, a warning nailed
  over a warning. No comedy.

# Game Feel & Juice (the Pass-2 delta)

- **Living candlelight.** Torch flames run a short looping pixel animation; the warm
  {colors.flame.glow} pool subtly **pulses/breathes** (slow, low-amplitude). Only the
  *pulse* is decorative — the glow's *presence* is load-bearing light. With **reduced
  motion** on, the glow holds at its **peak-equivalent brightness** (never the trough),
  so the static board is at least as legible as the animated one. Godot has no automatic
  `prefers-reduced-motion`, so this is an explicit in-game settings toggle.
- **Hover raise.** Hovering a live notice raises it to front (`move_to_front`) and
  lifts it slightly — the existing affordance, now reading against layered depth.
- **Seal feedback.** Stamping: the {components.wax_seal} presses from **faint → firm**
  with a brief settle — cosmetic only, never a gate (all rendered text stays within the
  R124 caption set; no invented labels). Lifting reverses it. The party toast fires from
  the server `CONTRACT_SELECTION`.
- **Reader transition.** Taking a notice down fades the board to a dim scrim and floats
  the enlarged parchment in — the existing cross-fade, retimed to feel like lifting
  paper off a wall.
- **No motion on state that matters.** Selection state, threat, live/flavor, and phase
  are all readable **static** (seal firmness, pip count, brightness). Motion is only
  ever mood.

# State Patterns

- **Board:** populated (≥1 live) · **empty** (no live petitions — placard + bare plank +
  torches + the "wall stands empty" scrap; never a blank popup).
- **Notice:** live-idle · live-hover(raised) · live-**focused**(keyboard, focus ring) ·
  flavor(inert, dimmed) · open(in reader).
- **Seal:** faint-unsealed · **pressed/in-flight** (brief, optimistic — the snapshot is
  the truth) · firm-sealed · read-only(non-leader). Derived from the snapshot's
  `contract`, so every client shows the same state. The **faint** state keeps its ring at
  full strength so it never reads as bare parchment.
- **Threat pips** (`{components.threat_pips}`): N filled + (max−N) empty **outlined**
  diamonds from `tier`; **no trait value**; static, non-interactive. The outline makes the
  count readable on any parchment tone (the non-hue threat cue).
- **Origin (seal sigil):** Belief / Sin / Relic each a distinct pressed **shape**; colour
  is redundant reinforcement (colorblind-safe).
- **Error:** a raced `NOT_*` / `WRONG_PHASE` / `NO_CONTRACT_SELECTED` surfaces on the
  **top-centre toast** (the same channel as the seal notices) — the error is renderable,
  not swallowed.
- **Torch:** single looping state (no gameplay states); holds at peak brightness under
  reduced-motion.

# Accessibility Floor

- **Legibility under gloom is a measurable hard floor** (not an assertion). A **live**
  notice renders at **≥ `{colors.parchment.base}`** tone (never `shadow`) with its own
  local backlight, and its **headline and body ink** each measure **≥ 4.5:1** against the
  **composited (post-gloom) local backing** — verified on a worst-case seed (see
  `specs/notice-board/playtest.md`). Legibility is guaranteed by construction (per-notice
  backlight), not by hoping a wall torch reaches the scatter spot. If mood and legibility
  conflict, legibility wins.
- **Occlusion floor.** Each live notice's headline/target/seal/pip band is a deterministic
  keep-out rectangle no other notice or decay prop may overlap (DESIGN.md Layout) — the
  "legibility beats mood" rule is enforced structurally, not by eyeball.
- **State never by color alone.** Threat = **outlined** pip count; selection = seal
  firmness; live/flavor = brightness + interactivity; **Origin = sigil shape** — each has
  a non-hue cue, and the pip outline keeps the cue visible under gloom.
- **Focus / keyboard.** The popup opens with **E**; live notices are **focusable**
  (Tab order = reading order) with a visible **gold focus ring** (≥3:1 against parchment
  and wood); **Enter/Space** opens the reader; the seal button is focus-reachable and
  activatable. A live notice presents **≥ 44×44** logical px of un-occluded hit area
  regardless of aesthetic size/tilt.
- **Reduced motion.** The flicker + pulse are gated behind an explicit in-game toggle;
  with motion off the **glow holds at peak brightness** (the static board is *at least*
  as legible as the animated one — the light is load-bearing, only the pulse is decor).

# Key Flow — "Wren takes up a charge"

Wren (leader) opens the board at the Collegium wall on her party's third expedition.

1. **E** at the Contract Board — the popup fills the screen: carved frame in stone,
   two torches guttering, `PETITIONS BEFORE THE COLLEGIUM` hung above a scatter of
   parchment. Four fresh notices glow; older scraps and a cobwebbed corner sit dim.
2. She reads the wall at a glance — headlines in sacred register, threat pips, Origin
   wax seals — no target art to give the game away.
3. She clicks a **SANCTION** notice; it lifts off the wall to centre over the dimmed
   board — full charge prose, the petitioner's signature, the empty Archive line.
4. **Climax:** she presses the faint wax seal. It settles firm; a toast tells the whole
   party "Wren sealed the charge: …". Nothing else moves — no phase change, no
   commitment yet.
4b. **The reversal.** She reconsiders and presses the firm seal again; it lifts back to
   faint, and the party sees "Wren lifted the seal on …" (`DESELECT_CONTRACT` →
   `CONTRACT_SELECTION {accepted:false}`). Sealing is a stance, not a commitment.
5. Settled on a charge, she returns to the wall (the parchment settles back) and walks to
   the Deploy Gate. There — a separate, deliberate act — she **commits** the party to
   DEPLOYING. (If she'd left the wall unsealed, the Gate would raise `NO_CONTRACT_SELECTED`
   on the top-centre toast.) **DEPLOYING is a staging screen, not the field**: the
   expedition launches on a *second* Deploy action from the Gate (R128) — out of scope for
   this reskin, but the reader should not conflate DEPLOYING with field entry.

# Key Flow — "Bede watches from the bench" (non-leader)

Bede is in Wren's party but not the leader, standing at the same board.

1. He opens the same **SANCTION** notice in his own reader.
2. The seal shows **read-only** — no stamp affordance, captioned "Awaiting the leader's
   seal." He cannot seal or commit; the board is the leader's to work.
3. When Wren seals (step 4 above), Bede's seal turns **firm** and the toast reaches him —
   the state travelled on the snapshot, not a local guess. When she lifts it, his seal
   goes faint again. He reads the wall and talks; the co-op decision is a conversation.

# Inspiration & Anti-patterns

- **Inspiration:** `imports/notice-board-2.jpg` (carved frame, hanging placard, flanking
  torches) for structure; `imports/notice-board-1.jpg` (layered aged parchment, torn
  edges, corner studs) for density.
- **Anti-patterns:** target portraits on notices; size-encodes-tier; tavern whimsy;
  painterly/HD; motion that carries state; decay occluding a live headline; any game
  logic in a render scene.
