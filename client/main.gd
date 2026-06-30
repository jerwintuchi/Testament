extends Node2D
## Testament — Phase 1 transport spike client.
##
## Connects to the authoritative server over raw WebSocket, auto-creates a room,
## auto-starts a run, renders the dungeon, and moves a Seeker with the arrow keys.
## Positions are authoritative: the client sends a direction; the server replies with
## PLAYER_MOVED. Render + input only, zero game logic (the trust boundary).

# The wire-protocol contract, codegen'd from src/shared (pnpm gen:protocol). The
# server references the same names, so message types and shared scalars never drift.
const Protocol = preload("res://protocol/protocol.gd")

const SERVER_URL := "ws://localhost:3001"
# Corridor half-width and design view height are shared with the server, so they are
# read from the generated Protocol constants (client/protocol/protocol.gd, codegen'd
# from src/shared) rather than hand-duplicated here.
# How fast the rendered position eases toward the latest authoritative one. The
# server broadcasts positions at 20Hz; this smooths those discrete snapshots into
# continuous motion without the client ever owning game state (the trust boundary).
const INTERP_RATE := 35.0

var _socket := WebSocketPeer.new()
var _player_id := ""
var _opened := false
var _run_started := false
var _last_dir := Vector2.ZERO

var _rooms: Array = []        # Array[Rect2]
var _corridors: Array = []    # Array[{from: Vector2, to: Vector2}]
var _target: Dictionary = {}  # player_id -> Vector2 (latest authoritative position)
var _render: Dictionary = {}  # player_id -> Vector2 (smoothed position actually drawn)

var _camera: Camera2D
var _status: Label

func _ready() -> void:
	_player_id = "seeker-%d" % (randi() % 100000)

	_camera = Camera2D.new()
	add_child(_camera)
	_camera.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	_status = Label.new()
	_status.position = Vector2(8, 8)
	layer.add_child(_status)

	var url := "%s/?playerId=%s" % [SERVER_URL, _player_id]
	var err := _socket.connect_to_url(url)
	if err != OK:
		push_error("Testament client: connect_to_url failed (%d). Is the server running on :3001?" % err)

func _process(delta: float) -> void:
	_socket.poll()
	var state := _socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not _opened:
				_opened = true
				_send(Protocol.CREATE_ROOM, null)
			while _socket.get_available_packet_count() > 0:
				_handle_message(_socket.get_packet().get_string_from_utf8())
			_send_input()
		WebSocketPeer.STATE_CLOSED:
			if _opened:
				_opened = false
				push_warning("Testament client: connection closed.")

	_interpolate(delta)
	_update_camera()
	_update_status(state)
	queue_redraw()

func _send(type: String, payload: Variant) -> void:
	_socket.send_text(JSON.stringify({"type": type, "payload": payload}))

func _send_input() -> void:
	if not _run_started:
		return
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir != _last_dir:
		_last_dir = dir
		_send(Protocol.MOVE_PLAYER, {"dx": dir.x, "dy": dir.y})

func _handle_message(text: String) -> void:
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY or not data.has("type"):
		return
	var type: String = data["type"]
	var payload: Variant = data.get("payload")
	match type:
		Protocol.ROOM_UPDATE:
			# Fresh room created; auto-start the run (transport spike).
			if not _run_started:
				_send(Protocol.START_RUN, null)
		Protocol.RUN_STARTED:
			_ingest_dungeon(payload["dungeon"])
			var positions: Dictionary = payload["playerPositions"]
			for pid in positions:
				var p: Dictionary = positions[pid]
				var pos := Vector2(p["x"], p["y"])
				_target[pid] = pos
				_render[pid] = pos  # snap on first sight, then interpolate
			_run_started = true
		Protocol.PLAYER_MOVED:
			_target[payload["playerId"]] = Vector2(payload["x"], payload["y"])
		Protocol.LOBBY_ERROR:
			push_warning("Testament LOBBY_ERROR: %s" % str(payload))

func _ingest_dungeon(dungeon: Dictionary) -> void:
	_rooms.clear()
	for room in dungeon["rooms"]:
		var r: Dictionary = room["rect"]
		_rooms.append(Rect2(r["x"], r["y"], r["width"], r["height"]))
	_corridors.clear()
	for c in dungeon["corridors"]:
		_corridors.append({
			"from": Vector2(c["from"]["x"], c["from"]["y"]),
			"to": Vector2(c["to"]["x"], c["to"]["y"]),
		})

# Ease each rendered position toward its authoritative target. The exp() form is
# frame-rate independent: the same smoothing whether we run at 60 or 144 FPS.
func _interpolate(delta: float) -> void:
	var t := 1.0 - exp(-INTERP_RATE * delta)
	for pid in _target:
		var goal: Vector2 = _target[pid]
		if _render.has(pid):
			_render[pid] = (_render[pid] as Vector2).lerp(goal, t)
		else:
			_render[pid] = goal

func _update_camera() -> void:
	var vh := get_viewport_rect().size.y
	var z := vh / float(Protocol.DESIGN_VIEW_HEIGHT)
	_camera.zoom = Vector2(z, z)
	if _render.has(_player_id):
		_camera.global_position = _render[_player_id]

func _update_status(state: int) -> void:
	var label := "connecting..."
	match state:
		WebSocketPeer.STATE_OPEN:
			label = "connected as %s" % _player_id
			if _run_started:
				label += "  |  in run  |  seekers: %d  |  arrow keys to move" % _target.size()
		WebSocketPeer.STATE_CLOSED:
			label = "server offline (start it: pnpm dev:server on :3001)"
	_status.text = "Testament  —  %s" % label

func _draw() -> void:
	var floor_col := Color(0.16, 0.14, 0.19)
	var edge_col := Color(0.42, 0.36, 0.48)
	# Corridors first (drawn beneath the rooms).
	for c in _corridors:
		_draw_corridor(c["from"], c["to"], floor_col)
	for rect in _rooms:
		draw_rect(rect, floor_col, true)
		draw_rect(rect, edge_col, false, 2.0)
	# Seekers: the local one gold, others blue.
	for pid in _render:
		var pos: Vector2 = _render[pid]
		var col := Color(0.88, 0.76, 0.45) if pid == _player_id else Color(0.5, 0.62, 0.88)
		draw_circle(pos, 12.0, col)

func _draw_corridor(from: Vector2, to: Vector2, col: Color) -> void:
	var hw := float(Protocol.CORRIDOR_HALF_WIDTH)
	# L-shaped: a horizontal leg at from.y, then a vertical leg at to.x.
	var x0 := minf(from.x, to.x)
	var x1 := maxf(from.x, to.x)
	draw_rect(Rect2(x0 - hw, from.y - hw, (x1 - x0) + 2.0 * hw, 2.0 * hw), col, true)
	var y0 := minf(from.y, to.y)
	var y1 := maxf(from.y, to.y)
	draw_rect(Rect2(to.x - hw, y0 - hw, 2.0 * hw, (y1 - y0) + 2.0 * hw), col, true)
