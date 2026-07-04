# Lobby Resilience — Requirements

> Playtested 2026-07-03 (two windows + a scripted bot Seeker): a lobby-phase
> disconnect leaves a ghost that (a) is indistinguishable from a live teammate
> on every client, (b) blocks ACCEPT_CONTRACT forever if it was not ready, and
> (c) occupies one of the four seats with no way to free it. Reconnect itself
> is solid — the fix must not weaken it: a FIELD-phase seat stays sacred.

Numbering continues: R77+, P38+, T88+.

**R77**: As a Seeker, I can see which party members are actually connected.
`LobbyPlayer` gains `connected: boolean`, derived from the server's
`disconnectedAt` (never stored separately — P38), carried in every snapshot.
- AC: `toPublicPlayer` maps `disconnectedAt === null` ↔ `connected: true`.
- AC: the field is on the wire in ROOM_CREATED / LOBBY_UPDATED / STATE_RESYNC
  snapshots (it rides `LobbySnapshot.players`, so all three).

**R78**: As a party, we are never deadlocked by a ghost: contract acceptance
requires every **connected** player to be ready; disconnected players do not
count. (The accepter is the leader and necessarily connected, so the check can
never pass vacuously against an all-ghost room — such rooms are destroyed.)
- AC: `allReady` ignores players with `disconnectedAt !== null`.
- AC: acceptContract succeeds with a not-ready ghost in the room; still fails
  with a not-ready *connected* player.

**R79**: As the room leader, I can kick a **disconnected** player in WAITING or
DEPLOYING to free the seat. New intent `KICK_PLAYER { playerId }`; new error
code `CANNOT_KICK`. Kicking never touches a connected player (P39) and is
illegal in FIELD (mid-expedition reconnect stays sacred). The kicked seat is
gone: a later RECONNECT with the old token fails.
- AC: validations in order (payload shape first, per the I2 checklist and the
  existing handler convention) — payload shape (`INVALID_PAYLOAD`); in a room
  (`NOT_IN_ROOM`); leader (`NOT_LEADER`); not FIELD (`WRONG_PHASE`); target
  exists and is disconnected (`CANNOT_KICK`, one code for both failure kinds so
  the response never reveals which). Success removes the player and broadcasts
  LOBBY_UPDATED; errors go to the sender only.
- AC: registry + codegen updated (KICK_PLAYER, KickPlayerPayload, CANNOT_KICK);
  reproducibility gate green after regen.

**R80**: As a Seeker, the client shows all of this and stops clipping: a
disconnected player's row is visibly marked, the leader gets a Kick button on
kickable rows, and the screen content scrolls inside the window with the
status line always visible (no more resizing the window to find it).
- AC: headless Godot check + run clean; manual: drop a window and watch the
  marker appear on the other client, kick it, watch the seat free up.

## Correctness properties

- **P38**: `connected` is derived at snapshot time from `disconnectedAt`;
  there is no second stored connection flag to drift.
- **P39**: KICK_PLAYER can never remove a connected player — no griefing lever.
