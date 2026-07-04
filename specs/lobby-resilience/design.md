# Lobby Resilience — Design

Satisfies R77–R80. Properties P38–P39.

## 1. `connected` on the wire (R77, P38)

`LobbyPlayer` (shared `lobby.ts`) gains `connected: boolean`. The server already
holds the truth as `ServerPlayerEntry.disconnectedAt: number | null`; the flag
is **derived at snapshot time** in `toPublicPlayer`:

```ts
connected: p.disconnectedAt === null
```

No second stored flag exists anywhere (P38). Because every snapshot flows
through `toPublicPlayer`, ROOM_CREATED / LOBBY_UPDATED / STATE_RESYNC all carry
it with no further changes. Disconnect and reconnect already broadcast
LOBBY_UPDATED, so clients see the flag flip in real time.

## 2. Ghost-proof readiness (R78)

`allReady` (readyCheck.ts) counts connected players only:

```ts
players.filter(p => p.disconnectedAt === null).every(p => p.readyState)
```

The accepter is the leader and necessarily connected (their socket delivered
the intent), so the check can never pass against an all-ghost room — a room
whose last player disconnects is destroyed by `handleSocketDisconnect` before
any intent could arrive. A disconnected player dragged into DEPLOYING keeps
their seat and can resume normally (STATE_RESYNC routes by phase).

## 3. `KICK_PLAYER` (R79, P39)

New client intent, leader-only, for freeing a seat held by a ghost — the room
caps at 4, so a ghost otherwise blocks a replacement joining (`ROOM_FULL`).

Registry: `CLIENT_MESSAGES.KICK_PLAYER`; payload type in lobbyMessages.ts:

```ts
export type KickPlayerPayload = { playerId: string };
```

New error code `CANNOT_KICK` appended to `LOBBY_ERROR_CODES` (now 14).
`pnpm gen:protocol` regenerates `client/protocol/protocol.gd`; the byte-equality
gate enforces the regen is committed.

`handleKickPlayer` (rooms/handlers/kickPlayer.ts), validation order following
the existing handler convention (payload shape first — I2 checklist):

1. payload has string `playerId` — else `INVALID_PAYLOAD`
2. sender is in a room — else `NOT_IN_ROOM`
3. sender is leader — else `NOT_LEADER`
4. phase is not FIELD — else `WRONG_PHASE` (mid-expedition seats are sacred)
5. target `playerId` exists in the room **and is disconnected** — else
   `CANNOT_KICK` (one code for both: "no such player" and "player is
   connected" — P39 means a connected target is never removed, and the error
   must not leak which of the two it was)

On success: remove the entry from `room.players`, broadcast LOBBY_UPDATED.
Errors emit to the sender only. No leader reassignment is ever needed: the
target is disconnected, and a disconnected ex-leader already lost leadership in
`handleSocketDisconnect`; the kicker is the current leader.

The kicked player's reconnect token still resolves, but `handleReconnect`
fails with `ROOM_NOT_FOUND` ("Player not found in room") — seat is gone; no
token revocation needed.

Phase note: kicking is legal in WAITING and DEPLOYING and also in COMPLETE
(vacuous — COMPLETE rooms are destroyed at extraction), so the guard is
written as `phase === 'FIELD'` rejection, not an allowlist.

## 4. Client (R80)

- `_player_row` renders `(disconnected)` when `connected == false`; the row is
  built by a `_party_row(p)` helper used by both the LOBBY and DEPLOYING
  screens (an HBox: label + optional Kick button).
- The Kick button appears only when: the viewer is leader, the row's player is
  disconnected, and the row is not the viewer. Sends
  `Protocol.KICK_PLAYER { playerId }`.
- Layout fix: the screen content (`_root`) moves inside a `ScrollContainer`
  that expands; the status label stays outside it, pinned at the bottom of the
  window. Long screens scroll; the status line is always visible.
- Resume-failure cleanup: the client sets `_awaiting_resume` when it sends
  RECONNECT; any LOBBY_ERROR while awaiting clears the persisted token (a
  kicked player's resume fails with ROOM_NOT_FOUND, which must not retry
  forever). TOKEN_EXPIRED / TOKEN_NOT_FOUND keep clearing unconditionally.

## Wire summary

| Message | Direction | Change |
|---|---|---|
| `KICK_PLAYER` | C→S | new: `{ playerId: string }` |
| `LOBBY_ERROR` | S→C | new code `CANNOT_KICK` |
| snapshots | S→C | `LobbyPlayer.connected: boolean` added |

No trait data is touched; `connected` and `playerId` are already-public
identity/liveness facts.
