# Playtest — Collegium Client (Walkable Spaces) v1

> The named "test" for this client spec (no GDScript unit harness; prior client
> convention). Run via the Godot MCP against a live server. Each item is an
> observable assertion; the client `print()`s the load-bearing events so
> `get_debug_output` can confirm them.
>
> **Setup:** `pnpm dev:server` up (`ws://localhost:3001`); `run_project` on the
> Godot client project; read `get_debug_output` after each step; `stop_project`
> at the end. Two clients (two `run_project` targets, or one manual window + one
> MCP) exercise the multi-body items.

## Items

1. **Boot + Collegium renders (R102/R105).** Create a room. `get_debug_output`
   shows `phase=WAITING grid=24x16`; a hall of floor/solid tiles is drawn with
   three labeled station glyphs (Contract Board N, Quartermaster W, Deploy Gate S);
   `bodies=1` with the local body at the spawn atrium (~tile 12,8).

2. **Walk (R104/R103).** Hold each arrow in turn. Each *press* and *release* logs
   exactly one `MOVE dx dy` edge (no per-frame spam); the local body slides in the
   pressed direction and stops on release. Walking into a wall stops the body at
   the wall (server collision), the client never clips through.

3. **Input authority (R104 AC3/P54).** Stop the server (or before it ticks). Press
   a direction: `MOVE` logs, but the local body does **not** move (no `POSITIONS`
   → no movement). Confirms input never moves the body locally.

4. **Two bodies + delta (R103/P55).** Second client joins. Both clients show two
   bodies at distinct spawn tiles (`bodies=2`); the local body is visually distinct
   (ring vs disc). When one walks, the other client's view moves only that body
   (`POSITIONS` names one player), the stationary body stays put.

5. **Station gating — Contract Board (R106).** As leader, standing in the atrium
   (far from the board): no "Accept Contract" button, a hint says "Walk to the
   Contract Board." Walk within `STATION_RADIUS` (log `at CONTRACT_BOARD`): the
   Accept button appears; all-ready → accept succeeds → `phase=DEPLOYING`. If the
   button is somehow pressed out of range, `NOT_AT_CONTRACT_BOARD` shows in status.

6. **Quartermaster + Deploy Gate (R106).** In DEPLOYING the Collegium still renders
   and the party still walks. The requisition checklist appears only within the
   Quartermaster radius (`at QUARTERMASTER`); requisition succeeds there. Walk to
   the Deploy Gate (leader, `at DEPLOY_GATE`): Deploy appears and succeeds →
   `FIELD_STARTED`.

7. **Field renders + walk (R107).** After deploy: `phase=FIELD grid=WxH` for the
   generated site; the site tiles + nodes (Approach, Sign source, Lair, Extraction)
   draw; bodies at Approach spawn. Walking works identically; the signs/probe/
   exposure overlay is present.

8. **Extraction gating (R107).** Far from the Extraction node: no Extract button,
   hint "Walk to the Extraction." Walk within `EXTRACTION_RADIUS` (`at EXTRACTION`):
   Extract appears and completes the expedition → Field Testament. `NOT_AT_EXTRACTION`
   still shows if raced.

9. **Reconnect re-renders (R105/R107).** Relaunch a client mid-lobby and mid-field;
   `STATE_RESYNC` re-renders the correct space (Collegium or site) with every
   present body placed where the server has them.

10. **No horizontal drift / clean teardown.** No GDScript errors in
    `get_debug_output` across the walk; `stop_project` leaves no orphan process.
