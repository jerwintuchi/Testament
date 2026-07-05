# Tasks — Collegium (Staging Site) v1

> T# numbering continues from T103 (field-space). Every task names its test
> before implementation (spec workflow). Order is dependency order. Reuses the
> field-space movement stack; several tasks *evolve* just-committed field-space
> code (tick, `MOVE` guard, deploy) — those edits update the affected
> field-space tests in the same task.

- [x] T104 [R92] — Shared Collegium types + constants in
      `src/shared/src/collegium.ts` (`StationKind`/`STATION_KINDS`, `Station`,
      `CollegiumLayout`, `STATION_RADIUS`), re-exported from the shared index.
      Test: `src/shared/src/collegium.test.ts` — `STATION_RADIUS` exported;
      `STATION_KINDS` runtime array matches the type; `CollegiumLayout` reuses
      `SiteGrid`; no server-only imports (compile-time containment, T95 pattern).

- [x] T105 [R93] — Add `NOT_AT_CONTRACT_BOARD`, `NOT_AT_QUARTERMASTER`,
      `NOT_AT_DEPLOY_GATE` to `LOBBY_ERROR_CODES`; run `pnpm gen:protocol`.
      Test: extend `src/shared/src/lobbyMessages.test.ts` (or `messages.test.ts`)
      — the three codes present in the union; `tools` sync test green against the
      regenerated GDScript.

- [x] T106 [R94 / P48] — The fixed `COLLEGIUM` layout constant in
      `src/server/src/collegium/collegium.ts`.
      Test: `src/server/src/collegium/collegium.test.ts` — border solid; exactly
      one CONTRACT_BOARD / QUARTERMASTER / DEPLOY_GATE; stations + spawn on
      floor; BFS from spawn reaches every floor tile.

- [x] T107 [R95] — Extract a pure `spawnFanOut(grid, anchorTile, count)` from
      `deploy.ts`'s `spawnPoints` into `src/server/src/site/spawn.ts`; repoint
      `handleDeploy` at it (no behavior change).
      Test: `src/server/src/site/spawn.test.ts` — distinct floor tiles, feet at
      tile center, fixed order (deterministic), fanned from the anchor;
      `deploy.test.ts` still green.

- [x] T108 [R96, R101 / P49, P52] — Generalize the tick: rename
      `fieldTick.ts` → `rooms/movementTick.ts` (`startMovementTick`/
      `stopMovementTick`, `room.moveTick`, `activeGrid(room)`); start it in
      `RoomManager.createRoom`, stop it in `destroyRoom`; drop the
      `startFieldTick` call from `handleDeploy`.
      Test: rename `fieldTick.test.ts` → `movementTick.test.ts` (fake timers) —
      tick moves against the COLLEGIUM grid in WAITING and the site grid in
      FIELD; delta discipline; grid swaps without restart; no broadcasts after
      `destroyRoom`. Update `deploy.test.ts` (no longer asserts deploy starts a
      tick).

- [x] T109 [R95] — Spawn the party in the Collegium: set `pos` +
      `startMovementTick` in `RoomManager.createRoom`; set the joiner's `pos` in
      `handleJoinRoom`.
      Test: `RoomManager.test.ts` / `handlers/joinRoom.test.ts` — creator and
      joiner get distinct Collegium floor `pos`, feet at tile center, stable
      order; a running tick is torn down on `destroyRoom` (no leak).

- [x] T110 [R97 / P50] — `MOVE` legal in WAITING/DEPLOYING/FIELD, rejected in
      COMPLETE; validation unchanged.
      Test: update `src/server/src/rooms/handlers/move.test.ts` — WAITING and
      DEPLOYING now store intent (were `WRONG_PHASE`); COMPLETE →
      `WRONG_PHASE`; not-in-room → `NOT_IN_ROOM`; malformed → `INVALID_PAYLOAD`;
      valid MOVE emits nothing, moves nothing.

- [x] T111 [R98 / P47] — `LobbySnapshot` gains `collegium` + `positions`;
      `toSnapshot` supplies them; reconnect (STATE_RESYNC) during
      WAITING/DEPLOYING carries them.
      Test: extend `src/server/src/rooms/snapshot.test.ts` — snapshot carries the
      COLLEGIUM layout + present players' positions; stringified snapshot has no
      trait-axis literals. Extend the reconnect handler test for a WAITING/
      DEPLOYING resync.

- [x] T112 [R99 / P51] — Gate `handleAcceptContract` to the CONTRACT_BOARD
      (`withinRadius` util, extracted from `handleExtract` and reused there).
      Test: extend `handlers/acceptContract.test.ts` — leader far from the board
      → `NOT_AT_CONTRACT_BOARD`, no phase change, no broadcast; leader adjacent →
      accepts as before (existing NOT_LEADER/PARTY_NOT_READY tests still green).

- [x] T113 [R100 / P51] — Gate `handleRequisition` to the QUARTERMASTER.
      Test: extend `handlers/requisition.test.ts` — far → `NOT_AT_QUARTERMASTER`,
      no bag change, no broadcast; near → requisitions as before.

- [x] T114 [R101 / P51] — Gate `handleDeploy` to the DEPLOY_GATE.
      Test: extend `handlers/deploy.test.ts` — leader far from the gate →
      `NOT_AT_DEPLOY_GATE`, stays DEPLOYING, no `FIELD_STARTED`; leader on the
      gate → deploys as before (site generated, party re-spawned in Approach).
