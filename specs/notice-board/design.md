# Design — The Notice Board (procedural notices, sacred register)

> Satisfies R118–R126. One new server/shared field (`requester`); everything else
> is client presentation over existing intents. Trust boundary unchanged: all game
> state is server-side; the client renders `ContractIntel` and emits `TOGGLE_READY`
> / `SELECT_CONTRACT` (I1/I2). Trait containment holds — `requester` is intel, not a
> roll, and `toContractIntel` still strips seed+roll (I3/I5).

---

## Phase A — Requester intel

### Data (shared) — `src/shared/src/contract.ts`

```ts
export type Requester = {
  name:  string;   // "" ⇒ anonymous ("an unnamed <role> of <place>")
  role:  string;   // Reliquary-Steward, Parish-Priest, Proctor, Warden, Archivist, penitent…
  place: string;   // Ashfen, Gall, Low Fen, the Sunken Nave…
};
export type ContractIntel = {
  contractId: string; tier: Tier; origin: Origin;
  requester: Requester;                 // NEW — who petitioned the charge
  targetName: string; siteName: string; primaryVerb: PrimaryVerb;
};
```

`Requester` is types-only; no logic in `src/shared` (I4).

### Generation (server) — `src/server/src/incarnate/generateContract.ts`

Authored tables (server-only) + a pure `pickRequester(rng)`:

```ts
const REQUESTER_NAMES:  readonly string[] = ['Aldis Vane', 'Sister Wren', 'Hald', 'Bede', 'Mother Sael', …];
const REQUESTER_ROLES:  readonly string[] = ['Reliquary-Steward', 'Parish-Priest', 'Proctor', 'Warden', 'Archivist', 'Almoner', 'Sexton'];
const REQUESTER_PLACES: readonly string[] = ['Ashfen', 'Gall', 'Low Fen', 'the Sunken Nave', 'Hollowmere', …];
const ANON_ROLES:       readonly string[] = ['penitent', 'pilgrim', 'lay witness'];

function pickRequester(rng: Rng): Requester {
  // ~1 in 5 anonymous: name '', an ANON_ROLE, a place.
  if (rng.next() < 0.2) return { name: '', role: rng.pick(ANON_ROLES), place: rng.pick(REQUESTER_PLACES) };
  return { name: rng.pick(REQUESTER_NAMES), role: rng.pick(REQUESTER_ROLES), place: rng.pick(REQUESTER_PLACES) };
}
```

Called inside `generateContract` (after `primaryVerb`, before `traitRoll`, keeping
the roll last). Deterministic: same seed → same requester (I3). `toContractIntel`
already spreads all non-(seed/roll) fields, so `requester` crosses as intel for free.

### Wire

`LobbySnapshot.board` / `contract` already carry `ContractIntel`; they gain
`requester` automatically. No new message. No new error code.

## Phase B — Procedural notice content (client)

A small client module `client/scripts/ui/notice.gd` (preloaded, not a global
class_name — TD-029/30) turns one `ContractIntel` dict into notice strings. Pure
functions of intel + `contractId`; no game logic, no server calls.

### Headline (R120) — sacred register by verb

```
const HEADLINE := {
  "INVESTIGATE": "INQUIRY",
  "ELIMINATE":   "SANCTION",
  "CAPTURE":     "CONTAINMENT ORDER",
  "BANISH":      "RITE OF BANISHMENT",
}
```

### Body grammar (R121)

Per-verb **charge** grammar (the current `VERB_SYNONYM` / `VERB_QUALIFIER` /
`CHARGE_LOCALE`, already in `main.gd`, move here and expand), plus a short
**preamble** frame that names the requester's concern. All slots come from intel:

```
charge  = "<Verb-synonym> the <target>, <locale(site)>. <qualifier(verb)>."
preamble= one of a few frames: "The <role> of <place> reports …", "A plea reaches the
          Archive from <place> …", seeded by contractId (independent hash offset).
sign    = name == "" ? "— an unnamed <role> of <place>"
                     : "— <name>, <role> of <place>"
```

Every slot is intel; the verb hint survives because each synonym conveys the verb
and the qualifier restates it. **No** trait-derived text: no signs, reward, gear, or
expedition notes; the Archive line stays the honest `"No prior testament on record."`
(R121 AC / P64).

## Phase C — Notice-board layout (client) — `main.gd` `_build_contract_board`

The board stops being a scroll of cards. It becomes a fixed **canvas** the wooden
panel wraps, with notices placed by seed:

- The popup keeps its full-screen wood skin (already done). Its body is a single
  `Control` (`_board_canvas`) of the board's inner size; **no ScrollContainer** for
  the notices (R122).
- **Slots + jitter:** a fixed set of anchor rects (one per notice) spread across the
  canvas; each notice takes its slot's centre plus a seeded offset, rotation
  (±~4°), size pick (from 2–3 portrait sizes, e.g. 150×200 / 168×224), tack style,
  and parchment texture variant — all from `hash(contractId)` (flavor notices from
  their own index). Slots are spaced so live text never overlaps (R122 AC).
- **Live vs. flavor:** the 4 board contracts render as fresh, clickable notices; a
  handful of **flavor notices** (a client-authored `FLAVOR_NOTICES` table — an old
  warning, a penitent's plea, a faded rite-notice) render dimmer/aged and
  `mouse_filter = IGNORE` (never selectable — P65).
- A **compact notice** (`_make_notice(intel, slot)`) shows headline + target + site
  + threat pips + wax seal, sized to a portrait rect; the full prose is read only in
  the enlarged view (keeps the wall glanceable).

`ContractNotice` visual (reusable, R126): a `Button` (live) or `Panel` (flavor) with
a torn-parchment `TextureRect` bg, the `WaxSeal` (Origin) as its tack, and the
`ThreatPips`. Hover lifts a live notice slightly (existing `_hover_card`).

## Phase D — Read + authorization (client)

### Take-down-to-read (R123)

Clicking a live notice sets `_open_notice = intel` and shows `_notice_reader` — a
centred, enlarged parchment over a second dim layer inside the popup (the board
stays behind, dimmed). Built by `_build_notice_reader(intel)`:

- headline (sacred), target (large ink), `Site — <site>`, asserted-Origin row (seal
  + gloss), `Threat` + pips, the **preamble + charge** prose, the Archive line, and
  the **signature**.
- a **Return to the board** affordance (and click-off on the dim layer) clears
  `_open_notice` and hides the reader. Pure view state (I1).

### The seal (R124, revised TD-041) — the seal block on the reader

> Superseded the per-Seeker signature ledger + leader countersign (see below). The
> playtest showed acceptance wants to be a **reversible seal** the leader stamps and
> lifts, decoupled from the irreversible commit. TD-041 records the change.

Rendered at the foot of the enlarged notice as a single **seal block**
(`_seal_block(intel)`):

- One wax-seal affordance whose **whole area is the hit target** ("Stamp your seal
  to take up this charge"). Its state is derived from the snapshot's `contract`:
  **sealed** when `contract.contractId == _open_notice.contractId`, else **faint**.
  A `WaxSeal` (Origin-keyed) draws firm (`modulate.a = 1.0`) when sealed, faint
  (`0.30` for the leader, `0.18` for others) when not.
- The **local leader** clicking the faint seal sends `SELECT_CONTRACT
  { contractId }`; clicking the firm seal sends `DESELECT_CONTRACT {}` — a
  reversible take-up/lift. **Non-leaders** get no button: the seal is read-only,
  captioned "Awaiting the leader's seal." / "Sealed. The charge is taken up."
- Selection is **non-committing**: no phase change, no Surety. The whole party is
  notified of a stamp/lift by the transient `CONTRACT_SELECTION` toast (a top-centre
  `_show_toast`), and the seal itself updates for everyone when the `LOBBY_UPDATED`
  snapshot rebuilds the reader.
- The **commit** to DEPLOYING is not here — it happens at the **Deploy Gate** via the
  two-stage `DEPLOY` (below), keeping "read the charge" and "take the party out" as
  separate deliberate acts. Affordance ≠ authority: a raced `NOT_*`/`WRONG_PHASE`
  still surfaces (P66).

### Server — reversible selection & staged commit (R127/R128, TD-041)

- `handleSelectContract` (`src/server/src/rooms/handlers/selectContract.ts`):
  gates leader + WAITING + at CONTRACT_BOARD + id-on-board (else the matching error
  to the sender only, I2), then sets `room.contract` (promoted board entry, never a
  re-roll) **without** touching phase, and broadcasts `LOBBY_UPDATED` +
  `CONTRACT_SELECTION { accepted: true, targetName, actorName }`.
- `handleDeselectContract` (`deselectContract.ts`): same gates; clears
  `room.contract` and broadcasts snapshot + `CONTRACT_SELECTION { accepted: false }`.
  A deselect with nothing selected is an idempotent no-op (no error, no mutation, no
  broadcast).
- `handleDeploy` (`deploy.ts`) is two-stage: in **WAITING** it is the **commit** —
  requires `room.contract` (else `NO_CONTRACT_SELECTED`), sets `WAITING → DEPLOYING`,
  broadcasts `ROOM_DEPLOYING` (Surety hook lands here later); in **DEPLOYING** it is
  the unchanged **launch** to FIELD.

New wire (TD-041): client→server `DESELECT_CONTRACT {}`; server→client
`CONTRACT_SELECTION { accepted, targetName, actorName }` (transient toast — the
authoritative selection travels on the snapshot's `contract`); error
`NO_CONTRACT_SELECTED`. `SELECT_CONTRACT` is redefined reversible; `ACCEPT_CONTRACT`
is kept only as a legacy/test convenience (select-first + commit).

## Correctness Properties

- **P64 (notice is intel, R118/R121/R125):** every notice string derives from
  `ContractIntel` (incl. `requester`) + `contractId` + client flavor; no serialized
  board/contract field is a trait-roll axis, and no notice renders a trait value.
- **P65 (flavor is inert, R122):** a decorative notice has no `contractId`, is not
  clickable, and can never be selected/accepted; only the 4 live contracts emit.
- **P66 (affordance ≠ authority, R124/R127/R128):** stamping the seal, deselecting,
  and deploying are server-validated intents; enabling/showing a control never
  authorizes, and a raced `NOT_*`/`WRONG_PHASE`/`UNKNOWN_CONTRACT`/
  `NO_CONTRACT_SELECTED` still surfaces (P56/P62 heritage).
- **P67 (requester determinism, R119):** `pickRequester` is a pure function of the
  seeded `rng`; the same expedition seed yields the same board of requesters.
- **P68 (verb hint survives, R120/R121):** the headline is a total function of the
  verb, and every charge synonym conveys the verb's meaning (a wrong-verb read is
  never produced from a right-verb contract).
- **P69 (selection is reversible & non-committing, R127):** `SELECT_CONTRACT` /
  `DESELECT_CONTRACT` mutate only `room.contract` (never phase) after all gates pass;
  a deselect with nothing selected mutates nothing; only these two handlers set
  `room.contract` in WAITING (I2).
- **P70 (commit is staged & guarded, R128):** phase advances `WAITING → DEPLOYING`
  only inside `handleDeploy` and only with a non-null `room.contract`; a commit with
  no selection mutates nothing (`NO_CONTRACT_SELECTED`).

## Wire Protocol Summary

New shared: `Requester` type; `ContractIntel.requester`. New server:
`pickRequester` + tables in `generateContract`. Wire additions (TD-041): client→
server `DESELECT_CONTRACT {}`; server→client `CONTRACT_SELECTION { accepted,
targetName, actorName }`; error `NO_CONTRACT_SELECTED`. `SELECT_CONTRACT` redefined
reversible (no phase change); `DEPLOY` redefined two-stage (commit then launch).
Reused unchanged: `ROOM_DEPLOYING`, `FIELD_STARTED`, the `NOT_AT_*` gates. No trait
data added to any message (I3/I5).

## Superseded

The Station UI v2 *client* board (T124): the two-panel wall/desk render is replaced
by this notice-board render. The **server** board pool (T122/R109) and leader
selection (T123/R110) are unchanged and reused. `ThreatPips` and `WaxSeal` (from
TD-039) are reused as-is. The obsolete `_build_contract_wall` / `_build_reading_desk`
/ `_build_authorization_bar` / desk helpers are removed in favor of the notice
render + reader; `_contract_brief` and the charge grammar move into `notice.gd`.
