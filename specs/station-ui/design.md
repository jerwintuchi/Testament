# Design — Station UI v2 (Preparation Loop, Themed)

> Satisfies R109–R117. Server grows a contract **board** and a **Stipend**;
> shared grows priced/descriptive gear and a `SELECT_CONTRACT` message + snapshot
> fields; the client rebuilds the three station popups as themed, data-driven
> scenes. Trust boundary unchanged: all game state is server-side; the client
> renders snapshot data and emits intents (I1/I2). Trait containment is preserved
> by reusing `toContractIntel` — the board is intel, never rolls (I3/I5).

---

## Phase A — Contract Board

### Data (server)

`RoomRecord` gains `board: ContractRecord[]` (full records held server-side) and
keeps `contract: ContractRecord | null` (the *selected* one). The board is built
once, at room creation, from the expedition seed:

```ts
// src/server/src/incarnate/generateBoard.ts  (pure, seeded — I3)
export function generateBoard(rng, expeditionSeed, size = BOARD_SIZE): ContractRecord[]
  // size distinct contractIds; each via the existing generateContract(rng, tier, id, seed).
  // Tier selection is v1-fixed (APPRENTICE) until Collegium Rank exists (TD-012);
  // the tier field is already on every record, so raising it later is data-only.
```

Wired in `createRoom` (where the room + seed are minted). The board is **derived
state**, never persisted (I7): a restart regenerates it from the seed.

### Wire (shared)

- `LobbySnapshot` gains `board: ContractIntel[]` — `room.board.map(toContractIntel)`.
  Intel-only by construction (R116): `toContractIntel` already strips the roll.
- New client→server `SELECT_CONTRACT { contractId: string }` (add to the message
  registry `src/shared/src/messages.ts` so codegen emits `Protocol.SELECT_CONTRACT`).
- New error codes: `UNKNOWN_CONTRACT` (id not on board). Existing `NOT_LEADER`,
  `NOT_AT_CONTRACT_BOARD`, `WRONG_PHASE`, `PARTY_NOT_READY` are reused.

### Handler (server) — `handleSelectContract`

Mirrors `handleAcceptContract`'s guards (leader, at board, ready, WAITING) and
adds the board lookup. On success it *promotes* a board entry rather than rolling
a fresh contract:

```
validate: in room? leader? at CONTRACT_BOARD? phase WAITING? party ready?
find = room.board.find(c => c.contractId === contractId)
  none -> LOBBY_ERROR UNKNOWN_CONTRACT (sender only), no mutation
room.contract = find; room.phase = 'DEPLOYING'      // Surety staked here (TD-004)
broadcast ROOM_DEPLOYING { contract: toContractIntel(find) }
```

`ACCEPT_CONTRACT` is **redefined** as "select the first board entry" (kept for the
current tests/flow) or removed in favor of `SELECT_CONTRACT`; the task picks one
and updates `acceptContract.test.ts` accordingly. Either way exactly one contract
promotion path stakes the Surety.

## Phase B — Quartermaster / Stipend

### Data (shared)

`GearItem` gains two authored fields:

```ts
export type GearItem = { id: ItemId; name: string; price: number; description: string }
  & ( { kind: 'PERCEPTION'; channel: Channel } | { kind: 'PROBE'; stimulus: Stimulus } );
```

`GEAR_CATALOG` fills `price` from a small authored table keyed to *what the item
unlocks* (a channel or a stimulus), not to power (loadout-economy §"priced by
utility"). `description` is the flavor + function line the detail panel shows.
New constant `STARTING_STIPEND`. These are constants/types only — `src/shared`
stays logic-free (I4).

### Data (server)

`RoomRecord` gains `stipend: number` (init `STARTING_STIPEND` at createRoom;
ephemeral, I7). `LobbySnapshot` gains `stipend: number`.

### Handler (server) — extend `handleRequisition`

Existing slot-bound check stays; add a cost check and a debit:

```
cost = sum(GEAR_CATALOG[id].price for id in requested)   // recompute from catalog, never trust a client total
requested.length > BAG_SLOTS       -> LOBBY_ERROR (existing slot error)
cost > room.stipend                -> LOBBY_ERROR INSUFFICIENT_STIPEND (sender only)
else: actor.bag = requested; room.stipend -= cost         // authoritative debit
      broadcast lobby snapshot (carries new bag + stipend)
```

Recomputing `cost` from the catalog each time (never from a client-supplied
number) keeps the balance drift-free and honors I2. *(v1 keeps the bag as a
bounded set of item ids — no per-item quantities, no sell; consumable stock and
sell-back are a later economy spec, matching loadout-economy "Future Expansion".)*

## Phase C — Deploy Gate

No new server data: the summary is `room.contract` (already broadcast as intel)
and the party is the existing roster (display name, ready, bag). Reward/duration
are **not** invented — omitted until a system produces them (Stipend reward
scaling is TD-017, a later task). Role labels are **not** assigned; the roster
shows each Seeker's bag as their emergent role (canon).

## Client — themed, data-driven scenes

New scenes under `client/scenes/ui/`, all render-only Controls themed by the
existing `_build_popup_theme` (extended into a small reusable `ui_theme.gd`):

```
contract_card.tscn      # parchment card: name, site, ThreatPips, verb (NO art)
threat_pips.tscn        # N filled/empty diamonds from a tier -> int mapping
contract_detail.tscn    # the selected card enlarged + Accept (leader)
gear_slot.tscn          # one catalog/loadout cell (greybox glyph until art)
item_detail.tscn        # name, kind, description, "Reads: <channel>" line
```

`main.gd` `_build_station_content` (today a `match` that builds simple buttons)
becomes a dispatch to three builders:

- `_build_contract_board()` — a `GridContainer` of `contract_card` instances from
  `snapshot.board`; card `pressed` → `_select_card(id)` shows `contract_detail`;
  Accept → `send_message(Protocol.SELECT_CONTRACT, { contractId })`. Logs
  `board cards=N`, `select <id>`.
- `_build_quartermaster()` — a `GridContainer` of `gear_slot` from `Catalog.GEAR`;
  selecting fills `item_detail`; an equipped row from the local bag; a footer with
  `used/BAG_SLOTS`, Stipend balance, selected-cost, and **Requisition**. Logs
  `requisition cost=C balance=B`.
- `_build_deploy_gate()` — `contract_detail` (read-only summary) + a party
  `VBox` (name · ready · bag) + **Deploy**. Logs `deploy target=<name>`.

**ThreatPips** is the reusable widget (R117): `set_tier(tier_string)` → draws
filled diamonds up to a fixed max. Pure display; it never sees a trait value.

Gear **icons** are greybox glyphs (a lettered/'?' cell) in v1; authored 16×16
Aseprite icons are a later art task — `gear_slot` exposes a `set_icon(texture)`
seam. The theme, threat pips, and card frames are the visual payload now.

## Correctness Properties

- **P58 (board is intel, R109/R116):** the wire board is `ContractIntel[]` via
  `toContractIntel`; no serialized board/contract field is a trait-roll axis.
- **P59 (selection is authoritative, R110/I2):** a body's contract/phase changes
  only inside `handleSelectContract` after all guards pass; no client path sets them.
- **P60 (Stipend accounting, R113):** balance debits equal the catalog-summed cost;
  an over-budget or over-slot requisition mutates nothing; balance is never negative.
- **P61 (utility pricing, R112):** prices are an authored table; the test forbids a
  monotonic power→price ladder assumption (no "bigger numbers" shopping).
- **P62 (affordance ≠ authority, R111/R114/R115):** every station action is still
  a server-validated intent; hiding/showing a button never authorizes, and a raced
  `NOT_*` / `PARTY_NOT_READY` / `INSUFFICIENT_STIPEND` still surfaces (P56 heritage).
- **P63 (no class roles, R115):** the Deploy roster is derived from bag contents;
  no code assigns a fixed class/role string to a Seeker.

## Wire Protocol Summary

New: `SELECT_CONTRACT { contractId }` (C→S). Snapshot additions: `board:
ContractIntel[]`, `stipend: number`. Gear additions: `price`, `description`.
New error codes: `UNKNOWN_CONTRACT`, `INSUFFICIENT_STIPEND`. Reused unchanged:
`ROOM_DEPLOYING`, `REQUISITION`, `DEPLOY`, the `NOT_AT_*` gates. No trait data is
added to any message (I3/I5).
