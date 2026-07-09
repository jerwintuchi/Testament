# Behavior-Drift Review — Notice Board Pass-2 Reskin

**Reviewer scope:** read-only consistency check of the reskin's `EXPERIENCE.md` and
`DESIGN.md` against the locked, tested behavior in `specs/notice-board`
(`requirements.md` R118–R128, `design.md`, `playtest.md`). The reskin is a *look*
delta; any place it silently re-specifies, contradicts, or drifts from the locked
behavior is a finding.

---

## Overall verdict

**PASS — no critical or high drift.** The reskin is scoped correctly as a
look-not-behavior delta and stays faithful to the locked flow on every load-bearing
point: the reversible leader seal (`SELECT_CONTRACT`/`DESELECT_CONTRACT`,
non-committing, leader-only, non-leaders read-only, `CONTRACT_SELECTION` toast), the
staged commit at the Deploy Gate, take-down-to-read, trait containment, and the
verb→headline mapping all match `specs/notice-board` verbatim where they touch
behavior. Terminology (message names, placard text, seal captions, toasts, headline
words, empty-Archive line) is identical to the authoritative spec and client helpers.

Only **3 low-severity polish notes** remain — an invented cosmetic term, an
incomplete narration of the two-stage DEPLOY, and a captioning-clarity nit. None
change behavior; none block the reskin.

---

## Point-by-point verification

**1. Reversible leader seal (R124 / R127) — CONSISTENT.**
`EXPERIENCE.md` "Game Feel" (line 63), "State Patterns" (lines 73–75), and Key Flow
step 4 (lines 101–103) all describe the seal as: leader stamps faint→firm; state
*derived from the snapshot's `contract`* so every client agrees; non-leader is
read-only; the party toast *"fires from the server `CONTRACT_SELECTION`"*; and
crucially *"no phase change, no commitment yet … She could lift it just as easily."*
That is an exact behavioral match to R124/R127 (reversible, non-committing,
leader-only, snapshot-derived).

**2. Two-stage DEPLOY (R128) — CONSISTENT (see finding B for a completeness nit).**
IA (line 38) and Key Flow step 5 (lines 104–105) place the commit at the Deploy Gate
as *"a separate, deliberate act"* moving to DEPLOYING — matching R128's WAITING→
DEPLOYING commit stage and the `NO_CONTRACT_SELECTED` guard implicitly (commit
requires a selection). No contradiction.

**3. Take-down-to-read (R123) — CONSISTENT.**
The Scope note (line 18) lists take-down-to-read among unchanged behaviors and the
"Reader transition" (line 66) treats it purely as a cross-fade. Nothing in the reskin
claims a message is sent on open/close, and behavior is explicitly deferred to
`specs/notice-board`. No drift.

**4. Trait containment (R125) — CONSISTENT.**
`EXPERIENCE.md` step 2 (*"no target art to give the game away"*) and Anti-patterns
(line 111, *"target portraits on notices"*) match `DESIGN.md` Brand rules (lines
70–72) and Don'ts (line 185). No trait data or target art is introduced anywhere.

**5. Terminology — CONSISTENT (one low nit, finding A).**
- Message/event names: `SELECT_CONTRACT`, `DESELECT_CONTRACT`, `CONTRACT_SELECTION`
  used exactly as in `requirements.md`/`design.md`.
- Verb→headline: `INQUIRY` / `SANCTION` / `CONTAINMENT ORDER` / `RITE OF BANISHMENT`
  (line 45) — byte-identical to R120.
- Placard: `PETITIONS BEFORE THE COLLEGIUM` — matches R122 AC and playtest Setup.
- Seal captions: *"Stamp your seal to take up this charge."* / *"Sealed. The charge
  is taken up."* / *"Awaiting the leader's seal."* (lines 46–47) — match R124 AC +
  `design.md` line 148.
- Toasts: *"<who> sealed the charge: <target>"* / *"<who> lifted the seal on
  <target>"* (line 48) — match R124 AC and playtest Item 4.
- Empty Archive line: *"No prior testament on record."* (line 50) — matches
  `design.md` line 89 and playtest Item 3.
- Client helper names (`_build_contract_board` / `_build_notice_reader` /
  `_seal_block`, lines 27–28) match `design.md`'s Phase C/D helpers.
No invented or mismatched behavioral term found (except finding A, a cosmetic label).

**6. Self-scoping — CONSISTENT.**
The Scope note (lines 16–22) and IA header (line 34, *"unchanged; restated"*)
correctly frame the doc as a delta and defer authority to `specs/notice-board`
(*"Spines win on conflict with any mock"*; `DESIGN.md` line 191). No over-reach into
re-authoring tested behavior.

---

## Findings

### A. "AUTHORIZED"-style wax settle is an invented, off-register term — **[low]**
- **Reskin (`EXPERIENCE.md`, line 63):** *"a crimson wax **\"AUTHORIZED\"-style**
  settle is cosmetic only, never a gate."*
- **Locked spec:** the seal's vocabulary is the sacred register only — captions
  *"Stamp your seal to take up this charge." / "Sealed. The charge is taken up." /
  "Awaiting the leader's seal."* (R124, `design.md` line 148). `AUTHORIZED` appears
  nowhere in `specs/notice-board` and clashes with the sacred-register rule
  (`DESIGN.md` Typography line 30; Don'ts line 187).
- **Contradiction:** minor. The word is qualified *"-style … cosmetic only, never a
  gate,"* so it does not re-specify behavior — but an artist or mock author could
  read `AUTHORIZED` as a caption/stamp string to render, introducing a
  bureaucratic-English label into a sacred-register surface.
- *Fix:* drop the word `AUTHORIZED` and describe the effect in register, e.g. *"the
  wax presses from faint to firm with a brief settle — cosmetic only, never a gate."*
  Keep all rendered text drawn from the R124 caption set.

### B. Key Flow narrates only the *commit* half of the two-stage DEPLOY — **[low]**
- **Reskin (`EXPERIENCE.md`, lines 104–105):** *"walks to the Deploy Gate, and there
  … commits the party to DEPLOYING."* IA (line 38): *"[later, at the Deploy Gate]
  commit → DEPLOYING."*
- **Locked spec (R128):** DEPLOY is two-stage — the Deploy-Gate press in **WAITING**
  is the commit (→ DEPLOYING, no field yet), and a *second* Deploy-Gate press in
  **DEPLOYING** is the launch (→ `FIELD_STARTED`).
- **Contradiction:** none — but the narration stops at DEPLOYING and never mentions
  the launch stage, so a reader could conflate "DEPLOYING" with "in the field" and
  under-build the DEPLOYING-state Deploy Gate. This is a completeness gap, not a
  contradiction; behavior is deferred correctly to the spec.
- *Fix:* add one clause noting DEPLOYING is a staging screen and the field starts on a
  second, separate Deploy action — or explicitly mark the launch stage out of scope
  for this reskin so no one assumes DEPLOYING == field entry.

### C. Seal captions are listed flat, without leader/non-leader/state binding — **[low]**
- **Reskin (`EXPERIENCE.md`, lines 46–47):** the three captions are listed as a
  voice inventory with no indication of which caption belongs to which actor/state.
- **Locked spec (R124 / `design.md` line 148):** the bindings are specific —
  *"Stamp your seal to take up this charge"* is the **leader/unsealed** affordance;
  *"Awaiting the leader's seal."* is the **non-leader/unsealed** read-only caption;
  *"Sealed. The charge is taken up."* is the **sealed** caption (both roles).
- **Contradiction:** none (the strings match); risk is only that an implementer
  reading the voice doc in isolation could mis-bind a caption to the wrong
  role/state.
- *Fix:* annotate each caption with its state/role binding, or add a one-line pointer
  to R124 for the authoritative mapping.

---

## Notes (no action)

- `DESIGN.md` is purely visual and correctly defers all flow to `EXPERIENCE.md` /
  `specs/notice-board` (line 191); its Origin-keyed `WaxSeal` and `ThreatPips` reuse
  matches R126. No behavior drift there.
- The reskin never invents an error code, never claims the seal gates anything, and
  never assigns a class/role — all consistent with the locked invariants.
