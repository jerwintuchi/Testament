# Design — Field Space v1

> Satisfies R81–R91. The tile-grid substrate for Phase 5 combat: seeded site
> generation with the TD-018 node vocabulary, server-integrated 20Hz movement,
> and position-gated extraction. Geometry is canonical-grid (TD-033): tiles are
> 16×16 px, positions are px floats, collision is a feet AABB against solid
> tiles — matching the Seeker's feet-anchor render convention so the server's
> collider and the client's sprite agree about where a Seeker "is".

---

## Data Models

### Shared (`src/shared/src/site.ts`) — types and constants only (I4)

```ts
export const TILE_SIZE = 16;              // px per tile (render + collision contract)
export const FIELD_TICK_HZ = 20;          // authoritative movement tick
export const SEEKER_SPEED = 80;           // px/s ≈ 5 tiles/s — deliberate, not twitchy
export const SEEKER_FEET_HALF_WIDTH = 5;  // feet AABB is 10×6 px centered on the feet point
export const SEEKER_FEET_HEIGHT = 6;
export const EXTRACTION_RADIUS = 32;      // px from EXTRACTION tile center (2 tiles)

export const SITE_NODE_KINDS = ['APPROACH', 'SIGN_SOURCE', 'LAIR', 'EXTRACTION'] as const;
export type SiteNodeKind = (typeof SITE_NODE_KINDS)[number];

export type SiteGrid = { width: number; height: number; rows: string[] };
export type SiteNode = { kind: SiteNodeKind; x: number; y: number };  // tile coords
export type SiteLayout = { grid: SiteGrid; nodes: SiteNode[] };
```

`rows` encodes tiles as strings (`#` solid, `.` floor): compact JSON, zero
parsing ambiguity for GDScript (`row[x]` char compare). Node kinds are authored
as a runtime const array (the codegen-able pattern from `messages.ts`).

### Wire messages (`src/shared/src/fieldMessages.ts`)

```ts
export type MovePayload = { dx: number; dy: number };  // direction, each in [-1, 1]
export type PositionsPayload = { positions: Record<string, { x: number; y: number }> };
```

`FieldStartedPayload` and `FieldSnapshot` each gain:

```ts
site: SiteLayout;
positions: Record<string, { x: number; y: number }>;  // playerId → feet px
```

Registry (`messages.ts`): `MOVE` joins `CLIENT_MESSAGES`, `POSITIONS` joins
`SERVER_MESSAGES`, both with payload mappings; `pnpm gen:protocol` refreshes
the GDScript side.

### Server state (`src/server/src/rooms/types.ts`)

```ts
// RoomRecord gains (server-only, never serialized wholesale):
site: SiteLayout | null;        // null until DEPLOY
fieldTick: NodeJS.Timeout | null;

// ServerPlayerEntry gains:
pos: { x: number; y: number } | null;         // feet px; null outside FIELD
moveIntent: { dx: number; dy: number };       // last validated MOVE; {0,0} default
```

## Algorithms

### `generateSite(rng: Rng): SiteLayout` — pure, `src/server/src/site/generateSite.ts`

Fixed 48×32 tile grid (768×512 px), all solid. Carve 6–8 rectangular rooms
(5–9 tiles a side, ≥1 tile from the border) by rejection placement; connect
each room to the previous with an L-shaped 2-tile-wide corridor (deterministic
order, elbow direction from `rng`). Nodes: `APPROACH` at the first room's
center; `LAIR` at the room whose center is farthest (Manhattan) from
`APPROACH`; `EXTRACTION` at the farthest room that is not the LAIR room;
`SIGN_SOURCE` ×2 in distinct remaining rooms (`rng.pick` of floor tiles).
Sequential-corridor connection makes full floor connectivity structural; the
property test (P42) verifies it anyway.

Seed namespacing in the deploy handler:
`createRng(hashSeed(contract.expeditionSeed + ':site'))` — a fresh stream, so
the contract/trait streams and their pinned determinism tests are untouched.

### `stepPlayer(pos, dx, dy, dtMs, grid)` — pure, `src/server/src/site/movement.ts`

1. Normalize `(dx, dy)` if magnitude > 1 (kills the √2 diagonal bonus).
2. Displacement = direction × `SEEKER_SPEED` × `dtMs / 1000`.
3. Axis-separated resolve: apply x, test the feet AABB
   (`pos ± SEEKER_FEET_HALF_WIDTH` × `SEEKER_FEET_HEIGHT` up from the feet
   line) against solid tiles, revert x on overlap; then the same for y.
   Blocked on one axis ⇒ slide along the other.

### Field tick — `src/server/src/rooms/fieldTick.ts`

`startFieldTick(room, broadcast)` sets a `setInterval` at `1000 / FIELD_TICK_HZ`
ms; `stopFieldTick(room)` clears it. Each tick: for every **connected** player
with `pos`, run `stepPlayer` with their `moveIntent`; collect players whose
position changed; if any, broadcast one `POSITIONS` with only those entries
(I6). Start: `handleDeploy` after entering FIELD. Stop: extract-completion,
room destruction, last-player removal, and disconnect-cleanup when the room
empties. Disconnect zeroes that player's `moveIntent`.

### Handler changes

- **`MOVE`** (new, `handlers/move.ts`): validate `dx`/`dy` are finite numbers
  in [-1, 1] → `INVALID_PAYLOAD` else; `assertPhase(room, 'FIELD')`; then
  `sender.moveIntent = { dx, dy }`. No broadcast, no position math here.
- **`handleDeploy`**: generate the site, spawn each player on distinct floor
  tiles of the APPROACH room (feet at tile center), set `pos`/`moveIntent`,
  include `site` + `positions` in every per-player `FIELD_STARTED`, start the
  tick.
- **`handleExtract`**: before today's logic, require the sender's `pos` within
  `EXTRACTION_RADIUS` px (Euclidean) of the EXTRACTION node's tile center →
  else `NOT_AT_EXTRACTION` to sender only. On success, stop the tick.
- **`buildFieldSnapshot`**: append `site` and all current `positions`.

## Correctness Properties

- **P41 (determinism, R83/R85):** same expedition seed → byte-identical
  `SiteLayout` and spawn set.
- **P42 (soundness, R84):** ∀ seeds: border solid; node multiplicities
  (1/1/1/≥2); nodes on floor; all floor reachable from APPROACH (BFS,
  4-neighbor).
- **P43 (containment, R88):** ∀ positions/directions/dt: the post-step feet
  AABB overlaps no solid tile.
- **P44 (authority, R86/R87):** client input alone never changes a position —
  only the tick does, at ≤ `SEEKER_SPEED`; malformed `MOVE` mutates nothing.
- **P45 (delta discipline, R87):** a tick without movement emits nothing; a
  `POSITIONS` payload names only moved players.
- **P46 (no leaks, R91):** after stop conditions, no further tick broadcasts.
- **P47 (trait containment, standing):** none of the new payloads carry trait
  values — `JSON.stringify` of `FIELD_STARTED`/`STATE_RESYNC`/`POSITIONS`
  contains no axis literals (extends the existing containment tests).

## Wire Protocol Summary

| Message | Direction | Payload |
|---|---|---|
| `MOVE` | client → server | `{ dx, dy }` — intent, [-1,1] each |
| `POSITIONS` | server → room | `{ positions: { [playerId]: { x, y } } }` — moved players only |
| `FIELD_STARTED` | server → player | + `site: SiteLayout`, `positions` |
| `STATE_RESYNC` | server → player | `FieldSnapshot` + `site`, `positions` |
| `EXTRACT` | client → server | unchanged shape; now position-gated (`NOT_AT_EXTRACTION`) |
