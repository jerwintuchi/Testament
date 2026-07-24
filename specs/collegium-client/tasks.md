# Tasks — Collegium Client (Walkable Spaces) v1

> T# numbering continues from T114. Client-only (GDScript). Verified by the
> MCP-driven `playtest.md` items each task names (no GDScript unit harness — prior
> client-spec convention). Order is dependency order. Server + shared are already
> complete and green; no changes there.

> **AUDITED 2026-07-24 (TD-074).** T115–T120 were shipped under TD-038 and had simply never been
> ticked — `tools/spec_status.py` flagged them **LIKELY-SHIPPED** (their named files all exist),
> and a read of the live code confirmed each one. Verified against:
> `client/scripts/world/space_view.gd` (`class_name SpaceView`, `set_space`, `grid_size_px`,
> `_draw`) for T115; `_bodies` / `_apply_positions(positions, full)` in `main.gd` for T116;
> `_send_move_intent` + `_last_intent` edge-triggering + `_walkable()` for T117; `_render_space()`
> + `_phase()` for T118; `STATION_RADIUS` / `_update_stations` / `_nearest_station` for T119;
> `EXTRACTION_RADIUS` + the FIELD branch for T120. The `--lobby-preview` capture shows the whole
> thing running: walkable Collegium, three named station markers, a body, camera follow.
>
> **Two task descriptions are superseded and were NOT re-implemented to match:** T118's "reflow
> the roster/ready/requisition `_root` into a compact overlay" and T119's "overlay shows Accept /
> requisition panel / Deploy only in range" both describe an inline overlay that TD-071's **room
> scroll** and the **E-to-open station popup** replaced. The requirement each served (R105, R106)
> still holds; only the presentation changed.
>
> **T121 remains genuinely open** — it needs two clients, which the capture harness cannot drive.

- [x] T115 [R102 / P53] — `client/space_view.gd` (`class_name SpaceView extends
      Node2D`): `set_space(grid, markers)` + `grid_size_px()`; `_draw()` renders
      floor/solid tiles (Nearest filter) and a labeled glyph per marker at tile
      center. Add `WorldRoot` + `SpaceView` + `Camera2D` + `Bodies` under `Main`
      in `main.gd` `_ready` (world layer beneath the existing UI `CanvasLayer`).
      Verify: playtest item 1 (Collegium grid + three station glyphs render;
      `phase=WAITING grid=24x16` logged). SpaceView holds no net/protocol ref.

- [x] T116 [R103 / P55] — Bodies: `_bodies` map, `_spawn_body`, `_apply_positions(
      positions, full)` (create/move; prune only on `full`), per-body lerp toward
      `target` in `_process`, local body distinct (ring vs disc), name labels.
      Camera follows the local body, clamped to `grid_size_px()`.
      Verify: playtest items 1 (`bodies=1` at spawn) + 4 (two distinct bodies;
      `POSITIONS` delta moves only the named body).

- [x] T117 [R104 / P54, P57] — Input loop in `main.gd` `_process`: arrow (`ui_*`)
      intent → `MOVE { dx, dy }` on edges only, `{0,0}` once on release, gated to
      walkable phases (`_walkable()`), never touching a body. `_reset_intent_if_
      needed()` on leaving a walkable phase. Log each `MOVE` edge.
      Verify: playtest items 2 (one edge per press/release, body slides, wall
      stops it) + 3 (server silent → `MOVE` logs but body does not move).

- [x] T118 [R105] — Phase router: `_render_space()` + `_world_visible()`; wire
      `ROOM_CREATED` / `LOBBY_UPDATED` (WAITING) / `ROOM_DEPLOYING` to render the
      Collegium and `_apply_positions(snapshot.positions, true)`; reflow the
      roster/ready/requisition `_root` into a compact overlay so the map shows
      behind it; `STATE_RESYNC` (WAITING/DEPLOYING) re-renders. Log `phase=… grid=…`.
      Verify: playtest items 1, 6 (Collegium persists through DEPLOYING), 9
      (lobby reconnect re-renders + places bodies).

- [x] T119 [R106 / P56] — Proximity affordances for the Collegium: `_within(center,
      radius)` off the local body's server position; overlay shows Accept
      (CONTRACT_BOARD, leader) / requisition panel (QUARTERMASTER) / Deploy
      (DEPLOY_GATE, leader) only in range, else a station hint; log `at <KIND>` /
      `left <KIND>` transitions. `NOT_AT_*` still surfaces via `LOBBY_ERROR`.
      Verify: playtest items 5 (board gating + accept) + 6 (quartermaster +
      deploy gate).

- [x] T120 [R107 / P56] — Field walkability: on `FIELD_STARTED` store `site` and
      `_apply_positions(positions, true)`; `_render_space()` FIELD branch renders
      `site.grid` + `site.nodes`; Extract affordance gated within
      `EXTRACTION_RADIUS` of the EXTRACTION node; `STATE_RESYNC.fieldSnapshot`
      re-renders the site + positions. Keep signs/probe/exposure overlay.
      Verify: playtest items 7 (field renders + walk) + 8 (extraction gating +
      extract) + 9 (field reconnect).

- [ ] T121 [R102–R108] — Full end-to-end MCP playtest pass: run the complete
      `playtest.md` (all 10 items) via `run_project` + `get_debug_output` against
      `pnpm dev:server`, two clients for the multi-body items; fix any GDScript
      errors surfaced; confirm clean `stop_project` (item 10). Mark the spec
      complete only when every item passes.
      Verify: `playtest.md` items 1–10 all green; no errors in `get_debug_output`.
