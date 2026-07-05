# Design — Collegium (Staging Site) v1

> Satisfies R92–R101. A fixed, walkable Collegium hall the party occupies during
> the lobby phases, built on the field-space movement stack (TD-035). Prep
> actions are gated to spatial stations exactly as field extraction is gated to
> the Extraction node. The central move is **generalizing the field tick into one
> movement tick** that runs across every walkable phase and collides against the
> phase's active grid — so the Collegium and the field share one authoritative
> integrator, one `MOVE`, one `POSITIONS`.

---

## Data Models

### Shared (`src/shared/src/collegium.ts`) — types and constants only (I4)

```ts
import type { SiteGrid } from './site.js';

export const STATION_RADIUS = 24;  // px from a station's tile center (1.5 tiles)

export const STATION_KINDS = ['CONTRACT_BOARD', 'QUARTERMASTER', 'DEPLOY_GATE'] as const;
export type StationKind = (typeof STATION_KINDS)[number];

export type Station = { kind: StationKind; x: number; y: number };  // tile coords
export type CollegiumLayout = {
  grid: SiteGrid;                       // reuses the field-space grid type
  stations: Station[];
  spawn: { x: number; y: number };      // tile-coord anchor; party fans out from here
};
```

Reuses `SiteGrid` (generic tile geometry) and the field-space px/collision
constants (`SEEKER_SPEED`, `SEEKER_FEET_*`). Station kinds are a runtime const
array (the codegen-able pattern). No `SiteNode`/`SiteNodeKind` — the Collegium
has *stations*, not field nodes; the two vocabularies stay separate.

### Wire (`src/shared/src/lobby.ts` + `lobbyMessages.ts`)

`LobbySnapshot` gains:

```ts
collegium: CollegiumLayout;            // the fixed hall (static; re-sent with the snapshot)
positions: Record<string, { x: number; y: number }>;  // present players' feet px
```

`LOBBY_ERROR_CODES` gains `NOT_AT_CONTRACT_BOARD`, `NOT_AT_QUARTERMASTER`,
`NOT_AT_DEPLOY_GATE`. No new message names: the station actions reuse
`ACCEPT_CONTRACT` / `REQUISITION` / `DEPLOY`; movement reuses `MOVE` /
`POSITIONS`; the Collegium reaches reconnecting clients through the existing
`LobbySnapshot` embedded in `STATE_RESYNC`. `pnpm gen:protocol` refreshes the
GDScript error-code enum.

### Server content (`src/server/src/collegium/collegium.ts`)

`COLLEGIUM: CollegiumLayout` — one hand-authored constant (like `GEAR_CATALOG`),
never seeded/generated. A modest hall: a central spawn atrium with three alcoves
holding the Contract Board, the Quartermaster, and the Deploy Gate, all on floor,
all reachable. Sent to clients over the wire (client stays a render copy, I1);
the *layout* lives server-side, only the *types* are shared.

### Server state (`src/server/src/rooms/types.ts`)

```ts
// RoomRecord: fieldTick is renamed to the phase-neutral moveTick.
moveTick: NodeJS.Timeout | null;   // was fieldTick; one integrator for the room's walkable life
// site stays as-is (null until DEPLOY). No per-room Collegium field — it is the
// global COLLEGIUM constant, referenced by activeGrid().
// ServerPlayerEntry.pos / moveIntent are unchanged (set on Collegium spawn now,
// re-set on field spawn at DEPLOY).
```

## Algorithms

### `activeGrid(room): SiteGrid | null` — `src/server/src/rooms/movementTick.ts`

- WAITING / DEPLOYING → `COLLEGIUM.grid`
- FIELD → `room.site?.grid ?? null`
- COMPLETE → `null`

The single source of "what am I walking on right now."

### Movement tick — `src/server/src/rooms/movementTick.ts` (was `fieldTick.ts`)

`startMovementTick` / `stopMovementTick` (renamed from `startFieldTick` /
`stopFieldTick`); `room.moveTick` (was `fieldTick`). Each tick: `grid =
activeGrid(room)`; if null, move nothing. Otherwise, for every **connected**
player with `pos`, run `stepPlayer(pos, intent, TICK_MS, grid)`; collect movers;
broadcast one `POSITIONS` delta with only movers (unchanged from field-space).
Lifecycle:
- **Start:** `RoomManager.createRoom` (the first player just spawned in the
  Collegium) — the tick lives for the room's whole walkable life.
- **Grid swap, not restart:** `handleAcceptContract` (WAITING→DEPLOYING) and
  `handleDeploy` (DEPLOYING→FIELD) change the phase / set `room.site`; the tick
  keeps running and `activeGrid` returns the new grid.
- **Stop:** `RoomManager.destroyRoom` (already the single choke point for
  extract-completion, last-player removal, and all-disconnected) clears
  `moveTick`.

> Evolution of field-space R87/R91: the tick used to start on DEPLOY and only in
> FIELD. It now starts at room creation and spans WAITING/DEPLOYING/FIELD.
> `handleDeploy` no longer calls a start function; extraction still stops via
> `destroyRoom`. Recorded in the DECISION_LOG.

### Spawn fan-out — shared helper `spawnFanOut(grid, anchorTile, count)`

Extracted from field-space `deploy.ts`'s `spawnPoints` (BFS fan-out from an
anchor over floor tiles, fixed neighbor order, feet at tile center). Reused by:
- `handleDeploy` — anchor = the site's `APPROACH` node (existing behavior).
- Collegium spawn — anchor = `COLLEGIUM.spawn`.

Lives in `src/server/src/site/movement.ts` (or a small `spawn.ts` beside it),
server-side and pure. Determinism (fixed order) gives R95's stable spawn order.

### Collegium spawn on entry

- `RoomManager.createRoom`: set the creator's `pos = spawnFanOut(COLLEGIUM.grid,
  COLLEGIUM.spawn, 1)[0]`, `moveIntent = {0,0}`, then `startMovementTick`.
- `handleJoinRoom`: set the joiner's `pos` to the fan-out tile at their index
  (`spawnFanOut(..., room.players.length)` → last entry), so present players get
  distinct tiles. `LOBBY_UPDATED` (with the now-position-bearing snapshot) tells
  existing players where the newcomer stands.

### Station gating — shared distance util `withinStation`

`withinRadius(pos, tileX, tileY, radiusPx): boolean` — feet px within a tile
center. Extracted from `handleExtract`'s inline `hypot` check and reused there
(refactor, no behavior change) and by the three station gates. A small
`stationCenterPx(kind)` reads `COLLEGIUM.stations`.

Handler insertions (each after the existing leader/phase/ready guards, before any
mutation, error to **sender only**, no broadcast):
- **`handleAcceptContract`**: leader within `STATION_RADIUS` of `CONTRACT_BOARD`
  else `NOT_AT_CONTRACT_BOARD`.
- **`handleRequisition`**: sender within radius of `QUARTERMASTER` else
  `NOT_AT_QUARTERMASTER`.
- **`handleDeploy`**: leader within radius of `DEPLOY_GATE` else
  `NOT_AT_DEPLOY_GATE`; and drop the `startFieldTick` call (tick already
  running).

### `MOVE` phase generalization — `handlers/move.ts`

Replace `assertPhase(room, 'FIELD', emit)` with a walkable-phase guard: legal in
WAITING/DEPLOYING/FIELD, rejected in COMPLETE (`WRONG_PHASE`) and outside a room
(`NOT_IN_ROOM`). Implemented as "the sender has a body": resolve the room, then
require `phase !== 'COMPLETE'` — equivalently `sender.pos !== null`. Validation
and the no-broadcast/store-intent-only contract are unchanged (R86).

### Snapshot — `toSnapshot(room)`

Append `collegium: COLLEGIUM` and `positions` (each present player's `pos`,
skipping `null`). Static layout re-sent with the snapshot is acceptable: lobby
snapshots are human-paced (join/ready/requisition/leader change), not 20Hz; live
movement rides the `POSITIONS` delta stream.

## Correctness Properties

- **P48 (soundness, R94):** the one fixed `COLLEGIUM` — border solid; exactly one
  of each station; stations + spawn on floor; all floor reachable from spawn
  (BFS, 4-neighbor).
- **P49 (one integrator, R96):** a single `moveTick` per room; it collides
  against `activeGrid`; grid swaps at phase changes without a stop/restart.
- **P50 (walkable authority, R97):** client input alone never moves a player in
  any phase — only the tick does; malformed/COMPLETE `MOVE` mutates nothing.
- **P51 (station gating, R99–R101):** each prep action outside its station radius
  errors to the sender and mutates nothing; inside, it proceeds unchanged.
- **P52 (no leaks, R96):** after `destroyRoom`, no further tick broadcasts, in
  any phase the room died in.
- **P47 (trait containment, standing):** the lobby snapshot (now carrying
  `collegium` + `positions`) still stringifies with no trait-axis literals.

## Wire Protocol Summary

| Message | Direction | Change |
|---|---|---|
| `MOVE` | client → server | now legal in WAITING/DEPLOYING/FIELD (was FIELD-only) |
| `POSITIONS` | server → room | unchanged; now also drives Collegium movement |
| `LOBBY_UPDATED` / `ROOM_CREATED` / `STATE_RESYNC` | server → client | `LobbySnapshot` gains `collegium` + `positions` |
| `ACCEPT_CONTRACT` | client → server | position-gated (`NOT_AT_CONTRACT_BOARD`) |
| `REQUISITION` | client → server | position-gated (`NOT_AT_QUARTERMASTER`) |
| `DEPLOY` | client → server | position-gated (`NOT_AT_DEPLOY_GATE`) |
