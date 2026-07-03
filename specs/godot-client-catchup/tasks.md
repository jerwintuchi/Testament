# Godot Client Catch-up — Tasks

- [x] T75 [R71] — Add `ReconnectTokenPayload { reconnectToken, playerId }` to
  `src/shared/src/lobbyMessages.ts`; `handleJoinRoom` includes `playerId`.
  Test: `joinRoom.test.ts` — RECONNECT_TOKEN payload carries the joined
  player's id; `lobbyMessages.test.ts` — type exports.

- [x] T76 [R69, P35, P36] — Implement `attachTestamentServer` in
  `src/server/src/bootstrap.ts`: socket registry, emit/emitTo/broadcast seams,
  routeMessage + handleSocketDisconnect wiring.
  Test: `bootstrap.integration.test.ts` — full walk over real WebSockets
  (create → join → ready → accept → requisition → deploy → probe → extract)
  against the production wiring; two-room broadcast isolation (P35);
  post-disconnect broadcast never reaches the closed socket (P36).

- [x] T77 [R70] — Rewrite `index.ts` to boot `attachTestamentServer`; delete
  `src/server/src/room/` and `src/server/src/transport/` (with their tests).
  Test: full suite + typecheck green after deletion; no non-test imports of
  the deleted modules remain (bootstrap.integration.test.ts now owns the
  over-the-wire coverage the deleted transport tests provided).

- [x] T78 [R72] — Client: `client/net.gd` (socket + envelope + signals) and
  `client/main.gd` MENU/LOBBY screens (create/join, player list with leader,
  ready, bags; TOGGLE_READY; leader ACCEPT_CONTRACT).
  Test: R69 integration test covers the emitted sequence; manual checklist
  items 1–4 in `client/README.md` (T82).

- [x] T79 [R73] — Client: `client/catalog.gd` (GEAR_CATALOG/BAG_SLOTS/STIMULI
  mirror) and the DEPLOYING screen (contract intel, ≤4-item requisition,
  party bags, leader DEPLOY).
  Test: R69 integration test (REQUISITION leg); manual checklist items 5–7.

- [x] T80 [R74] — Client: FIELD screen (site/target, own channels, signs,
  4 stimulus probe buttons, probe-result log incl. "you cannot read it",
  exposure, leader EXTRACT) and TESTAMENT screen (outcome + archive).
  Test: R69 integration test (PROBE/EXTRACT legs); manual checklist items 8–11.

- [x] T81 [R75, R76] — Client: reconnect (token persisted to `user://` so a
  relaunch can resume; RECONNECT on a fresh socket after close; STATE_RESYNC —
  now carrying `playerId` — restores the right screen) and non-fatal
  LOBBY_ERROR status line.
  Test: existing reconnect integration tests + R69 walk; manual checklist
  items 12–13.

- [x] T82 [R72–R76] — Rewrite `client/README.md`: Testament protocol summary
  and the numbered manual playtest checklist the client ACs cite.
  Test: n/a (documentation; the checklist is itself the manual test script).

- [x] T83 [R69] — `startServer` resolves once listening and returns
  `{ port, close }` so the production entrypoint itself is bootable in a test.
  Test: `index.test.ts` — startServer(0) answers CREATE_ROOM with ROOM_CREATED
  over a real WebSocket.
