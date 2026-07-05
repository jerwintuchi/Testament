# Tasks — Field Space v1

> T# numbering continues from T94 (lobby-resilience). Every task names its test
> before implementation (spec workflow). Order is dependency order.

- [x] T95 [R81] — Shared site types + constants in `src/shared/src/site.ts`,
      re-exported from the shared index; `MovePayload`/`PositionsPayload` in
      `src/shared/src/fieldMessages.ts`.
      Test: `src/shared/src/site.test.ts` — constants exported with the design
      values; `SITE_NODE_KINDS` runtime array matches the type; no server-only
      imports (compile-time containment, T40 pattern).

- [x] T96 [R82] — Register `MOVE` (client→server) and `POSITIONS`
      (server→client) with payload mappings in `src/shared/src/messages.ts`;
      run `pnpm gen:protocol`.
      Test: `src/shared/src/messages.test.ts` — names present in the right
      registries; `tools` sync test green against the regenerated GDScript.

- [x] T97 [R83, R84 / P41, P42] — Pure `generateSite(rng)` in
      `src/server/src/site/generateSite.ts` (grid carve + node placement per
      design).
      Test: `src/server/src/site/generateSite.test.ts` — same rng seed →
      deep-equal layout; property over ≥100 seeds: border solid, node
      multiplicities (1 APPROACH / 1 LAIR / 1 EXTRACTION / ≥2 SIGN_SOURCE),
      nodes on floor, BFS from APPROACH reaches every floor tile.

- [x] T98 [R88 / P43] — Pure `stepPlayer(pos, dx, dy, dtMs, grid)` in
      `src/server/src/site/movement.ts` (normalize, integrate, axis-separated
      collide).
      Test: `src/server/src/site/movement.test.ts` — property: post-step feet
      AABB never overlaps solid; diagonal magnitude ≤ SEEKER_SPEED·dt; wall
      contact slides (blocked axis reverts, free axis advances); zero intent →
      identical position.

- [x] T99 [R86 / P44] — `MOVE` handler in
      `src/server/src/rooms/handlers/move.ts`: validation → `assertPhase` →
      store `moveIntent`; wire into the message router. `RoomRecord` gains
      `site`/`fieldTick`; `ServerPlayerEntry` gains `pos`/`moveIntent`.
      Test: `src/server/src/rooms/handlers/move.test.ts` — validation matrix
      (missing/NaN/Infinity/out-of-range → `INVALID_PAYLOAD`; not in room →
      `NOT_IN_ROOM`; WAITING/DEPLOYING/COMPLETE → `WRONG_PHASE`); valid MOVE
      stores intent, emits nothing, moves nothing.

- [x] T100 [R87, R91 / P44, P45, P46] — Field tick in
      `src/server/src/rooms/fieldTick.ts` (`startFieldTick`/`stopFieldTick`);
      disconnect clears the ghost's intent.
      Test: `src/server/src/rooms/fieldTick.test.ts` (fake timers) — tick
      applies stored intents at SEEKER_SPEED; `POSITIONS` carries only moved
      players; all-idle tick broadcasts nothing; disconnected player stops
      moving; after `stopFieldTick`/room destruction no further broadcasts.

- [x] T101 [R85 / P41, P47] — Deploy integration: generate site from
      `hashSeed(expeditionSeed + ':site')`, spawn party in the APPROACH room,
      start the tick, extend `FIELD_STARTED`.
      Test: extend `src/server/src/rooms/handlers/deploy.test.ts` — payload
      carries `site` + `positions`; spawns distinct, on floor, in APPROACH
      room; same seed → identical site/spawns; stringified payload still
      carries no trait-axis literals.

- [x] T102 [R89 / P47] — Reconnect: `FieldSnapshot` gains `site` +
      `positions`; `buildFieldSnapshot` supplies them.
      Test: extend `src/server/src/rooms/fieldData.test.ts` (and the reconnect
      handler test) — FIELD-phase resync carries the live site and current
      positions; containment check on the stringified snapshot.

- [x] T103 [R90] — Extraction gating in `handleExtract`: sender's feet within
      `EXTRACTION_RADIUS` of the EXTRACTION tile center, else
      `NOT_AT_EXTRACTION` (sender only); success path stops the tick.
      Test: extend `src/server/src/rooms/handlers/extract.test.ts` — far →
      error, no state change, no broadcast; player moved adjacent to the node
      → extraction completes exactly as before.
