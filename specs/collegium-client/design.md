# Design — Collegium Client (Walkable Spaces) v1

> Satisfies R102–R108. One reusable `SpaceView` renders both the Collegium (lobby
> phases) and the field (FIELD), driven entirely by server data. `main.gd` gains a
> world layer beneath its existing UI, a phase router that feeds `SpaceView` the
> right layout, an input loop that emits `MOVE` intent on edges, and
> proximity-gated action affordances that mirror the server's `NOT_AT_*` gates.
> No server or shared changes.

> **Revision (2026-07-05) — authored scenes/nodes, not `_draw` shapes.** The world
> is built from real Godot scenes and nodes on the sanctioned toolchain
> (TileMap autotiles; scenes), not immediate-mode `_draw`. Concretely: tiles are a
> **`TileMapLayer`** driven by a greybox **`TileSet`** (atlas from a Python
> generator, `client/assets/gen_greybox_tiles.py` → `tiles.png`); the player body
> and station/node markers are **instanced scenes** (`body.tscn`, `marker.tscn`)
> built from `Polygon2D` + `Label` (vector, no texture); the world tree lives in
> **`scenes/main.tscn`** as authored nodes, not created in `_ready`. The workspace
> is foldered: `scenes/`, `scripts/`, `assets/`, `protocol/` (generated, in place).
> This supersedes the "nodes created in `_ready`" and "`_draw` rects/discs" wording
> below; the responsibilities (R102–R108, P53–P57) are unchanged — only the
> rendering substrate is now scenes/nodes. Authored Aseprite/PIL sources replace
> the greybox generator later (art task).

---

## Node architecture

`main.gd` (`Node2D`) today builds only a `CanvasLayer` UI. Add a world beneath it:

```
Main (Node2D)
├─ WorldRoot (Node2D)              # the walkable space; z below the UI layer
│  ├─ SpaceView (Node2D)           # tiles + marker glyphs (res://space_view.gd)
│  ├─ Bodies (Node2D)              # one child per playerId (created/updated/freed)
│  └─ Camera2D                     # follows the local body, clamped to grid bounds
└─ CanvasLayer (existing)          # menus, roster/ready/requisition/probe, status,
                                   #   and the contextual station/extraction prompt
```

The UI stays a `CanvasLayer` (screen-space, unaffected by the camera). The world
renders in world-space under it. Menus (MENU/RECONNECTING/TESTAMENT) hide
`WorldRoot`; walkable phases show it.

### `space_view.gd` — `class_name SpaceView extends Node2D` (render-only, R102)

Pure render surface. No net, no protocol, no phase enum.

```gdscript
const TILE := 16                    # mirrors shared TILE_SIZE (kept local; render constant)
const SOLID := "#"                  # mirrors TILE_SOLID / TILE_FLOOR

var _grid: Dictionary = {}          # { width, height, rows }
var _markers: Array = []            # [{ kind, x, y }] in tile coords

func set_space(grid: Dictionary, markers: Array) -> void   # store + queue_redraw()
func grid_size_px() -> Vector2                              # width*TILE, height*TILE (camera clamp)

func _draw() -> void:
    # floor vs solid: two flat colors (greybox). Border/solid darker.
    # each marker: a glyph rect + its kind label at tile center (x*TILE+8, y*TILE+8).
```

Tiles and glyphs are flat Godot-drawn rects/labels (functional greybox, R102
note). `texture_filter = TEXTURE_FILTER_NEAREST` on the node; the camera zoom is
an integer so the greybox already reads as pixel-scale. Authored tilesets are a
later art task — `set_space` is the seam they will slot into.

### Bodies (R103)

`main.gd` owns `_bodies: Dictionary` (`playerId -> Node2D`). A body is a small
`Node2D` drawing a filled disc (teammate) or a ringed disc (local self), tinted;
a name label sits above it.

```gdscript
func _apply_positions(positions: Dictionary, full: bool) -> void:
    for pid in positions:                       # create-or-move (feet px)
        var b := _bodies.get(pid, null)
        if b == null: b = _spawn_body(pid); _bodies[pid] = b
        b.target = Vector2(positions[pid]["x"], positions[pid]["y"])
    if full:                                     # full sync also *removes* absentees
        for pid in _bodies.keys():
            if not positions.has(pid): _bodies[pid].queue_free(); _bodies.erase(pid)
```

- **Full sync** (`full = true`): `LobbySnapshot.positions`, `FIELD_STARTED.positions`,
  `STATE_RESYNC` — authoritative full set, so it also prunes bodies that left.
- **Delta** (`full = false`): `POSITIONS` — moves only named players, never prunes
  (mirrors server delta discipline, I6).

Each body lerps its drawn position toward `target` in `_process` (pure visual
smoothing over the 20 Hz stream). `target` is *only ever* set from a server
position — never from local input (R104/R108). The local body is `_bodies[_self_id]`.

### Camera (R103)

`Camera2D` follows `_bodies[_self_id]` (position copied each frame), clamped so the
view never leaves `SpaceView.grid_size_px()`. Zoom is a fixed integer (2×: the
960×540 window over a 480×270 art frame) with `TEXTURE_FILTER_NEAREST`. The
Collegium (384×256) fits inside one frame; larger field sites scroll. (The strict
480×270 SubViewport pipeline is deferred; an integer-zoom camera is the v1 seam.)

## Input → MOVE (R104) — in `main.gd`

A `_process(delta)` loop (main.gd currently has none; net.gd polls separately):

```gdscript
var _last_intent := Vector2i(0, 0)

func _process(_dt):
    _tick_bodies()                     # lerp bodies toward server targets
    _follow_camera()
    if not _walkable(): _reset_intent_if_needed(); return
    var v := Vector2i(
        int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left")),
        int(Input.is_action_pressed("ui_down"))  - int(Input.is_action_pressed("ui_up")))
    if v != _last_intent:              # edge only — not every frame
        _last_intent = v
        _net.send_message(Protocol.MOVE, { "dx": v.x, "dy": v.y })
        _log("MOVE dx=%d dy=%d" % [v.x, v.y])
```

- `_walkable()` = a room exists and `phase in {WAITING, DEPLOYING, FIELD}`.
- Raw `{-1,0,1}` sent; server normalizes the diagonal. Input never touches a body
  (R104 AC3 / R108): the local body only moves when `POSITIONS` arrives.
- `_reset_intent_if_needed()`: on leaving a walkable phase with a nonzero intent,
  send one `{0,0}` and clear `_last_intent`, so a stored server intent can't drift
  the body after the player stopped steering.
- Uses the built-in `ui_*` actions (WASD can be added to the input map in a task);
  no new project settings required for arrows.

## Phase router — `main.gd` message handlers

The existing `_show_*` screens stay, but WAITING/DEPLOYING/FIELD now *also* drive
the world. A small `_render_space()` centralizes it:

```gdscript
func _render_space() -> void:
    match _phase():
        WAITING, DEPLOYING:
            var c: Dictionary = _snapshot["collegium"]
            _space.set_space(c["grid"], c["stations"])
            _apply_positions(_snapshot["positions"], true)
            _world_visible(true)
        FIELD:
            _space.set_space(_field_site["grid"], _field_site["nodes"])
            # positions applied from FIELD_STARTED / STATE_RESYNC at ingest
            _world_visible(true)
        _: _world_visible(false)
```

Wire-in points (evolving existing handlers, R105/R107):
- `ROOM_CREATED`, `LOBBY_UPDATED` (WAITING), `ROOM_DEPLOYING`: after updating
  `_snapshot`, call `_render_space()`; `_apply_positions(snapshot.positions, true)`.
- `FIELD_STARTED`: store `_field_site = payload["site"]`; `_apply_positions(
  payload["positions"], true)`; `_render_space()`.
- `POSITIONS`: `_apply_positions(payload["positions"], false)` (delta; no reprune).
- `STATE_RESYNC`: WAITING/DEPLOYING → collegium branch; `fieldSnapshot != null` →
  store its site + `_apply_positions(fieldSnapshot.positions, true)`.
  *(Requires `fieldSnapshot` to carry `site`; it already does — `FieldSnapshot`
  ships `site` + `positions`, R98/R85.)*

The roster/ready/requisition/probe controls move into a compact overlay panel so
the map is visible behind them (the existing `_root` VBox becomes a side/corner
panel rather than full-bleed). No control logic changes — only placement.

## Proximity affordances (R106/R107)

A pure helper mirrors the server's `withinRadius`:

```gdscript
func _within(marker_center_px: Vector2, radius: float) -> bool:
    return _self_body_pos().distance_to(marker_center_px) <= radius
```

`_self_body_pos()` reads the local body's server `target` (feet px) — server truth,
not an integrated guess. Marker center px = `Vector2(x*16+8, y*16+8)`.

The overlay shows exactly one contextual prompt for the phase:
- WAITING near `CONTRACT_BOARD` (leader) → **Accept Contract** button → `ACCEPT_CONTRACT`.
- DEPLOYING near `QUARTERMASTER` → the requisition checklist + **Requisition** →
  `REQUISITION`. Near `DEPLOY_GATE` (leader) → **Deploy** → `DEPLOY`.
- FIELD near `EXTRACTION` → **Extract** → `EXTRACT`.
- Otherwise → a greyed hint: "Walk to the Contract Board / Quartermaster / Deploy
  Gate / Extraction." The affordance recomputes each frame from the local body's
  moving position (cheap; it is just a distance check).

This is UX only: the buttons still send the same intents, and `NOT_AT_*` from the
server still renders (R106/R107 AC2) — belt and suspenders, never a replacement
for the gate (R108).

## Logging for observability (Verification)

The client `print()`s load-bearing transitions so the MCP `get_debug_output` can
assert them: `MOVE dx dy` on each edge; `bodies=N` after each `_apply_positions`;
`phase=… grid=WxH` on each `_render_space`; `at CONTRACT_BOARD` / `left
CONTRACT_BOARD` (and the other markers) on each within-transition. These are the
playtest's machine-readable checkpoints.

## Correctness Properties

- **P53 (render-only view, R102):** `SpaceView` has no net/protocol/phase
  references; it renders `set_space` inputs and emits nothing.
- **P54 (client movement authority, R104/R108):** no code path moves a body from
  input; a body's `target` is assigned only inside `_apply_positions`, whose only
  callers are server-message handlers.
- **P55 (delta discipline mirrored, R103):** `POSITIONS` updates only named bodies
  and never prunes; only a full sync prunes.
- **P56 (affordance ≠ authority, R106/R107):** every station/extraction action is
  still sent to and validated by the server; hiding a button never grants one, and
  a raced `NOT_AT_*` still surfaces.
- **P57 (walkable-phase input, R104):** `MOVE` is emitted only when a room exists
  and the phase is WAITING/DEPLOYING/FIELD.

## Wire Protocol Summary

No new messages. Consumed: `LobbySnapshot.collegium` + `.positions` (render the
hall), `FIELD_STARTED.site` + `.positions` and `STATE_RESYNC.fieldSnapshot.site`
(render the field), `POSITIONS` (deltas). Sent: `MOVE { dx, dy }` on intent edges;
existing `ACCEPT_CONTRACT` / `REQUISITION` / `DEPLOY` / `PROBE` / `EXTRACT`
unchanged, now offered contextually. `NOT_AT_*` errors already flow through
`LOBBY_ERROR` into the status line.
