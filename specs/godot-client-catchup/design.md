# Godot Client Catch-up — Design

Satisfies R69–R76. Properties P35–P37.

## 1. Server bootstrap (`src/server/src/bootstrap.ts`, rewritten `index.ts`)

The Testament router (`rooms/messageRouter.ts`) is fully unit- and
integration-tested but only ever wired inside tests; production `index.ts`
still boots the spike (`create-room`/`start-run`/`move-player` against
`room/manager.ts`). The fix promotes the integration-test wiring into a
production module.

### `attachTestamentServer(wss: WebSocketServerLike): TestamentServer`

Pure transport plumbing (P36 — holds **no game state**; room membership is
derived from `RoomManager` player entries, never tracked in the transport):

```
sockets: Map<socketId, RawSocket>        // the only bootstrap-owned state
roomManager, tokenStore, sessionArchive  // the game core, owned per server

on connection(raw):
  socketId = "s" + counter++
  sockets.set(socketId, raw)
  emit      = (type, payload) -> raw.send(envelope)
  emitTo    = (sid, ...)      -> sockets.get(sid)?.send(envelope)
  broadcast = (code, ...)     -> for p in roomManager.getRoom(code).players:
                                   sockets.get(p.socketId)?.send(envelope)
  on message(data): routeMessage(socketId, data, mgr, store,
                                 emit, emitTo, broadcast, sessionArchive)
  on close: sockets.delete(socketId)
            handleSocketDisconnect(socketId, mgr, broadcast)
```

`index.ts` shrinks to: create `WebSocketServer`, call `attachTestamentServer`,
log. The movement tick, `room/`, and `transport/` go away (R70); movement
returns in Phase 5 through the Testament field phase, not the spike.

Envelope: `{ "type": string, "payload": unknown }` — unchanged (TD-002).

### Correctness properties

- **P35 (delivery scope)**: `emit` reaches exactly the sender; `emitTo` exactly
  the named socket; `broadcast(code)` exactly the connected sockets whose
  player entry lives in room `code`. Two-room test proves no cross-room leak.
- **P36 (stateless transport)**: bootstrap holds only `Map<socketId, socket>`;
  every routing decision reads `RoomManager`. Disconnect deletes the map entry
  before delegating, so a dangling socket can never receive a broadcast.

## 2. Wire-protocol addition (R71)

`JOIN_ROOM` currently replies `RECONNECT_TOKEN { reconnectToken }` — the joiner
has no way to know which snapshot entry is itself (the creator infers
`players[0]` from `ROOM_CREATED`; a joiner cannot safely infer anything).

New shared type in `lobbyMessages.ts`:

```ts
export type ReconnectTokenPayload = {
  reconnectToken: string;
  playerId: string;   // the receiving player's own id — self-identification
};
```

`handleJoinRoom` adds `playerId: player.playerId` to the existing emit.
`StateResyncPayload` gains the same `playerId` field, emitted by
`handleReconnect`: a **relaunched** client holds nothing but the persisted
token, so the resync must name which snapshot entry it is (otherwise a resumed
leader loses their leader controls). No new message types; `playerId` is
server-generated identity (not trait data) already visible in every snapshot —
safe on the wire.

## 3. Godot client (`client/`)

Three scripts, one scene. Render + input only (P37): every screen transition is
caused by a received server event; user input only ever *sends* an intention.

| File | Role |
|------|------|
| `client/net.gd` | `WebSocketPeer` wrapper: connect, poll, JSON envelope encode/decode, `message(type, payload)` + `socket_closed` signals. No game knowledge. |
| `client/catalog.gd` | Protocol mirror of `@testament/shared` constants the client must render: `GEAR_CATALOG`, `BAG_SLOTS`, `STIMULI`, channel list. Header comment marks it **generated-by-hand from `src/shared/src/gear.ts` + `signs.ts` — keep in lockstep**. |
| `client/main.gd` | State machine + code-built UI (no hand-edited .tscn beyond the root node). |

### Client state machine (states = screens)

```
MENU ──CREATE_ROOM/JOIN_ROOM──▶ (await) ──ROOM_CREATED/LOBBY_UPDATED+RECONNECT_TOKEN──▶ LOBBY
LOBBY ──(snapshot.phase == "DEPLOYING" via ROOM_DEPLOYING/LOBBY_UPDATED)──▶ DEPLOYING
DEPLOYING ──FIELD_STARTED──▶ FIELD
FIELD ──FIELD_TESTAMENT──▶ TESTAMENT
TESTAMENT ──LOBBY_UPDATED (phase COMPLETE→…)/user "back"──▶ LOBBY or MENU
any ──socket_closed──▶ RECONNECTING (offers RECONNECT{token} on new socket)
RECONNECTING ──STATE_RESYNC──▶ LOBBY | DEPLOYING | FIELD (from snapshot.phase / fieldSnapshot)
any ──LOBBY_ERROR──▶ same state, status-line message (R76)
```

Self-identity: `ROOM_CREATED` → `snapshot.players[0].playerId` (creator is the
only player); `RECONNECT_TOKEN` → `payload.playerId` (R71). Stored with the
token in memory for the session.

### Screens → wire messages

| Screen | Renders (from) | Sends |
|--------|----------------|-------|
| MENU | — | `CREATE_ROOM {displayName}`, `JOIN_ROOM {code, displayName}` |
| LOBBY | `LobbySnapshot`: players (name, leader ★, ready ✓, bag), room code | `TOGGLE_READY {}`, `ACCEPT_CONTRACT {}` (leader) |
| DEPLOYING | `ContractIntel` (target, site, tier, verb); catalog checklist (≤ `BAG_SLOTS`); party bags from snapshots | `REQUISITION {itemIds}`, `DEPLOY {}` (leader) |
| FIELD | `FieldStartedPayload` / `FieldSnapshot`: site, target, own `perceivedChannels`, signs list; probe-result log; exposure | `PROBE {stimulus}`, `EXTRACT {}` (leader) |
| TESTAMENT | `StubTestament` + `ArchiveUpdatedPayload.entries` | — |

The signs list renders `Sign { channel, token }` verbatim — the client never
receives and never displays trait values (CLAUDE.md invariant 3 upheld by
construction: they are not on the wire).

`PROBE_RESULT.sign == null` renders as *"you cannot read it"* — the distributed-
perception experience, not an error.

### Verification strategy

No GDScript harness exists in this repo (and no headless Godot in the dev
environment), so the *protocol* is verified server-side: the R69 integration
test drives the production bootstrap through the exact sequence the client
emits. The client's rendering is verified by the manual playtest checklist in
`client/README.md` (T82). This mirrors the transport spike's precedent.

## 4. Retirements (R70)

Deleted: `src/server/src/room/` (manager, state, sync, roomCode + tests),
`src/server/src/transport/` (wsHub, protocol, types + tests), spike handler
body of `index.ts`. Kept dormant: `combat/movement.ts`, `dungeon/` (pure,
tested, Phase 5 re-entry points); kept live: `rng/`. Spike-era shared types
(`RoomSummary`, `JoinRoomRequest`, `RoomUpdateEvent`, `LobbyErrorEvent`,
`MovePlayerRequest`, dungeon wire types) stay in `@testament/shared` untouched
this spec — pruning them is a follow-up once Phase 5 decides what movement
looks like.
