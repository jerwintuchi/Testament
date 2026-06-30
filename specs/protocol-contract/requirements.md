# Requirements — Protocol Contract & Shared Codegen

Phase 2 of the roadmap. Make the wire protocol one language-neutral source of
truth that the TypeScript server and the GDScript Godot client both consume, so
the two can never drift. Today the message-type strings are scattered literals in
both `src/server/src/index.ts` and `client/main.gd`. This spec replaces them with
constants drawn from one registry in `src/shared`, plus a build-time codegen that
emits a GDScript constants file the client reads. Commits no gameplay.

**R1**: As the wire protocol, every message-type name is declared once in a
canonical registry in `src/shared`, split into a client-to-server set and a
server-to-client set, with the TypeScript union types derived from those values.
- AC: `CLIENT_MESSAGES` contains exactly `create-room`, `join-room`, `rejoin`, `leave-room`, `start-run`, `move-player`, and nothing else.
- AC: `SERVER_MESSAGES` contains exactly `ROOM_UPDATE`, `RUN_STARTED`, `PLAYER_MOVED`, `STATE_RESYNC`, `PLAYER_CONNECTION_CHANGED`, `LOBBY_ERROR`, and nothing else.
- AC: the registry excludes the transport-internal lifecycle events `connection` and `disconnect` (and any test-only token such as `PING`); a test asserts none of those strings appear as registry values.
- AC: `ClientMessageType` and `ServerMessageType` are derived from the registry objects via `typeof`/keyof, not hand-written unions (a value added to the object widens the type with no second edit).

**R2**: As the protocol catalog, every message-type constant is associated with its
payload type so the catalog is complete and checkable.
- AC: a type-level name-to-payload map (or equivalent doc-comment traceability checked by a test) covers all twelve names; the payloads referenced are the existing `src/shared` interfaces (`JoinRoomRequest`, `MovePlayerRequest`, `RoomUpdateEvent`, `RunStartedEvent`, `PlayerMovedEvent`, `StateResyncEvent`, `PlayerConnectionChangedEvent`, `LobbyErrorEvent`), not duplicates.
- AC: the four payload-free messages (`create-room`, `rejoin`, `leave-room`, `start-run`) are mapped to `null` (no payload), and a test asserts that mapping.

**R3**: As `src/shared`, the codegen-able enums and shared scalars are authored as
runtime values (const objects and const string arrays) with the TypeScript types
derived from them, so a codegen that imports the module can introspect them and so
there is exactly one source per value.
- AC: `LOBBY_ERROR_CODES` is a `readonly` string array whose values are exactly `ROOM_NOT_FOUND`, `ROOM_FULL`, `ALREADY_STARTED`, `ALREADY_IN_ROOM`, `NOT_ENOUGH_PLAYERS`, `NOT_IN_ROOM`, `INVALID_REQUEST`, `CANNOT_REJOIN`; `LobbyErrorCode` is derived from it via indexed access.
- AC: `ROOM_STATUSES` is a `readonly` array `['lobby', 'in-progress', 'ended']`; `RoomStatus` is derived from it.
- AC: the existing `LobbyErrorEvent.code` union and the existing `RoomStatus` union are refactored to derive from these arrays; a test asserts the derived type accepts every array member and that the arrays are the single declaration site (no parallel hand-written union remains).
- AC: the shared scalars `CORRIDOR_HALF_WIDTH`, `DESIGN_VIEW_HEIGHT`, `MAX_PLAYERS`, `MIN_PLAYERS_TO_START`, `PLAYER_RADIUS` are exported from `src/shared` (they already exist) and are the values the codegen reads; a test enumerates the exact codegen scalar set.

**R4**: As the build, a tools-package codegen emits a deterministic, reproducible
GDScript constants file covering every message name, every shared enum value, and
every shared scalar, and that file is checked into the Godot project.
- AC: generating twice from the same `src/shared` input yields byte-identical output strings (no timestamps or other nondeterministic content; LF newlines; fixed key ordering equal to the insertion order of the source const objects).
- AC: the output contains every value in `CLIENT_MESSAGES`, `SERVER_MESSAGES`, `LOBBY_ERROR_CODES`, `ROOM_STATUSES`, and every scalar named in R3.
- AC: the checked-in `client/protocol/protocol.gd` is byte-identical to a fresh generation (reproducibility gate: a test regenerates in memory and compares to the committed file).
- AC: the output is well-formed GDScript shape: a generated-file header naming the source module and the regenerate command, a documented preload usage hint, no global `class_name` (so it resolves in a headless run and on a fresh checkout without an editor reimport; see DECISION_LOG TD-021), and each entry a well-formed `const NAME := <literal>` line.

**R5**: As the server, `src/server/src/index.ts` references the shared name constants
for every wire message, with no wire-message string literal remaining.
- AC: a test (or a grep-style assertion) confirms `index.ts` contains no bare wire-message literal from the R1 catalog; each `socket.on(...)`/`emit(...)`/`io.to(...).emit(...)` wire call uses `CLIENT_MESSAGES.*` or `SERVER_MESSAGES.*`.
- AC: the transport-internal `socket.on('disconnect', ...)` is not treated as a wire message (it stays as-is or behind a transport-level constant, never in the wire registry); a test confirms `disconnect` is absent from the wire registry.
- AC: existing server tests (`manager.test.ts`, the wsHub integration test) stay green and a `create-room` still produces a `ROOM_UPDATE`.

**R6**: As the client, `client/main.gd` references the generated `Protocol.*`
constants for every wire message it sends and matches, and consumes the generated
scalars instead of hand-duplicated ones, with the Phase-1 round-trip intact.
- AC: every `_send(...)` call and every `match type:` arm uses a `Protocol.*` constant, not a string literal.
- AC: the hand-duplicated `CORRIDOR_HALF_WIDTH` and `DESIGN_VIEW_HEIGHT` consts at the top of `main.gd` are removed and replaced by `Protocol.CORRIDOR_HALF_WIDTH` / `Protocol.DESIGN_VIEW_HEIGHT`.
- AC: the Phase-1 round-trip still works end to end (connect, create-room, ROOM_UPDATE, start-run, RUN_STARTED, move-player, PLAYER_MOVED); verified manually against the running server (no automated GDScript test harness exists yet, so this AC is a documented manual gate).

**R7** (correctness): The protocol contract and codegen stay logic-free and respect
the trust boundary (I4): `src/shared` exports only types and constants, and the
`tools/` codegen imports no server game modules.
- AC: `src/shared/src/messages.ts` exports only `const` objects, `const` arrays, and derived types (no functions that compute game state, no side effects at import time); a test imports the module and asserts the exports are data.
- AC: `tools/**` imports nothing from `src/server/src/room`, `dungeon`, or `combat`; it imports only `@testament/shared` (as TS source) and standard library / file-system helpers.
