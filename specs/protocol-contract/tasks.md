# Tasks — Protocol Contract & Shared Codegen

Ordered: shared registry first, then the enum/scalar refactor, then the codegen,
then the server refactor, then the client refactor, then wiring. Every task cites
its R#/P# and names a test or a documented manual gate.

- [x] T1 [R1, R2, P1, P2] — Author the registry `CLIENT_MESSAGES`, `SERVER_MESSAGES`, the derived `ClientMessageType`/`ServerMessageType`, and the `ClientMessagePayloads`/`ServerMessagePayloads` name-to-payload maps (payload-free names -> `null`) in `src/shared/src/messages.ts`.
  Test: `src/shared/src/messages.test.ts` — the two objects contain exactly the twelve-name catalog and nothing else; `connection`/`disconnect`/`PING` are absent from every registry value; all values are unique; the payload maps cover all twelve names with the four payload-free names mapped to `null`.

- [x] T2 [R3, P2] — Add `LOBBY_ERROR_CODES` (const array) and `ROOM_STATUSES` (const array) with derived `LobbyErrorCode`/`RoomStatus` types, and the `PROTOCOL_SCALARS` set referencing the existing scalar exports, in `src/shared/src/messages.ts`.
  Test: `src/shared/src/messages.test.ts` — `LOBBY_ERROR_CODES` holds exactly the eight codes and `ROOM_STATUSES` exactly the three statuses; `PROTOCOL_SCALARS` enumerates exactly `CORRIDOR_HALF_WIDTH`, `DESIGN_VIEW_HEIGHT`, `MAX_PLAYERS`, `MIN_PLAYERS_TO_START`, `PLAYER_RADIUS`.

- [x] T3 [R3, P2] — Refactor `src/shared/src/lobby.ts` to derive `RoomStatus` and `LobbyErrorEvent.code` from the `messages.ts` arrays (delete the inline unions), and export `messages.js` from `src/shared/src/index.ts`.
  Test: `src/shared/src/messages.test.ts` — `RoomStatus` and `LobbyErrorCode` accept every array member; no parallel hand-written union remains (a type-level round-trip assertion); existing shared tests stay green.

- [x] T4 [R7, P4] — Confirm `messages.ts` exports only data and types (no functions, no import-time side effects).
  Test: `src/shared/src/messages.test.ts` — importing the module yields only objects/arrays/typeof-derived values; a guard asserts every runtime export is a plain object, array, or primitive (no `function`).

- [x] T5 [R4, P3] — Scaffold the `tools/` workspace package (`tools/package.json` as `@testament/protocol-codegen`, importing `@testament/shared` as TS source, run via `tsx`); add `tools` to `pnpm-workspace.yaml` and a `gen:protocol` script to the root `package.json`.
  Test: covered by the generate tests (T6); `pnpm -r test` resolves the new package.

- [x] T6 [R4, R7, P3, P4] — Implement the pure `generateProtocolGd(input) -> string` and the side-effecting `writeProtocolGd()` in `tools/src/generate.ts` (fixed header naming source module + `pnpm gen:protocol`, `class_name Protocol`, insertion-ordered `const` lines, LF newlines, trailing newline).
  Test: `tools/src/generate.test.ts` — generating twice yields byte-identical strings; output contains every `CLIENT_MESSAGES`/`SERVER_MESSAGES` value, every `LOBBY_ERROR_CODES`/`ROOM_STATUSES` value, and every `PROTOCOL_SCALARS` scalar; the GDScript shape holds (header present, preload hint, no global `class_name`, well-formed `const NAME := <literal>` lines); `tools/**` imports nothing from `server/room|dungeon|combat`.

- [x] T7 [R4, P3] — Generate and commit `client/protocol/protocol.gd` via `pnpm gen:protocol`.
  Test: `tools/src/generate.test.ts` — the reproducibility gate: a fresh in-memory generation is byte-identical to the committed `client/protocol/protocol.gd`.

- [x] T8 [R5] — Refactor `src/server/src/index.ts` to use `CLIENT_MESSAGES.*` for every `socket.on(...)` wire handler and `SERVER_MESSAGES.*` for every `emit(...)`/`io.to(...).emit(...)`; leave `socket.on('disconnect', ...)` as a transport lifecycle handler (not a wire-registry value).
  Test: existing `manager.test.ts` and the wsHub integration test stay green; a `create-room` still yields a `ROOM_UPDATE`; an assertion confirms no bare wire-message literal from the R1 catalog remains in `index.ts` and that `disconnect` is absent from the wire registry.

- [x] T9 [R6] — Refactor `client/main.gd`: add `const Protocol = preload("res://protocol/protocol.gd")`; replace every `_send(...)` literal and every `match type:` arm with `Protocol.*`; remove the hand-duplicated `CORRIDOR_HALF_WIDTH`/`DESIGN_VIEW_HEIGHT` consts and reference `Protocol.CORRIDOR_HALF_WIDTH`/`Protocol.DESIGN_VIEW_HEIGHT`.
  Test: manual gate (no GDScript test harness yet) — verified via the Godot MCP against the running server (Godot 4.7): the project compiles and runs with zero parser/runtime errors, and an instrumented run observed the Phase-1 round-trip end to end (connect, create-room, ROOM_UPDATE, start-run, `RUN_STARTED rooms=12 seekers=1`). The change is value-preserving (each `Protocol.*` equals the prior literal), so move-player/PLAYER_MOVED behaviour is unchanged.

- [ ] T10 [R4, R5, R6] — Verify the full exit gate: `pnpm -r test` green, `pnpm gen:protocol` clean (no diff), server and client both reference the one source.
  Test: `pnpm -r test` (all suites green, including the new `messages.test.ts` and `generate.test.ts`); regenerating produces no git diff.

---

## Reconciliation addendum (2026-07-03, TD-031)

T1–T10 above were authored on `feat/protocol-contract` against the Phase 1 spike
protocol (create-room/start-run/move-player). By the time the branch merged, the
Testament protocol (Phases 3–4, T1–T83) had replaced the spike entirely, so the
machinery was kept and the content re-targeted. Global task numbering continues
from the godot-client-catchup spec.

- [x] T84 — Rewrite the registry for the Testament protocol: ten client intents,
  ten server events, payload maps referencing lobbyMessages/fieldMessages types;
  `LOBBY_ERROR_CODES` and `ROOM_PHASES` become runtime arrays declared beside
  their derived types (in lobbyMessages.ts / lobby.ts, avoiding import cycles);
  `PROTOCOL_SCALARS` = MAX_ROOM_PLAYERS, ROOM_CODE_LENGTH, BAG_SLOTS.
  Test: `src/shared/src/messages.test.ts` — exact name sets, key==value,
  uniqueness, lifecycle events absent, payload-map exhaustiveness (type-level),
  registry purity.

- [x] T85 — Extend the codegen to the full contract: error codes, phases,
  CHANNELS, STIMULI, and GEAR_CATALOG (as a GDScript array of dictionaries),
  replacing the hand-mirrored `client/catalog.gd` data (TD-028's noted drift
  risk); regenerate `client/protocol/protocol.gd`.
  Test: `tools/src/generate.test.ts` — determinism, GDScript shape incl. GEAR
  entries, every name/item/scalar present, no trait vocabulary leaks,
  byte-equality reproducibility gate against the committed file.

- [x] T86 — Port the server to the registry: `messageRouter` case arms use
  `CLIENT_MESSAGES.*`; every handler emit/broadcast uses `SERVER_MESSAGES.*`.
  Test: `src/server/src/rooms/wireLiterals.test.ts` — position-aware guard
  (emit/emitTo/broadcast/case) over every non-test server source; plus the full
  existing suite unchanged (values are identical strings).

- [x] T87 — Port the client: `main.gd` sends and matches via `Protocol.*`
  (messages, phases, error codes); `catalog.gd` becomes display helpers over
  `Protocol.GEAR`/`BAG_SLOTS`/`STIMULI`/`CHANNELS` with no hand-copied data.
  Test: headless Godot 4.7 `--check-only` on all four scripts + a headless
  project run against the live server, zero errors (no GDScript harness; the
  wire behaviour is value-preserving).

- [x] T10 (closed by T84–T87) — `pnpm -r test` green across shared + tools +
  server (372 tests); `pnpm gen:protocol` produces no diff; server and client
  reference the one source.
