# Requirements — The Notice Board (procedural notices, sacred register)

> Phase 5. Redesigns the Contract Board from a menu into the Collegium's **notice
> board** — a wooden installation of portrait parchment notices at varied size,
> rotation, and tack, each a full poster generated procedurally and **signed by
> the petitioner who reported the Manifestation**. Supersedes the *client render*
> of the Station UI v2 board (T124/R111): the server board pool (T122/R109) and
> leader selection (T123/R110) are unchanged and reused.
>
> **Canon this honors (do not re-litigate):**
> - *The Collegium issues the charge from a report it received* — a contract is
>   the order dispatching scholars to witness/contain/redeem a **reported**
>   Manifestation (`docs/lore/collegium.md`). So a notice is **signed by its
>   petitioner** — a new, wire-safe piece of intel (never trait data).
> - *Intel is partial, and trait-free* — a notice shows only `ContractIntel`, never
>   the hidden roll (I3/I5); **no Incarnate art** (mystery is the mechanic).
> - *Verbs are the order's language* — witness/contain/redeem map to the primary
>   verbs; notice headlines use the Collegium's **sacred register**, not a guild's.
> - *Roles emerge from loadout* — the board never assigns a class.
>
> Numbering continues: **R118+**, correctness **P64+**, tasks **T131+**. Trust
> boundary unchanged: server authoritative, client render+intent only (I1/I2). The
> only new server *data* is the `requester` intel field; the notice **look and prose**
> are client presentation. The authorization flow was reworked mid-build
> (**DECISION_LOG TD-041**): acceptance is a **reversible seal** decoupled from the
> commit, so the server grows a small intent surface — `SELECT_CONTRACT` redefined
> reversible, new `DESELECT_CONTRACT`, a transient `CONTRACT_SELECTION` toast, a
> two-stage `DEPLOY`, and the `NO_CONTRACT_SELECTED` error. R124 below is the
> post-TD-041 requirement; R127/R128 capture the new server behavior.

---

## Phase A — Requester intel (who petitioned the charge)

**R118** (shared): `ContractIntel` carries a **requester** — the petitioner who
reported the Manifestation.
- AC: `ContractIntel` gains `requester: Requester` where
  `Requester = { name: string; role: string; place: string }` (`name` may be `""`
  for an anonymous petitioner); types/constants only, `src/shared` stays logic-free (I4).
- AC: the requester is intel, not trait data — the serialized `ContractIntel` still
  contains **no** trait-roll axis anywhere (P64, standing I3/I5).

**R119** (server): `generateContract` seeds the requester deterministically.
- AC: the requester is drawn from authored name/role/place tables via the existing
  seeded `rng` inside `generateContract`; same seed → identical requester (I3).
- AC: `toContractIntel` carries `requester` through unchanged; the intel key set
  grows by exactly one (`requester`), still stripping `expeditionSeed`/`traitRoll`.

## Phase B — Procedural notice content (client)

**R120** (client): a notice's **headline** is the Collegium's sacred register,
a pure function of the primary verb.
- AC: `INVESTIGATE → "INQUIRY"`, `ELIMINATE → "SANCTION"`,
  `CAPTURE → "CONTAINMENT ORDER"`, `BANISH → "RITE OF BANISHMENT"` (exact wording
  is design's to finalize); the mapping is total and deterministic — no trait input.

**R121** (client): a notice's **body prose** is procedural and preserves every
piece of intel.
- AC: the body is assembled from an archetype grammar with slots
  `{target}`, `{site}`, `{requester}`, `{threat}`, `{verb-phrase}`, filled from the
  contract's intel and chosen deterministically from `contractId` (same contract →
  identical notice, always).
- AC: the rendered notice always shows the **target**, the **site/location**, a
  **threat** read (pips from `tier`), a **verb-faithful charge** (every synonym of a
  verb still conveys that verb's meaning), and a **signature** naming the requester
  (`"{name}, {role} of {place}"`, or `"an unnamed {role} of {place}"` when
  `name == ""`).
- AC: the body invents no trait-derived content — **no Known Signs, no reward, no
  recommended gear, no expedition notes** (those need server systems that do not
  exist yet; the Archive line stays the honest empty state). (P64)

## Phase C — Notice-board layout (client)

**R122** (client): the board renders as a wooden installation of parchment
notices in a **dense organic scatter** filling the whole board — no ScrollContainer.
(Arrangement per TD-040: reference-driven, overlap permitted.)
- AC: each notice is placed at a **seeded** position/rotation/size/tack
  (nail·wax·pin·ribbon) and parchment-texture variant from `contractId`, scattered
  across the entire board (not a row) at human angles with a seeded jitter so no two
  align.
- AC: notices **may overlap** at their corners to read as a maintained wall, but a
  **live notice's headline/target is never occluded** at rest: live notices draw
  **above** flavor scraps, are clamped inside the wooden frame, and a hovered live
  notice raises to the front. Flavor scraps are `MOUSE_FILTER_IGNORE`, so an overlap
  never steals a live notice's click (P65).
- AC: live-contract **sizes vary dramatically** (small notes → big posters), seeded
  from `contractId`; the size is **purely aesthetic and never encodes tier**
  (equal-weight contracts — the mystery is the mechanic).
- AC: the board carries a carved **placard header** ("PETITIONS BEFORE THE
  COLLEGIUM") hung at top-centre in place of a plain text title.
- AC: the board shows the **4 live contracts** plus a few **decorative flavor
  notices** — non-interactive ambient papers (client-authored, pure ambiance) that
  are visibly *older/dimmer* and are **not** clickable; live notices read as fresh
  and clickable (P65: a flavor notice can never be selected or accepted).

**R123** (client): clicking a live notice **takes it down to read** — the parchment
enlarges to center over the dimmed board.
- AC: clicking a live notice opens the enlarged full notice (headline, target,
  site, asserted-Origin seal+gloss, threat, preamble+charge, Archive line,
  signature, seal block) over a dim backdrop; a **back/dismiss** returns it to the
  wall with no state change.
- AC: opening/closing a read is pure display — it sends nothing and mutates no game
  state (I1); the selection is client view state only.

## Phase D — Authorization by the leader's seal (client) — revised per TD-041

**R124** (client): the enlarged notice carries a **seal block** where the **leader**
takes up the charge with a single reversible stamp, over the existing board intent.
- AC: the seal block holds one wax-seal affordance whose whole area is the hit
  target ("Stamp your seal to take up this charge"). The seal is **faint** while
  unsealed and **firm** once sealed; its state is derived from the snapshot's
  `contract` (sealed ⇔ `contract.contractId == the open notice's id`), so every
  client sees the same seal state.
- AC: the **local leader** clicking the faint seal sends `SELECT_CONTRACT
  { contractId }` (take up the charge); clicking the firm seal sends
  `DESELECT_CONTRACT` (lift it). Selection is **reversible and non-committing** — it
  changes no phase and stakes no Surety; the actual commit happens later at the
  Deploy Gate (R128).
- AC: **non-leaders** see the seal state **read-only** (no stamp affordance —
  "Awaiting the leader's seal" / "Sealed."). The whole party is notified of a
  stamp/lift by a transient toast fed by `CONTRACT_SELECTION` ("<who> sealed the
  charge: <target>" / "<who> lifted the seal on <target>").
- AC: affordance ≠ authority (P66, P56 heritage): showing/enabling the stamp never
  authorizes; a raced `NOT_LEADER` / `NOT_AT_CONTRACT_BOARD` / `WRONG_PHASE` /
  `UNKNOWN_CONTRACT` still surfaces, no client gating substitutes for the server check.

## Phase D-server — reversible selection & staged commit (server) — TD-041

**R127** (server): contract selection is **reversible and non-committing**.
- AC: `SELECT_CONTRACT { contractId }` is honored only for the **leader**, in
  **WAITING**, standing at the **CONTRACT_BOARD**, with `contractId` on the board —
  else the matching error (`NOT_LEADER` / `WRONG_PHASE` / `NOT_AT_CONTRACT_BOARD` /
  `UNKNOWN_CONTRACT` / `INVALID_PAYLOAD`) to the sender only, no mutation (I2).
- AC: on success it sets `room.contract` to the promoted board entry (never a
  re-roll) **without** changing phase or staking a Surety; a second select replaces
  the first. It broadcasts the `LOBBY_UPDATED` snapshot (authoritative `contract`)
  and a transient `CONTRACT_SELECTION { accepted: true, targetName, actorName }`.
- AC: `DESELECT_CONTRACT` (same leader/WAITING/at-board gates) clears
  `room.contract` and broadcasts snapshot + `CONTRACT_SELECTION { accepted: false }`;
  a deselect with nothing selected is an **idempotent no-op** — no error, no
  mutation, no broadcast (I2).

**R128** (server): `DEPLOY` is a **two-stage** action; the commit is distinct from
the launch.
- AC: `DEPLOY` from the leader at the **DEPLOY_GATE** in **WAITING** is the
  **commit**: it requires a current selection (`room.contract`) — absent one, it
  rejects `NO_CONTRACT_SELECTED` to the sender with no mutation — and on success
  moves `WAITING → DEPLOYING`, broadcasting `ROOM_DEPLOYING` (this is where the
  Surety will be staked once that system lands). No `FIELD_STARTED` yet.
- AC: `DEPLOY` from the leader at the gate in **DEPLOYING** is the **launch**:
  unchanged field-start (site gen, spawns, per-player `FIELD_STARTED`). Gate/phase/
  leader errors still surface to the sender only.

## Cross-cutting

**R125** (trait containment, standing I3/I5): every byte of a notice the client
shows derives from `ContractIntel` (incl. `requester`) + the `contractId` seed +
client-authored flavor — **never** a trait-roll axis.
- AC: the serialized board/contract carries only intel keys incl. `requester`, no
  trait axis (serialized-shape assertion, P64).

**R126** (visual system / reuse, standing R117): the notice, the wax seal, and the
threat pips are reusable render-only components; no game logic lives in any notice
scene (they render snapshot/intel data and emit the existing intents).

---

## Verification

Server/shared requirements (R118, R119, R125, R127, R128) are verified by Vitest
colocated with the source — determinism of the requester, intel-key growth,
trait-containment shape assertions, the reversible select/deselect gates
(`selectContract.test.ts`, `deselectContract.test.ts`), and the two-stage deploy
commit/launch (`deploy.test.ts`). Client requirements (R120–R124, R126) have no
GDScript unit harness (prior client-spec convention) and are verified by an
MCP-driven playtest (`specs/notice-board/playtest.md`): the client logs the
load-bearing events (notice count live/flavor, headline per verb, requester
signature, open-read, seal stamp/lift, deploy commit→DEPLOYING) for
`get_debug_output`, run against `pnpm dev:server`, two clients for the
leader/non-leader and the seal-notification paths.
