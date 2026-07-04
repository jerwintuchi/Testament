# Lobby Resilience — Tasks

- [x] T88 [R77, P38] — Add `connected: boolean` to `LobbyPlayer`
  (`src/shared/src/lobby.ts`); derive it in `toPublicPlayer`
  (`src/server/src/rooms/types.ts`) from `disconnectedAt === null`; update
  every test fixture that constructs a `LobbyPlayer`.
  Test: `types.test.ts` — toPublicPlayer maps disconnectedAt null/set to
  connected true/false; `snapshot.test.ts` — snapshots carry the flag.

- [x] T89 [R78] — `allReady` counts connected players only
  (`src/server/src/rooms/readyCheck.ts`).
  Test: `readyCheck.test.ts` — a not-ready ghost does not block; a not-ready
  connected player still blocks; `acceptContract.test.ts` — acceptance
  succeeds with a not-ready ghost in the room.

- [x] T90 [R79] — Registry: `CLIENT_MESSAGES.KICK_PLAYER`,
  `KickPlayerPayload`, `CANNOT_KICK` in `LOBBY_ERROR_CODES` (14); run
  `pnpm gen:protocol` and commit the regenerated `protocol.gd`.
  Test: `messages.test.ts` — KICK_PLAYER in the exact name set + payload-map
  exhaustiveness; `lobbyMessages.test.ts` — fourteen codes;
  `generate.test.ts` — reproducibility gate green after regen.

- [x] T91 [R79, P39] — Implement `handleKickPlayer`
  (`src/server/src/rooms/handlers/kickPlayer.ts`) + router case.
  Test: `kickPlayer.test.ts` — INVALID_PAYLOAD / NOT_IN_ROOM / NOT_LEADER /
  WRONG_PHASE (FIELD) / CANNOT_KICK (unknown target; connected target);
  success removes the player and broadcasts LOBBY_UPDATED; errors never
  broadcast; a kicked player's RECONNECT then fails.

- [x] T92 [R78, R79] — Over-the-wire proof in
  `bootstrap.integration.test.ts`: joiner drops without readying; leader
  readies and ACCEPT_CONTRACT succeeds (R78); leader kicks the ghost; a new
  player can join the freed seat; the kicked token's RECONNECT fails.

- [x] T93 [R80] — Client: `_party_row` helper with `(disconnected)` marker and
  leader-only Kick button (LOBBY + DEPLOYING screens); `_root` inside a
  `ScrollContainer` with the status label pinned outside it; RECONNECT
  failure while awaiting resume clears the persisted token.
  Test: headless Godot 4.7 `--check-only` + project run clean; manual gate —
  drop a window, watch the marker, kick, watch the seat free (added to
  `client/README.md` checklist items 14–15).

- [x] T94 [R77–R80] — Docs: DECISION_LOG TD-032 (ghost visibility, ghost-proof
  readiness, kick policy, FIELD seats stay sacred); CLAUDE.md Active Work
  refresh (protocol reconciliation is done; this spec is the tail of Phase 4);
  README checklist items.
  Test: n/a (documentation).
