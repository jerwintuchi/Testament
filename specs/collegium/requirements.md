# Requirements — Collegium (Staging Site) v1

> Phase 5, spec 2. The party's **preparation map**: a fixed, walkable Collegium
> the party spawns into during the lobby phases (WAITING + DEPLOYING), built on
> the field-space movement stack (TD-035). Prep actions become **spatial
> stations** — accept a contract at the Contract Board, requisition at the
> Quartermaster, deploy at the Deploy Gate — gated exactly like field
> extraction (`NOT_AT_EXTRACTION`, R90). Full spatial prep (new interaction
> verbs, per-station UIs, the Archive as a room) is deferred to a later spec;
> this one spatializes *access* to the existing, working prep handlers.
>
> Server + shared wire only. The Godot client learns to render the Collegium and
> reuses its `MOVE` sender in a follow-up client spec.
>
> R# numbering continues from R91 (field-space). Reuses the field-space wire
> (`MOVE`, `POSITIONS`, `SiteGrid`, `PlayerPositions`, `SEEKER_*`).

---

## Functional Requirements

**R92**: As the shared wire protocol, the Collegium station vocabulary is in
`@testament/shared` with no logic and no server-only types (I4).
- AC: `StationKind = 'CONTRACT_BOARD' | 'QUARTERMASTER' | 'DEPLOY_GATE'`,
  authored as a runtime `STATION_KINDS` const array (codegen-able pattern);
  `Station = { kind: StationKind; x: number; y: number }` (tile coords).
- AC: `CollegiumLayout = { grid: SiteGrid; stations: Station[]; spawn: { x: number; y: number } }`
  reuses the field-space `SiteGrid`; `spawn` is a tile-coord anchor.
- AC: `STATION_RADIUS` (px) exported — the gating radius, the wire contract both
  sides honor (parallels `EXTRACTION_RADIUS`).
- AC: Nothing in the new types references `TraitRoll`, `SiteNode`, or any
  server-only type.

**R93**: As the protocol contract, the station error codes are registered so the
GDScript client cannot drift.
- AC: `NOT_AT_CONTRACT_BOARD`, `NOT_AT_QUARTERMASTER`, `NOT_AT_DEPLOY_GATE`
  are added to `LOBBY_ERROR_CODES` in `src/shared/src/lobbyMessages.ts`.
- AC: `pnpm gen:protocol` regenerates the GDScript side and the tools sync test
  passes. No new message *names* — the station actions reuse `ACCEPT_CONTRACT`,
  `REQUISITION`, `DEPLOY`, `MOVE`, `POSITIONS`.

**R94**: As the Collegium, the fixed layout is structurally sound for play.
- AC: `COLLEGIUM` is a single authored `CollegiumLayout` constant in
  `src/server/src/collegium/` (server-side content, like `GEAR_CATALOG`);
  it is *not* seeded/generated — the party's home is stable and recognizable.
- AC: All border tiles are solid; the `spawn` anchor and every station sit on a
  floor tile.
- AC: Exactly one `CONTRACT_BOARD`, one `QUARTERMASTER`, one `DEPLOY_GATE`.
- AC: Every floor tile (hence every station) is reachable from `spawn` by
  4-neighbor floor walk (no sealed pockets). Verified by an invariant test over
  the one fixed layout (BFS).

**R95**: As a Seeker, joining a room places me in the Collegium.
- AC: On room create and on join (WAITING), the new player's `pos` is set to a
  distinct Collegium floor tile fanned out from the `spawn` anchor (feet at tile
  center); no two present players share a tile.
- AC: Spawn assignment is deterministic (fixed neighbor order over the fixed
  layout) — the Nth player to join always lands on the Nth fan-out tile.
- AC: A player's `pos` survives disconnect (kept; only `moveIntent` is zeroed),
  so a reconnecting Seeker resumes in place.

**R96**: As the server, movement is integrated authoritatively on the same 20Hz
tick across every walkable phase, colliding against the phase's active grid
(I1, I6).
- AC: The movement tick runs during WAITING, DEPLOYING, and FIELD. Its active
  grid is the `COLLEGIUM` grid in WAITING/DEPLOYING and `room.site.grid` in
  FIELD (`activeGrid(room)`); COMPLETE has no grid and the tick moves nothing.
- AC: The tick starts when a room is created (the party has a body from the
  first spawn) and stops on room destruction (extract-completion, last-player
  removal, all-disconnected) — one timer for the room's whole walkable life; it
  is *not* stopped and restarted at the WAITING→FIELD boundary (the grid swaps
  under it).
- AC: Delta discipline holds unchanged: a tick with no movement broadcasts
  nothing; `POSITIONS` names only moved players (I6).
- AC: No timer outlives its room (fake-timer test: no further broadcasts after
  destruction).

**R97**: As a Seeker, I can move whenever I have a body.
- AC: `MOVE` is legal in WAITING, DEPLOYING, and FIELD; in COMPLETE (or outside
  a room) it is rejected (`WRONG_PHASE` / `NOT_IN_ROOM`) with no state change.
- AC: Payload validation is unchanged (missing/non-finite/out-of-range `dx`/`dy`
  → `INVALID_PAYLOAD`, sender only); a valid `MOVE` still only stores intent and
  broadcasts nothing (R86 semantics, now phase-generalized).

**R98**: As a Seeker (and a reconnecting one), I receive the Collegium and the
party's positions.
- AC: `LobbySnapshot` gains `collegium: CollegiumLayout` and
  `positions: PlayerPositions` (all present players' feet px). `toSnapshot`
  supplies them.
- AC: A reconnect during WAITING/DEPLOYING carries them via the `LobbySnapshot`
  inside `STATE_RESYNC`; the reconnecting client can render the hall and place
  everyone where they are.
- AC: Trait containment holds — `JSON.stringify` of the lobby snapshot carries
  no trait-axis literals (extends the existing containment tests).

**R99**: As a Seeker, accepting a contract is an action at the Contract Board.
- AC: `ACCEPT_CONTRACT` from a leader whose feet are farther than
  `STATION_RADIUS` px from the `CONTRACT_BOARD` tile center →
  `NOT_AT_CONTRACT_BOARD` to sender only; no state change, no broadcast. The
  existing `NOT_LEADER` / `PARTY_NOT_READY` guards are unchanged.
- AC: Within the radius, acceptance behaves exactly as today.

**R100**: As a Seeker, requisition is an action at the Quartermaster.
- AC: `REQUISITION` from a player whose feet are farther than `STATION_RADIUS`
  from the `QUARTERMASTER` tile center → `NOT_AT_QUARTERMASTER` to sender only;
  no state change. Existing payload/phase guards unchanged.
- AC: Within the radius, requisition behaves exactly as today.

**R101**: As a Seeker, deployment is an action at the Deploy Gate (the mirror of
Extraction).
- AC: `DEPLOY` from the leader whose feet are farther than `STATION_RADIUS` from
  the `DEPLOY_GATE` tile center → `NOT_AT_DEPLOY_GATE` to sender only; no state
  change. Existing `NOT_LEADER` / phase guards unchanged.
- AC: Within the radius, deployment behaves exactly as today (generate the site,
  re-spawn the party in the Approach room, `FIELD_STARTED`), and it no longer
  *starts* the movement tick — the tick is already running from room creation
  and simply swaps its active grid to the site.
