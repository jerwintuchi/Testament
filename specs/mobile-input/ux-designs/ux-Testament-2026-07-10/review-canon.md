# Canon & Trust-Boundary Review — Testament Mobile Input

## Overall verdict

The spec is unusually disciplined on the trust boundary: "zero server change" is
*literally* true, the client-side legality recompute is a legitimately-precedented
render hint, and the deferrals (portrait, ATTACK/DODGE, haptics) are mostly honest.
Two things keep it from clean: it cites a **testing-convention precedent that exists
nowhere in the codebase** (T148's only named test hangs on it), and the **reserved
DODGE slot inherits the cluster's "draw-only-when-legal" doctrine, which points
directly at a future Pillar-3 trait-tell** — the deepest risk here, and the one the
spec names its danger but never fences off. Everything else is medium/low drift.

## Findings

- **[critical]** The `keepout seed=<s> ok=<bool>` **boot self-check is cited as an
  established client-spec precedent but does not exist in the code.** requirements.md:119
  ("the precedent set by the notice board's `keepout seed=<s> ok=<bool>`"), tasks.md:6
  and T148 (whose *only* named test is "boot self-check … logs `touch selftest
  dirs=24/24 …`"). A grep of `client/scripts/**` for `selftest|self.?check|dirs=|ok=true|assert(`
  returns nothing. The cited "precedent" appears only in `specs/notice-board/tasks.md:165`
  (T133) — which is **unchecked `[ ]`, i.e. itself unbuilt**. So the spec invents a
  verification mechanism and back-dates it as convention. The genuine prior client-spec
  convention (collegium-client, notice-board playtests) is **MCP playtest + `get_debug_output`
  logs**, not an assert-at-boot harness. vs `.claude/rules/spec-workflow.md` ("Nothing is
  'done' without a passing test that is named in the task" — the named test must be a real
  mechanism). *Fix:* either (a) build the boot self-check as a first, real deliverable and
  stop calling it precedent, or (b) drop it and verify T148's pure functions (`quantize8`,
  `next_walk`) through the established MCP-log path. Do not mark T148 done against a harness
  the repo has never run.

- **[high]** The **reserved `DODGE` slot is governed by D1 / R131's doctrine — "a control
  exists only while its action is legal"** — which is exactly the wrong gate for a dodge and
  sets up a Pillar-3 violation the moment the verb ships. EXPERIENCE.md:267-273 (Flow 3) +
  DESIGN.md:159-161 + R131 AC (requirements.md:57-58). combat.md:30,40 gates the dodge on
  *reading the Omen* ("Read the Omen and you get the window to dodge"; "the lethal Tell is
  always readable through its Omen"). If a future implementer applies R131 literally —
  DODGE is "legal" only when the dodge is *useful*, i.e. during the live Omen window — the
  button's **appearance becomes the Omen tell**, replacing the read the player was supposed
  to perform. That is a Sign readout by another name, forbidden by vision.md non-negotiable
  2 ("no knowledge as a number"), Pillar 3 (interpretation, never memorization), and the
  spec's own R137/P76 ("the HUD narrates the player, never the Incarnate"). The spec cites
  combat.md's Omen gating repeatedly but **never records the load-bearing constraint that
  resolves the R131-vs-R137 collision**. *Fix:* add an explicit rule now, while the grammar
  is being defined: the future DODGE control is **capability-gated** (drawn iff the Seeker
  carries the perception to read the Omen, exactly as Probe is bag-gated) and is **never
  gated on the live Omen sign**. The Omen stays unmarked; pressing dodge in its window is
  the player's skill, not the HUD's cue. (See dedicated section below.)

- **[medium]** DESIGN.md declares "**the stick is the only circle in Testament**"
  (DESIGN.md:39,136) but never pins **how the circle is rendered**, and `floating_stick.gd`
  is described as "pure geometry **+ draw**" (design.md:27,38). A runtime `draw_circle` /
  `draw_arc` primitive produces anti-aliased vector edges that violate the Nearest-filtered,
  16×16-class pixel canon the same file swears to (DESIGN.md:73-74, CLAUDE.md Art Direction /
  TD-033). vs CLAUDE.md CLOSED LIST ("Nearest filtering … palette-locked Aseprite sources").
  *Fix:* state that the ring/knob are palette-locked pixel assets (Aseprite or a `gen_*.py`
  sheet) blitted with Nearest, or a deliberately pixel-stepped draw — not a smooth vector
  primitive.

- **[medium]** **Resolution drift via the `inherits:` key.** DESIGN.md:12-13 inherits the
  notice-board spine "wholesale," and DESIGN.md:34-37 leaves the caption size as "one
  authored pixel-font size" with no number — inheriting it from that spine, whose
  `min_glyph` is authored at **480×270** (`specs/notice-board/ux-designs/ux-Testament-2026-07-09/DESIGN.md:36,46`).
  TD-042 explicitly supersedes 480×270 with **640×360** and flags that notice-board's
  `min_glyph`/contrast floor "were specified against 480×270 — both need reconciling."
  The mobile spec is meticulous about 640×360 for *every spatial* metric (DESIGN.md:41-51)
  yet silently inherits a **stale 480×270 font token** that its own accessibility floor
  (≥4.5:1 contrast, ≥40px targets, DESIGN.md:93-94) leans on. It defers "board layout at
  640×360" (design.md:122-124) but not its own caption size. vs TD-042. *Fix:* re-author the
  HUD caption size against 640×360 in this spec (captions are a mobile-HUD element, not
  borrowed board furniture), or state explicitly which inherited token is re-validated.

- **[low]** "**Station**" is used as canonical vocabulary throughout (EXPERIENCE.md:15,47,
  IA table; requirements.md R131) but is **not a GLOSSARY term**. It is repo-established in
  `specs/collegium`, so this is drift, not invention. vs `docs/GLOSSARY.md` (no "Station"
  entry; canonical usage is the named stations — Contract Board, Quartermaster, Deploy Gate).
  *Fix:* add "Station" to GLOSSARY if it is now canonical, or reference the named stations.

- **[low]** **Extract-button-reveals-the-tile.** R131 draws Extract "iff the Seeker is on the
  extraction tile" (requirements.md:51, design.md:80). One could argue finding the Extraction
  node should be the skill (Pillar 3). Ruling: **acceptable** — Extraction is a *visible* node
  in the authored site vocabulary (Approach/Sign-source/Lair/Extraction, TD-035), extraction
  is already position-gated server-side (`NOT_AT_EXTRACTION`), and this is the same affordance
  class as the committed `_active_station = _nearest_station()` "Press E" prompt (main.gd:677).
  Noted, not a violation. *Fix:* none; keep it symmetric with the station prompt.

- **[low]** **CLAUDE.md's Active Work block still points at `specs/station-ui`**, not even at
  the actually-in-flight notice board — pre-existing drift the mobile spec inherits, not its
  fault. The mobile `.decision-log.md:143-145` correctly declines to switch the active spec
  and flags that switching "needs its own DECISION_LOG entry." Per `.claude/rules/spec-workflow.md`
  this is **correct**: authoring a spec triple does not require the swap; *implementation* does.
  *Fix / gate:* before **T148 starts**, three things must land — (1) notice-board reaches a
  shippable stop, (2) CLAUDE.md Active Work swaps to `specs/mobile-input`, (3) a DECISION_LOG
  entry records the switch. Also note T153 and notice-board T142-T147 both edit
  `_build_contract_board` — coordinate to avoid a two-spec collision on the same board code.

## The Omen/Dodge question

This is the one place the spec quietly mortgages canon against a future task, so it deserves
the scrutiny.

**The mechanic (combat.md).** Survival is the third payoff of *understanding* (combat.md:29-30):
the lethal Tell is telegraphed by its **Omen** sign; a Seeker who *reads* the Omen earns the
window to dodge or ward. combat.md non-negotiable 4 makes the Tell "always readable through its
Omen … earned by reading a re-rolled trait, never by memorizing a fixed boss pattern." The
Omen is a **Sign** (GLOSSARY: signs are the only Incarnate information the client ever receives;
they are derived server-side from the hidden Tell, I5). So *when* to dodge is player-derived
knowledge read off a sign — precisely the thing Pillar 3 and vision.md rule 2 protect.

**The trap the spec builds.** The action cluster's founding doctrine (D1, `.decision-log.md:96-100`;
R131, requirements.md:49-58; DESIGN.md:154 "drawn only while its action is legal") is
*appearance == legality*. A control shows up exactly when acting is legal/useful and is absent
otherwise — that is the whole selling point ("the empty screen is the design"). Now reserve a
`DODGE` slot inside that doctrine. A dodge is only *useful* during the Omen window. The path of
least resistance for a future implementer is to make the reserved slot obey the same rule as
every sibling: **draw DODGE when the dodge is legal → draw it during the Omen window**. At that
instant the button's mere presence announces "an Omen is live; dodge now." The player no longer
reads the sign; the HUD reads it for them. That is a trait-tell — it violates R137/P76 (the HUD
must "narrate the player, never the Incarnate"), Pillar 3, and vision.md rule 2, and it
functionally leaks the derived state of the hidden Tell to the screen (the spirit of I3/I5).

**Both sides.** *For the spec:* today the slot **draws nothing** (DESIGN.md:159-161; R131 AC),
Flow 3 is explicitly "reserved, not built," and EXPERIENCE.md:174-177 already forbids a
per-Incarnate readout. Flow 3's own framing keys the control to capability — "Vidal, **who
carries the perception to read it**" (EXPERIENCE.md:269) — not to the live Omen, which is the
*correct* gate. So the raw materials for the safe answer are present. *Against the spec:* those
materials are scattered across a flavor flow and a general containment requirement; the **binding
grammar** (D1/R131) says the opposite, and nothing in requirements/design/tasks states the carve-out
where an implementer would look for it. R131 and R137 will collide at the DODGE slot and the spec
does not declare which wins.

**Ruling.** R137 must win, and the spec must say so **now**, because the grammar is being fixed
here and "reserved slot, defined grammar" is the spec's own justification for touching DODGE at
all. Add, to R131 (or a new R): *the ATTACK/DODGE slots, when populated, are gated on the Seeker's
capability (kit/perception), never on the live state of any Incarnate sign; DODGE in particular is
drawn iff the Seeker carries the perception to read the Omen — its presence must be identical
whether or not an Omen is currently firing, so the Omen read stays the player's.* Without that line,
the reserved slot is a loaded gun pointed at Pillar 3.

## Verified-compliant claims

- **"Zero server change" is literally true.** No task (T148-T156) touches `src/server` or
  `src/shared`; design.md "Wire Protocol Summary: None." The stick reuses `MovePayload
  { dx, dy, walk? }`, which already carries `walk` (`src/shared/src/fieldMessages.ts:26`).
- **Client-side legality recompute is a render hint, not I1 game logic.** It is the same class
  as the committed `_active_station = _nearest_station()` (main.gd:677) driving the "Press E"
  prompt; the server independently enforces `NOT_AT_*`/kit gates (P62). design.md:84-88 states
  this correctly. Not an I1/I5 violation.
- **Probe legality is capability-gated, not Incarnate-gated** — "local bag contains any
  PROBE-kind item" (design.md:80) narrates the player, honoring R137.
- **Haptics and accessibility captions are not new tools.** They are Godot 4.7 runtime engine
  features (`Input.vibrate_handheld`, Control accessibility), orthogonal to the TD-033
  authoring-tool CLOSED LIST (which governs Aseprite/PIL/Godot as *authoring* tools). No tool,
  asset type, or `.blend`/`.psd`/`.mdp` is introduced.
- **8-way quantization respects the wire.** `quantize8 → Vector2i ∈ {-1,0,1}²` (design.md:44-48)
  gives touch no precision the keyboard lacks — honors "peers, not a port" (EXPERIENCE.md:30-33).
- **Hover-raise removal (T153/R133) targets real code** — the committed `card.mouse_entered …
  move_to_front` / `_hover_card` at main.gd:1010, 1408. The task is runnable, not speculative.
- **Not switching the active spec is correct** per spec-workflow (`.decision-log.md:143-145`),
  provided the swap + DECISION_LOG entry land before T148 begins (see low finding).
- **Microcopy honors GLOSSARY** where terms exist: "Present the relic" matches Probe's definition
  ("present a relic … expose the Incarnate to a stimulus"); "Extract"/"Extraction", "Seeker",
  "Contract Board", "Surety", "Omen" used as written.
