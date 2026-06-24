# Technical — Netcode

> **Status:** Canon (summary — the binding rules live in `.claude/rules/netcode-invariants.md`)
> **Sources:** .claude/rules/netcode-invariants.md (I1–I7); DECISION_LOG.md (authoritative-server, delta-updates, socket-payload hardening entries)
> **See also:** [technical/architecture.md](architecture.md) · [technical/determinism-and-rng.md](determinism-and-rng.md) · [systems/combat.md](../systems/combat.md)

## Model

Single authoritative server (Node + Socket.io). Clients receive **delta events** and render them only. Client-side prediction is deliberately deferred — room-based play with forgiving hit windows makes 50–80ms RTT imperceptible. An authoritative server is simpler, correct by construction, and required for anti-cheat.

## The seven invariants (I1–I7)

1. **I1 — Server is the only source of truth.** All game state lives in `src/server/`. Clients send *intentions*; the server validates and applies.
2. **I2 — Never trust client input.** Validate payload shape (shared types) → validate the action is legal given current state → only then mutate. On failure, emit an error to that socket only; never mutate, never broadcast.
3. **I3 — Seeded RNG is server-only and deterministic.** The `runId` never leaves the server. ([determinism-and-rng.md](determinism-and-rng.md))
4. **I4 — `src/shared` contains no game logic.** Types, interfaces, enums, constants, and pure non-domain helpers (e.g. `hexCoordKey`) only.
5. **I5 — All synergy evaluation is server-side and pure.** `evaluateSynergies` lives in `src/server/`, never called from the client; broadcast via `RELIC_PLACED` / `RELIC_REMOVED`.
6. **I6 — Delta events, not full state pushes.** After the initial `BOARD_STATE_SYNC`, send deltas only. Exceptions: reconnection / explicit `STATE_RESYNC`.
7. **I7 — Room state is ephemeral.** Active runs are never written to the DB; lost on server restart (acceptable for 20–40 min sessions). Only post-run meta-progression persists.

## New-handler checklist

- [ ] Input validated against shared type before any mutation
- [ ] Action authorized (player in this room; legal in current phase)
- [ ] State mutation synchronous, returns new state
- [ ] Delta event(s) broadcast to room after mutation
- [ ] Error path emits to the requesting socket only; no broadcast

## Hardening already done

Identity is server-derived everywhere: `placeRelic` and `revive` use the authenticated socket's player id, not a client-supplied field. Socket handlers shape-guard untrusted payloads (`isCoord`) and emit targeted error codes (`INVALID_COORD`, `INVALID_REQUEST`, `WRONG_PHASE`, etc.) rather than throwing. Room codes use `node:crypto` (unpredictable), deliberately outside the seeded-RNG mandate.

## Event catalog (representative)

- **Lobby/room:** `ROOM_UPDATE`, `RUN_STARTED`, `RUN_ENDED`, `LOBBY_ERROR`, `FLOOR_ADVANCED`, `PHASE_CHANGED`.
- **Board:** `BOARD_STATE_SYNC`, `RELIC_PLACED`, `RELIC_REMOVED`, `RELIC_PLACE_ERROR`, `LINKED_FATES_ERROR`, `BOARD_DOCTRINE_SHIFT`.
- **Bleed:** `BLEED_CLOCK_TICK`, `BLEED_STAGE_CHANGED`.
- **Combat:** `ENEMY_SPAWNED/DAMAGED/DIED/MOVED`, `PLAYER_DAMAGED/DOWNED/REVIVED/MOVED`, `PLAYER_AIM_CHANGED`, `PROJECTILE_FIRED/REMOVED`.

> Socket wiring is typed against minimal `SocketIOServerLike` / `ServerSocket` interfaces so handler logic is fully testable with fakes; the real socket.io `Server` is cast at a single boundary in `startServer` (guarded by an `isMain` check so importing under tests never opens a port).
