# Godot Client Catch-up — Requirements

> Phase 4 closure: all five Phase 4 deliverables exist server-side (TD-027), but
> the production server still boots the Phase 1 transport-spike protocol and the
> Godot client still speaks it. This spec converges both onto the Testament
> protocol so the Phase 4 exit gate — a party reads an Incarnate from signs and
> probes and forms a theory — is *playable*, not just walkable in tests.

Numbering continues from the loadout-economy spec: R69+, P35+, T75+.

## Server side

**R69**: As a Seeker, when I connect to the production server, I am speaking the
Testament protocol (`CREATE_ROOM` … `REQUISITION`), not the spike protocol —
`startServer` wires `routeMessage` and `handleSocketDisconnect` over raw
WebSocket exactly as the integration tests do.
- AC: an integration test boots the *production* wiring (the exported attach
  function, not a test re-implementation) and walks
  create → join → ready → accept → requisition → deploy → probe → extract
  over real WebSockets.
- AC: `emit` reaches only the sender; `emitTo` only the named socket;
  `broadcast` only connected sockets whose player entry is in that room —
  verified with two concurrent rooms (no cross-room leak).

**R70**: As a maintainer, there is exactly one room system. The spike's
`src/server/src/room/` manager, `src/server/src/transport/` hub, and the spike
handlers in `index.ts` are retired. Pure algorithm modules with no protocol
surface (`combat/`, `dungeon/`, `rng/`) are retained: `rng/` is live
(contract generation) and `combat/` + `dungeon/` are dormant Phase 5 assets.
- AC: no non-test file imports `room/` or `transport/`; both packages
  typecheck; the full suite is green after the deletion.

**R71**: As a joining Seeker, I learn my own `playerId`, so the client can
render which lobby entry is *me*. `JOIN_ROOM`'s `RECONNECT_TOKEN` reply carries
`playerId`, and the payload gets a shared wire type (`ReconnectTokenPayload`).
- AC: `joinRoom.test.ts` asserts the emitted payload's `playerId` equals the
  joined player entry's id.
- AC: `@testament/shared` exports `ReconnectTokenPayload`; types only (I4).

## Client side

The client is render + input only (trust boundary): every screen transition is
driven by a server event, never by local prediction. GDScript has no test
harness in this repo, so client ACs are verified by (a) the R69 integration
test, which walks the exact message sequence the client emits, and (b) the
manual playtest checklist in `client/README.md` (T82).

**R72**: As a Seeker, I can enter a display name and create a room or join one
by code, then see the lobby: every player's name, leader mark, ready state, and
bag; I can toggle ready; the leader can accept the contract when all are ready.
- AC: client emits `CREATE_ROOM`/`JOIN_ROOM`/`TOGGLE_READY`/`ACCEPT_CONTRACT`
  with the shared payload shapes; lobby renders from `ROOM_CREATED` /
  `LOBBY_UPDATED` snapshots only.

**R73**: As a Seeker during DEPLOYING, I see the contract intel (target, site,
tier, primary verb) and the gear catalog; I can select up to `BAG_SLOTS` items
and requisition (replace-not-merge); I see every party member's bag update; the
leader can deploy.
- AC: client emits `REQUISITION { itemIds }` and renders bags from
  `LOBBY_UPDATED`; the catalog rendered is a mirror of `GEAR_CATALOG`
  (ids/names/kinds/channels/stimuli) in `client/catalog.gd`.

**R74**: As a Seeker in the field, I see the site, the target, my own perceived
channels, and my filtered signs from `FIELD_STARTED`; I can probe with one of
the four stimuli; I see each `PROBE_RESULT` (who probed, stimulus, the sign or
"you cannot read it" when `sign` is null, and party exposure); the leader can
extract; I then see the Field Testament and archive entries.
- AC: client emits `PROBE { stimulus }` / `EXTRACT`; field screen renders only
  wire data (signs and channels — never trait values, which never arrive).

**R75**: As a disconnected Seeker, my client kept the reconnect token (persisted
to `user://`, so it survives a relaunch) and can send `RECONNECT { token }` on a
fresh socket; `STATE_RESYNC` restores me to the correct screen (lobby for
WAITING/DEPLOYING, field for FIELD, with signs and perceived channels intact)
and carries my `playerId`, since a relaunched client holds only the token.
- AC: `reconnect.test.ts` asserts STATE_RESYNC's `playerId` names the
  reconnecting player; the existing reconnect integration tests plus the manual
  checklist cover the client-side restore.

**R76**: As a Seeker, when the server rejects an intention (`LOBBY_ERROR`), I
see the message non-fatally (status line), and the client stays on its current
screen — errors never mutate client state.
- AC: manual checklist: joining a bad code shows ROOM_NOT_FOUND and returns to
  the menu; probing without the kit shows MISSING_GEAR and stays in the field.
