# Requirements — Field Space v1

> Phase 5, spec 1. The spatial substrate combat needs: a seeded tile-based site,
> player positions, server-integrated movement, and the TD-018 node vocabulary
> (Approach, Sign-source, Lair, Extraction — Probe-features and Caches deferred
> until probes/items are themselves spatial). After TD-034 the repo has no
> geometry or movement code at all; this spec rebuilds it on the canonical grid
> (TD-033: 16x16 tiles), not the spike's free world units.
>
> Server + shared wire only. The Godot client learns to render the site and send
> `MOVE` in a follow-up client spec (the TD-028 pattern); until that lands, the
> next playtest is blocked on the client spec because EXTRACT becomes
> position-gated (R90).
>
> R# numbering continues from R80 (lobby-resilience spec).

---

## Functional Requirements

**R81**: As the shared wire protocol, site geometry types are in
`@testament/shared` with no logic and no server-only types (I4).
- AC: `SiteGrid = { width: number; height: number; rows: string[] }` where each
  row is a string of `#` (solid) and `.` (floor), `rows.length === height`,
  every row length `=== width`. Language-neutral: trivially parsed by GDScript.
- AC: `SiteNodeKind = 'APPROACH' | 'SIGN_SOURCE' | 'LAIR' | 'EXTRACTION'`,
  `SiteNode = { kind: SiteNodeKind; x: number; y: number }` (tile coords),
  `SiteLayout = { grid: SiteGrid; nodes: SiteNode[] }`.
- AC: Constants exported: `TILE_SIZE = 16` (px), `FIELD_TICK_HZ = 20`,
  `SEEKER_SPEED` (px/s), `SEEKER_FEET_HALF_WIDTH`, `SEEKER_FEET_HEIGHT` (px),
  `EXTRACTION_RADIUS` (px). Values are the wire contract both sides honor.
- AC: `MovePayload = { dx: number; dy: number }` (client → server, each in
  [-1, 1]) and `PositionsPayload = { positions: Record<string, { x: number; y: number }> }`
  (server → room) are exported from `src/shared/src/fieldMessages.ts`.
- AC: Nothing in the new types references `TraitRoll` or any server-only type.

**R82**: As the protocol contract, the new message names are registered and
codegen'd so the GDScript client cannot drift.
- AC: `MOVE` is added to the client→server names and `POSITIONS` to the
  server→client names in `src/shared/src/messages.ts`, with payload-type
  mappings.
- AC: `pnpm gen:protocol` regenerates the GDScript registry and the tools
  sync test passes.

**R83**: As the server, the site is generated purely and deterministically from
the expedition seed (I3, I5).
- AC: `generateSite(rng)` is a pure function in `src/server/src/site/`; the
  same `Rng` state → an identical `SiteLayout`, always.
- AC: The site RNG stream is namespaced (`hashSeed(expeditionSeed + ':site')`)
  so existing contract/trait-roll generation streams are unchanged (existing
  determinism tests keep passing without edits).

**R84**: As the site, the layout is structurally sound for play.
- AC: All border tiles are solid.
- AC: Exactly one `APPROACH`, one `LAIR`, one `EXTRACTION`, and at least two
  `SIGN_SOURCE` nodes; every node sits on a floor tile.
- AC: Every floor tile (hence every node) is reachable from `APPROACH` by
  4-neighbor floor walk (no sealed pockets).
- AC: Holds across many seeds (property test, ≥100 seeds).

**R85**: As a Seeker, deploying places the party in the site.
- AC: On DEPLOY, `FieldStartedPayload` gains `site: SiteLayout` and
  `positions: Record<playerId, { x: number; y: number }>` (px); every player
  spawns on floor within the `APPROACH` room area, no two players identical.
- AC: Same expedition seed → identical `site` and spawn positions.

**R86**: As the server, `MOVE` is validated before any state change (I2).
- AC: Payload with missing/non-finite/out-of-range `dx` or `dy` →
  `LOBBY_ERROR` code `INVALID_PAYLOAD` to sender only; no state mutation.
- AC: `MOVE` outside a room → `NOT_IN_ROOM`; in a non-FIELD phase →
  `WRONG_PHASE` (matches `assertPhase` behavior). Sender only; no broadcast.
- AC: A valid `MOVE` stores the sender's movement intent only — position
  changes happen exclusively in the tick (R87). No immediate broadcast.

**R87**: As the server, movement is integrated authoritatively on a 20Hz field
tick, and only changes are broadcast (I1, I6).
- AC: Each tick applies every connected player's stored intent via the pure
  step function (R88) and broadcasts one `POSITIONS` delta containing only
  players whose position changed; a tick with no movement broadcasts nothing.
- AC: Client message rate cannot move a player faster than `SEEKER_SPEED`
  (intent is a direction, sampled once per tick).
- AC: A disconnected player's intent is cleared (ghosts don't drift).

**R88**: As a Seeker, I cannot pass through solid tiles.
- AC: `stepPlayer(pos, dx, dy, dtMs, grid)` is pure; the resulting feet AABB
  (`SEEKER_FEET_HALF_WIDTH` × `SEEKER_FEET_HEIGHT`) never overlaps a solid tile,
  for any input direction (property test).
- AC: Diagonal input is normalized (no √2 speed advantage); movement into a wall
  slides along it (axis-separated resolution) rather than sticking.

**R89**: As a reconnecting Seeker, I resume in place.
- AC: `FieldSnapshot` gains `site: SiteLayout` and `positions` (all players'
  current px positions); a reconnect during FIELD receives them via
  `STATE_RESYNC`.

**R90**: As a Seeker, extraction is a leave action from the Extraction node
(TD-018), not an anywhere-button.
- AC: `EXTRACT` from a player whose feet position is farther than
  `EXTRACTION_RADIUS` px from the `EXTRACTION` node's tile center →
  `LOBBY_ERROR` code `NOT_AT_EXTRACTION` to sender only; no state change.
- AC: `EXTRACT` within the radius behaves exactly as today (testament,
  archive, room completion).

**R91**: As the server, the field tick does not leak.
- AC: The tick starts when the room enters FIELD and stops on room completion
  (extract), room destruction, and last-player removal; no timer survives its
  room (fake-timer test asserts no further broadcasts after stop).
