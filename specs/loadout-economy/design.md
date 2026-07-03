# Design — Loadout & Bag Economy (v1)

> Satisfies R64–R68. P# numbering continues from P29 (distributed-perception spec).
>
> Spine verb: **Hypothesize → Test** — packing the bag is the bet placed on the
> contract's intel (Pillar 1), and distributing the bags is distributing
> perception (Pillar 4, TD-007). The bag is entirely the reading-and-tool layer:
> melee costs no slot (TD-011).

---

## Data models

### Shared (`@testament/shared` — types and constants only, I4)

```ts
// src/shared/src/gear.ts (new)
export type ItemId = string;

export type GearItem = { id: ItemId; name: string } & (
  | { kind: 'PERCEPTION'; channel: Channel }    // lets its carrier read one sign channel
  | { kind: 'PROBE';      stimulus: Stimulus }  // lets its carrier present one stimulus
);

export const BAG_SLOTS = 4;

export const GEAR_CATALOG: ReadonlyArray<GearItem> = [
  // Perception gear — one per channel
  { id: 'ashen-lens',          name: "Ashen Lens",          kind: 'PERCEPTION', channel: 'RESIDUE' },
  { id: 'chirurgeons-glass',   name: "Chirurgeon's Glass",  kind: 'PERCEPTION', channel: 'STRESS_MARK' },
  { id: 'witness-prism',       name: "Witness Prism",       kind: 'PERCEPTION', channel: 'REACTION' },
  { id: 'trackers-fetish',     name: "Tracker's Fetish",    kind: 'PERCEPTION', channel: 'SPOOR' },
  { id: 'cantors-ear',         name: "Cantor's Ear",        kind: 'PERCEPTION', channel: 'LITURGY' },
  { id: 'augurs-bead',         name: "Augur's Bead",        kind: 'PERCEPTION', channel: 'OMEN' },
  // Probe kits — one per stimulus (reusable in v1)
  { id: 'censer-of-embers',    name: "Censer of Embers",    kind: 'PROBE', stimulus: 'FLAME' },
  { id: 'phial-of-hoarfrost',  name: "Phial of Hoarfrost",  kind: 'PROBE', stimulus: 'COLD' },
  { id: 'consecrated-salt',    name: "Consecrated Salt",    kind: 'PROBE', stimulus: 'SALT' },
  { id: 'lantern-of-the-creed', name: "Lantern of the Creed", kind: 'PROBE', stimulus: 'LIGHT' },
];
```

The catalog lives in shared (unlike `SIGN_LEXICON`, which is server-only): the
lexicon maps *hidden trait values* to tokens and must never reach a client,
while the catalog is public requisition data the Godot client needs to render
the shop. It carries channels and stimuli — wire-safe vocabulary — never axis
values.

```ts
// src/shared/src/lobbyMessages.ts (additions)
export type RequisitionPayload = { itemIds: ItemId[] };  // client → server
// LobbyErrorCode gains: 'UNKNOWN_ITEM' | 'BAG_OVERFLOW' | 'MISSING_GEAR'

// src/shared/src/lobby.ts (change)
export type LobbyPlayer = { ...; bag: ItemId[] };  // bags are party-visible
```

No new server → client message: a successful requisition broadcasts the existing
`LOBBY_UPDATED`, whose snapshot now carries every player's bag.

### Server-only

```ts
// src/server/src/rooms/types.ts (ServerPlayerEntry addition)
bag: ItemId[];   // empty until REQUISITION; keyed to playerId, survives reconnect
```

## Sizing rationale

`BAG_SLOTS = 4` against a 10-item catalog: a full 4-party has 16 slots — roomy,
coordination is about coverage. A duo has 8 slots against 6 channels + the probe
kits their theory needs — tight, real tradeoffs. Solo has 4 slots purely for
probe kits (reading is free solo); testing all four stimuli costs the whole bag.
Open tuning; the constant is one number.

## Algorithms

### `perceivedChannelsFor(bag: ItemId[], isSolo: boolean, tier: Tier): Channel[]`
Pure, in `src/server/src/rooms/perception.ts`.

1. Solo → `channelsForTier(tier)` — all relevant channels, regardless of bag
   (TD-008: solo is never information-starved; its cost is tempo and slots).
2. Party → the `channel` of every PERCEPTION item in the bag, canonical order.
   Gear is not filtered by tier relevance: packing a Cantor's Ear for an
   Apprentice hunt reads nothing — a wasted slot is the player's own bad bet.

Spec 5's `assignPerception` and `MIN_CHANNELS_PER_PLAYER` are **deleted** (the
interim source is fulfilled); `channelsForTier` and `filterSigns` remain.

### `hasProbeKit(bag: ItemId[], stimulus: Stimulus): boolean`
Pure, in `src/server/src/rooms/perception.ts` (or a small `gearLookup` helper):
true iff the bag holds the PROBE item whose `stimulus` matches.

### `handleRequisition(socketId, payload, roomManager, emit, broadcast)`
`src/server/src/rooms/handlers/requisition.ts`. Standard intent skeleton:

1. **Validate shape**: `itemIds` is an array of strings → else `INVALID_PAYLOAD`.
2. **Validate content**: every id in `GEAR_CATALOG` → else `UNKNOWN_ITEM`;
   no duplicate ids → else `INVALID_PAYLOAD`; `length <= BAG_SLOTS` → else
   `BAG_OVERFLOW`.
3. **Authorize**: `assertPhase(room, 'DEPLOYING', emit)`. Any player, own bag only
   (the sender is resolved by socket — there is no way to name another player).
4. **Mutate**: `sender.bag = itemIds` (replace-not-merge: the payload is the
   whole bag, so requisition is idempotent and un-packing is legal).
5. **Broadcast** `LOBBY_UPDATED` with `toSnapshot(room)` (bags included).

### `handleDeploy` (changes)
Replace the seeded assignment block:

```ts
const isSolo = room.players.length === 1;
for (const player of room.players) {
  player.perceivedChannels = perceivedChannelsFor(player.bag, isSolo, contract.tier);
  ...emit FIELD_STARTED as before (filtering machinery unchanged)
}
```

### `handleProbe` (changes)
After phase/authorization checks, before mutation:

```ts
if (!hasProbeKit(sender.bag, stimulus)) {
  emit('LOBBY_ERROR', { code: 'MISSING_GEAR', message: ... });
  return;  // no exposure, no delivery
}
```

### `toPublicPlayer` (change)
Adds `bag: p.bag` — bags are party-visible coordination state, not secrets.
`STATE_RESYNC` therefore carries bags for free (R68).

## Wire protocol

| Direction | Type | Payload |
|-----------|------|---------|
| C → S | `REQUISITION` | `{ "itemIds": ["ashen-lens", "censer-of-embers"] }` |
| S → room | `LOBBY_UPDATED` | existing snapshot; `players[*].bag` now present |
| S → sender | `LOBBY_ERROR` | codes `INVALID_PAYLOAD`, `UNKNOWN_ITEM`, `BAG_OVERFLOW`, `WRONG_PHASE`, `NOT_IN_ROOM`; `MISSING_GEAR` on PROBE |

Trait rolls still never cross the wire; the catalog carries no trait data.

## Correctness properties

- **P30 — Catalog completeness**: exactly one PERCEPTION item per Channel and one
  PROBE item per Stimulus; all ids unique. [R64]
- **P31 — Bag boundedness**: no server state ever holds a bag with more than
  `BAG_SLOTS` items, duplicates, or unknown ids; a rejected requisition changes
  nothing. [R65]
- **P32 — Perception follows gear**: in a party, a player's `perceivedChannels`
  equals exactly the channels of their carried perception gear; solo equals
  `channelsForTier(tier)`. [R66]
- **P33 — No kit, no probe**: a probe without the matching kit mutates nothing
  and delivers nothing; with the kit it behaves exactly as spec 5 defined
  (per-player filtered delivery, exposure +1). [R67]
- **P34 — Bag stability**: bags are identical before disconnect and after
  reconnect within one room lifetime, and visible in every snapshot. [R68]
