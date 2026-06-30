# Design — Protocol Contract & Shared Codegen

Satisfies R1–R7. One language-neutral registry of wire-message names, enums, and
scalars in `src/shared`, plus a `tools/` codegen that emits a GDScript constants
file the Godot client consumes. No gameplay; pure plumbing and a build step.

## The central design decision: runtime values, derived types

TypeScript union types are erased at runtime, so a codegen that imports the shared
module cannot introspect `type X = 'a' | 'b'`. Therefore the registry and every
codegen-able enum are authored as **runtime values** (const objects for message
names, const string arrays for enums), with the TS types **derived** from those
values. Const arrays and objects are data, not logic, so `src/shared` stays
types-and-constants-only (invariant I4). There is then exactly one source per
value: the runtime value, with the type following it.

## Data Models

```ts
// src/shared/src/messages.ts — the canonical wire registry (new file).

// Client -> Server message names. Keys are the GDScript/codegen identifiers;
// values are the on-the-wire strings.
export const CLIENT_MESSAGES = {
  CREATE_ROOM: 'create-room',
  JOIN_ROOM:   'join-room',
  REJOIN:      'rejoin',
  LEAVE_ROOM:  'leave-room',
  START_RUN:   'start-run',
  MOVE_PLAYER: 'move-player',
} as const;
export type ClientMessageType = (typeof CLIENT_MESSAGES)[keyof typeof CLIENT_MESSAGES];

// Server -> Client message names.
export const SERVER_MESSAGES = {
  ROOM_UPDATE:               'ROOM_UPDATE',
  RUN_STARTED:               'RUN_STARTED',
  PLAYER_MOVED:              'PLAYER_MOVED',
  STATE_RESYNC:              'STATE_RESYNC',
  PLAYER_CONNECTION_CHANGED: 'PLAYER_CONNECTION_CHANGED',
  LOBBY_ERROR:               'LOBBY_ERROR',
} as const;
export type ServerMessageType = (typeof SERVER_MESSAGES)[keyof typeof SERVER_MESSAGES];

// R2: name -> payload association. The payload-free messages map to null. This is a
// type-level map; it duplicates no payload shapes (it references the existing ones).
import type {
  MovePlayerRequest, RunStartedEvent, PlayerMovedEvent,
  PlayerConnectionChangedEvent, StateResyncEvent,
} from './events.js';
import type { JoinRoomRequest, RoomUpdateEvent, LobbyErrorEvent } from './lobby.js';

export type ClientMessagePayloads = {
  'create-room': null;
  'join-room':   JoinRoomRequest;
  'rejoin':      null;
  'leave-room':  null;
  'start-run':   null;
  'move-player': MovePlayerRequest;
};
export type ServerMessagePayloads = {
  'ROOM_UPDATE':               RoomUpdateEvent;
  'RUN_STARTED':               RunStartedEvent;
  'PLAYER_MOVED':              PlayerMovedEvent;
  'STATE_RESYNC':              StateResyncEvent;
  'PLAYER_CONNECTION_CHANGED': PlayerConnectionChangedEvent;
  'LOBBY_ERROR':               LobbyErrorEvent;
};
```

```ts
// Shared enums authored as runtime arrays, types derived (R3). LOBBY_ERROR_CODES
// moves to messages.ts; lobby.ts re-derives LobbyErrorEvent.code and RoomStatus.
export const LOBBY_ERROR_CODES = [
  'ROOM_NOT_FOUND', 'ROOM_FULL', 'ALREADY_STARTED', 'ALREADY_IN_ROOM',
  'NOT_ENOUGH_PLAYERS', 'NOT_IN_ROOM', 'INVALID_REQUEST', 'CANNOT_REJOIN',
] as const;
export type LobbyErrorCode = (typeof LOBBY_ERROR_CODES)[number];

export const ROOM_STATUSES = ['lobby', 'in-progress', 'ended'] as const;
export type RoomStatus = (typeof ROOM_STATUSES)[number];
```

```ts
// The bounded scalar set the codegen reads (R3, R4). These constants already exist
// in dungeon.ts / lobby.ts / player.ts; the codegen imports them, it does not
// redeclare them. PROTOCOL_SCALARS names exactly which ones cross to GDScript.
export const PROTOCOL_SCALARS = {
  CORRIDOR_HALF_WIDTH,   // dungeon.ts
  DESIGN_VIEW_HEIGHT,    // dungeon.ts
  MAX_PLAYERS,           // lobby.ts
  MIN_PLAYERS_TO_START,  // lobby.ts
  PLAYER_RADIUS,         // player.ts
} as const;
```

### Refactor of existing declarations (single source)

- `lobby.ts`: delete the inline `RoomStatus` union and the inline `LobbyErrorEvent.code`
  union; import `RoomStatus` and `LobbyErrorCode` from `messages.ts` and use them.
- `src/shared/src/index.ts`: add `export * from './messages.js';`.
- No payload shape is duplicated: `ClientMessagePayloads` / `ServerMessagePayloads`
  reference the existing interfaces by `import type`.

## Algorithms

### Codegen (`tools/`)

`generateProtocolGd(input) -> string`
- Input: the runtime values imported from `@testament/shared`
  (`CLIENT_MESSAGES`, `SERVER_MESSAGES`, `LOBBY_ERROR_CODES`, `ROOM_STATUSES`,
  `PROTOCOL_SCALARS`).
- Output: the full GDScript file text, deterministic and pure (same input -> same
  string; no I/O, no clock, no randomness).
- Steps:
  1. Emit a fixed header: a comment block naming the source module
     (`src/shared/src/messages.ts`), the regenerate command (`pnpm gen:protocol`), and
     a preload usage hint. No global `class_name` is emitted: the client consumes the
     file with `const Protocol = preload("res://protocol/protocol.gd")`, which resolves
     at compile time from the res:// path. A `class_name` would not be registered in a
     headless run or on a fresh checkout until the editor reimports (see DECISION_LOG
     TD-021).
  2. Emit string consts for `CLIENT_MESSAGES` then `SERVER_MESSAGES`, in the object's
     insertion order, as `const KEY := "value"`.
  3. Emit string consts for each `LOBBY_ERROR_CODES` member (key derived from the
     value, e.g. `ROOM_NOT_FOUND`) and each `ROOM_STATUSES` member.
  4. Emit numeric consts for each `PROTOCOL_SCALARS` entry as `const KEY := <number>`.
  5. Join lines with `\n` (LF) and end with a trailing newline.
- Ordering is fixed (insertion order of the source objects/arrays), so the output is
  byte-stable across runs.

`writeProtocolGd()` (the CLI entry, run via `tsx`)
- Calls `generateProtocolGd(...)`, writes the string to `client/protocol/protocol.gd`
  with LF newlines. This is the only side-effecting function; the generator itself
  is pure so it can be unit-tested without touching the filesystem.

### Reproducibility gate

The test imports the live `@testament/shared` values, calls `generateProtocolGd`,
and compares the result byte-for-byte to the committed `client/protocol/protocol.gd`.
A drift (someone edited the registry without regenerating) fails the test.

## Correctness Properties

- **P1** (registry completeness): `CLIENT_MESSAGES` ∪ `SERVER_MESSAGES` equals the
  twelve-name catalog exactly, and excludes `connection`/`disconnect`/`PING` (R1).
- **P2** (derived-type fidelity): `LobbyErrorCode`, `RoomStatus`, `ClientMessageType`,
  `ServerMessageType` each accept exactly their source array/object members and no
  others; the union is never hand-maintained in parallel (R1, R3).
- **P3** (determinism / reproducibility): `generateProtocolGd` is pure and total;
  two runs on the same input yield byte-identical text, and the committed file
  matches a fresh generation (R4).
- **P4** (purity / trust boundary): `src/shared/src/messages.ts` exports only data
  and types (no functions computing game state, no import-time side effects); `tools/`
  imports nothing from `server/room|dungeon|combat` (R7, invariant I4).

## Wire-Protocol Messages

No new wire messages and no payload changes. This spec only relocates the message-
type *names* into a shared registry and codegens them to GDScript. The catalog is
unchanged from the raw-ws-transport spec:
- Client -> Server: `create-room`, `join-room {code}`, `rejoin {code}`, `leave-room`,
  `start-run`, `move-player {dx,dy}`.
- Server -> Client: `ROOM_UPDATE {room}`, `RUN_STARTED {dungeon, playerPositions}`,
  `PLAYER_MOVED {playerId,x,y}`, `STATE_RESYNC {...}`,
  `PLAYER_CONNECTION_CHANGED {playerId,connected}`, `LOBBY_ERROR {code,message}`.
- Not wire messages (transport lifecycle, excluded from the registry): `connection`,
  `disconnect`.

## New / Changed Files

- `src/shared/src/messages.ts` (new): the registry, enums, scalar set, derived types.
- `src/shared/src/messages.test.ts` (new): R1/R2/R3 assertions.
- `src/shared/src/lobby.ts` (changed): re-derive `RoomStatus` and `LobbyErrorEvent.code`.
- `src/shared/src/index.ts` (changed): export `messages.js`.
- `tools/package.json` (new): `@testament/protocol-codegen` workspace package.
- `tools/src/generate.ts` (new): `generateProtocolGd` + `writeProtocolGd`.
- `tools/src/generate.test.ts` (new): R4 determinism, completeness, reproducibility, shape.
- `client/protocol/protocol.gd` (new, generated, checked in): the GDScript constants (preload-consumed, no `class_name`).
- `src/server/src/index.ts` (changed): consume `CLIENT_MESSAGES`/`SERVER_MESSAGES`.
- `client/main.gd` (changed): `const Protocol = preload(...)`, then consume `Protocol.*`.
- `pnpm-workspace.yaml` (changed): add `tools`.
- root `package.json` (changed): add `gen:protocol` script.

## Satisfies Requirements
R1 (registry), R2 (name-to-payload map), R3 (runtime-value enums/scalars, single
source), R4 (deterministic reproducible codegen, checked in), R5 (server refactor),
R6 (client refactor, round-trip intact), R7 (logic-free, trust boundary).
