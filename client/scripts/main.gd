extends Node2D
## Testament client — the Phase 4 protocol walk: lobby → requisition → field → probe.
##
## Render + input only (trust boundary): every screen transition is caused by a
## server event; user input only ever *sends* an intention. All session state
## below is a render copy of what the server said, never locally derived.

enum Screen { MENU, LOBBY, DEPLOYING, FIELD, TESTAMENT, RECONNECTING }

# The wire-protocol contract, codegen'd from src/shared (pnpm gen:protocol). The
# server references the same names, so message types, error codes, phases, and the
# gear catalog never drift (TD-029/TD-030: preload, not a global class_name).
const Protocol = preload("res://protocol/protocol.gd")
const ThreatPips = preload("res://scripts/ui/threat_pips.gd")

const SERVER_URL := "ws://localhost:3001"
# The reconnect token survives a client relaunch (R75). It is an opaque server
# secret, not game state — the one thing the client is allowed to remember.
const TOKEN_PATH := "user://reconnect-token.txt"

var _net: NetClient
var _screen: Screen = Screen.MENU

# ── Server-derived session state ─────────────────────────────────────────────
var _self_id := ""
var _reconnect_token := ""
var _snapshot: Dictionary = {}    # last LobbySnapshot
var _field: Dictionary = {}       # StubFieldData
var _channels: Array = []         # own perceived channels (never other players')
var _signs: Array = []            # [{channel, token}] — the only Incarnate info that exists client-side
var _probe_log: Array = []        # display strings, newest last
var _exposure := 0
var _testament: Dictionary = {}
var _archive: Array = []

# ── Client-only UI state ─────────────────────────────────────────────────────
var _selected_items: Array = []   # requisition picks before sending
var _pending_join := false        # sent CREATE/JOIN, awaiting the server's verdict
var _awaiting_resume := false     # sent RECONNECT, awaiting STATE_RESYNC or an error

# ── UI shell ─────────────────────────────────────────────────────────────────
var _root: VBoxContainer
var _status: Label
var _name_input: LineEdit
var _code_input: LineEdit

# ── Walkable world (a render copy of server positions; never client-derived) ──
# The world is an authored node tree (scenes/main.tscn) rendered beneath the UI
# CanvasLayer. Bodies move only when the server reports a position (R104/R108);
# input only ever *sends* a MOVE intent.
const BODY := preload("res://scenes/player.tscn")
@onready var _world: Node2D = $World
@onready var _space: SpaceView = $World/SpaceView
@onready var _body_root: Node2D = $World/Bodies
@onready var _camera: Camera2D = $World/Camera2D
var _bodies: Dictionary = {}      # playerId -> Player
var _field_site: Dictionary = {}  # SiteLayout (grid + nodes) for the FIELD phase
var _last_intent := Vector2i.ZERO # last MOVE vector sent; we emit only on change
var _last_walk := false           # last walk-modifier (Shift) sent; also edge-triggered

# ── Station interaction (client affordance; server still gates with NOT_AT_*) ─
# Radii mirror @testament/shared (STATION_RADIUS / EXTRACTION_RADIUS). They only
# drive the "Press E" prompt — the server re-validates every station action, so a
# drifted client copy can never grant an action the server would deny (R106/R108).
const TILE := 16
const STATION_RADIUS := 24.0
const EXTRACTION_RADIUS := 32.0
var _active_station := ""         # kind of the station in range, or "" — a render hint
var _menu_open := false           # a station popup is up: movement is locked
var _popup_kind := ""             # the station kind the open popup was built for (for rebuilds)
var _board_selection: Dictionary = {}  # the contract card being previewed, or {} = the grid view
var _wood_sb: StyleBox            # Contract Board panel skin — a wooden board
var _parch_tex: Array = []        # 4 torn parchment card textures (unique tear patterns)
var _popup_tween: Tween           # the open/close animation, tracked so it can be killed on re-entry
var _prompt: Label                # bottom-center "Press E — <Station>"
var _popup_dim: ColorRect         # full-rect input blocker + dimmer behind the popup
var _popup: PanelContainer        # the reusable station menu shell
var _popup_title: Label           # station name (persistent, above the scroll)
var _popup_body: VBoxContainer    # per-station content, rebuilt on open (scrolls)

func _ready() -> void:
	_net = NetClient.new()
	add_child(_net)
	_net.message_received.connect(_on_message)
	_net.socket_opened.connect(_on_socket_opened)
	_net.socket_closed.connect(_on_socket_closed)

	# The walkable world (scenes/main.tscn: World/SpaceView/Bodies/Camera2D) renders
	# beneath the UI CanvasLayer, which is built below. 2× integer zoom (960×540
	# window over a 480×270 frame) is set on the Camera2D in the scene.
	_camera.make_current()

	var layer := CanvasLayer.new()
	add_child(layer)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	layer.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	# Screens can outgrow the window; they scroll while the status line below
	# stays visible (R80 — no more resizing the window to find it).
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	_root = VBoxContainer.new()
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_theme_constant_override("separation", 8)
	scroll.add_child(_root)
	_status = Label.new()
	_status.modulate = Color(0.85, 0.7, 0.5)
	column.add_child(_status)

	# Bottom-center interaction prompt (hidden until near a station).
	_prompt = Label.new()
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -180
	_prompt.offset_right = 180
	_prompt.offset_top = -56
	_prompt.offset_bottom = -32
	_prompt.modulate = Color(1.0, 0.95, 0.72)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	layer.add_child(_prompt)

	# Reusable station popup: a full-rect dimmer that blocks the map/base UI, plus a
	# centered panel whose body is rebuilt per station. Hidden until E.
	_popup_dim = ColorRect.new()
	_popup_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_popup_dim.color = Color(0, 0, 0, 0.55)
	_popup_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup_dim.visible = false
	layer.add_child(_popup_dim)
	# CenterContainer robustly centres the panel regardless of its size.
	# A plain full-rect Control (not a CenterContainer) so the popup's position is
	# ours to animate — we centre it manually and slide it up from the bottom.
	var pcenter := Control.new()
	pcenter.set_anchors_preset(Control.PRESET_FULL_RECT)
	pcenter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_popup_dim.add_child(pcenter)
	_popup = PanelContainer.new()
	_popup.theme = _build_popup_theme()  # 9-slice gothic panel + gold-on-charcoal controls
	# Skins swapped in per station: the Contract Board is a wooden board, its cards
	# pinned parchment. Built once; a missing texture falls back to a flat box.
	_wood_sb = _texture_sb("res://assets/ui/board_wood.png", 16.0, 16.0, Color(0.29, 0.19, 0.10), Color(0.45, 0.30, 0.15))
	for i in 4:
		var t := load("res://assets/ui/parch_card_%d.png" % i) as Texture2D
		if t != null:
			_parch_tex.append(t)
	pcenter.add_child(_popup)
	var ppad := MarginContainer.new()
	for side in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		ppad.add_theme_constant_override(side, 10)
	_popup.add_child(ppad)
	var pcol := VBoxContainer.new()
	pcol.add_theme_constant_override("separation", 8)
	ppad.add_child(pcol)
	_popup_title = Label.new()
	_popup_title.add_theme_font_size_override("font_size", 22)
	_popup_title.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	pcol.add_child(_popup_title)
	# Fixed-size scroll viewport so a long list (Quartermaster) never overruns the
	# window — it scrolls instead.
	var pscroll := ScrollContainer.new()
	pscroll.custom_minimum_size = Vector2(400, 340)
	pscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pcol.add_child(pscroll)
	_popup_body = VBoxContainer.new()
	_popup_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_popup_body.add_theme_constant_override("separation", 8)
	pscroll.add_child(_popup_body)
	var pclose := Button.new()
	pclose.text = "Close  (Esc)"
	pclose.pressed.connect(_close_station)
	pcol.add_child(pclose)

	_reconnect_token = _load_token()
	_net.open(SERVER_URL)
	_show_menu()

# ── Inbound messages (the only source of state) ──────────────────────────────

func _on_message(type: String, payload: Variant) -> void:
	match type:
		Protocol.ROOM_CREATED:
			_snapshot = payload["snapshot"]
			_set_token(payload["reconnectToken"])
			_self_id = _snapshot["players"][0]["playerId"]  # creator is the only player
			_pending_join = false
			_show_lobby()
		Protocol.RECONNECT_TOKEN:
			_set_token(payload["reconnectToken"])
			_self_id = payload["playerId"]
			_pending_join = false
			_show_lobby()
		Protocol.LOBBY_UPDATED:
			_snapshot = payload["snapshot"]
			match _snapshot["phase"]:
				Protocol.PHASE_WAITING:
					# A joiner's first LOBBY_UPDATED precedes its RECONNECT_TOKEN;
					# without _self_id the lobby can't mark "you" yet, so wait.
					if _screen == Screen.LOBBY or (_pending_join and _self_id != ""):
						_show_lobby()
				Protocol.PHASE_DEPLOYING:
					if _screen == Screen.DEPLOYING:
						_show_deploying()  # party bags updated
		Protocol.ROOM_DEPLOYING:
			_snapshot["phase"] = Protocol.PHASE_DEPLOYING
			_snapshot["contract"] = payload["contract"]
			_selected_items = []
			_close_station()   # a phase change invalidates any open station popup
			_show_deploying()
		Protocol.FIELD_STARTED:
			_field = payload["fieldData"]
			_field_site = payload["site"]
			_set_token(payload["reconnectToken"])
			_signs = payload["signs"]
			_channels = payload["perceivedChannels"]
			_probe_log = []
			_exposure = 0
			_snapshot["phase"] = Protocol.PHASE_FIELD
			_apply_positions(payload["positions"], true)
			_close_station()
			_show_field()
		Protocol.POSITIONS:
			# 20 Hz movement delta: move only the named bodies, prune nothing.
			_apply_positions(payload["positions"], false)
		Protocol.PROBE_RESULT:
			_ingest_probe_result(payload)
		Protocol.FIELD_TESTAMENT:
			_testament = payload["testament"]
			_close_station()
			_show_testament()
		Protocol.ARCHIVE_UPDATED:
			_archive = payload["entries"]
			if _screen == Screen.TESTAMENT:
				_show_testament()
		Protocol.STATE_RESYNC:
			_awaiting_resume = false
			_snapshot = payload["snapshot"]
			_set_token(payload["reconnectToken"])
			_self_id = payload["playerId"]  # a relaunched client holds only the token
			var fs: Variant = payload["fieldSnapshot"]
			if fs != null:
				_field = fs["fieldData"]
				_field_site = fs["site"]
				_signs = fs["signs"]
				_channels = fs["perceivedChannels"]
				_archive = fs["archiveEntries"]
				_probe_log = []
				_apply_positions(fs["positions"], true)
				_show_field()
			elif _snapshot["phase"] == Protocol.PHASE_DEPLOYING:
				_show_deploying()
			else:
				_show_lobby()
			_set_status("resynced")
		Protocol.LOBBY_ERROR:
			_pending_join = false
			# A failed resume means the seat is gone (kicked, or the room died):
			# forget the token so the client does not retry a dead seat forever.
			if _awaiting_resume or payload["code"] in [Protocol.ERR_TOKEN_EXPIRED, Protocol.ERR_TOKEN_NOT_FOUND]:
				_set_token("")
			_awaiting_resume = false
			_set_status("✝ %s — %s" % [payload["code"], payload["message"]])
			_log("LOBBY_ERROR %s — %s" % [payload["code"], payload["message"]])

func _ingest_probe_result(payload: Dictionary) -> void:
	_exposure = int(payload["exposure"])
	var who: String = _display_name(payload["playerId"])
	var line: String
	if payload["sign"] != null:
		var sign_data: Dictionary = payload["sign"]
		line = "%s presented %s — [%s] %s" % [who, payload["stimulus"], sign_data["channel"], sign_data["token"]]
		if not _signs.any(func(s): return s["channel"] == sign_data["channel"] and s["token"] == sign_data["token"]):
			_signs.append(sign_data)
	else:
		line = "%s presented %s — you cannot read it" % [who, payload["stimulus"]]
	_probe_log.append(line)
	if _screen == Screen.FIELD:
		_show_field()

# ── Connection lifecycle ─────────────────────────────────────────────────────

func _on_socket_opened() -> void:
	_set_status("connected")
	# Auto-resume only after a live drop. A fresh launch offers a Resume button
	# instead: instances on one machine share the token file, so resuming
	# silently would let a second window hijack the first one's identity.
	if _reconnect_token != "" and _screen == Screen.RECONNECTING:
		_awaiting_resume = true
		_net.send_message(Protocol.RECONNECT, {"token": _reconnect_token})

func _on_socket_closed() -> void:
	if _screen == Screen.MENU or _screen == Screen.TESTAMENT:
		_set_status("server offline — start it with: pnpm dev:server")
	else:
		_show_reconnecting()

# ── Screens ──────────────────────────────────────────────────────────────────

func _show_menu() -> void:
	_screen = Screen.MENU
	_world.visible = false
	_clear()
	_h1("TESTAMENT")
	_label("The Collegium is hiring. We seek truth, not certainty.")
	_name_input = _make_line_edit("display name", "Seeker")
	_button("Create Room", func():
		_pending_join = true
		_net.send_message(Protocol.CREATE_ROOM, {"displayName": _name_input.text}))
	_label("")
	_code_input = _make_line_edit("room code (e.g. ABC234)", "")
	_button("Join Room", func():
		_pending_join = true
		_net.send_message(Protocol.JOIN_ROOM, {"code": _code_input.text.strip_edges().to_upper(), "displayName": _name_input.text}))
	if _reconnect_token != "":
		_label("")
		_button("Resume unfinished expedition", func():
			if _net.is_open():
				_awaiting_resume = true
				_net.send_message(Protocol.RECONNECT, {"token": _reconnect_token})
			else:
				_set_status("still connecting — try again in a moment"))

func _show_lobby() -> void:
	_screen = Screen.LOBBY
	_clear()
	_h1("Lobby — room %s" % _snapshot.get("roomCode", "?"))
	_label("share the code aloud; the Collegium sends up to four")
	for p in _snapshot.get("players", []):
		_party_row(p)
	_label("")
	_button("Toggle Ready", func(): _net.send_message(Protocol.TOGGLE_READY))
	_label("Walk to the Contract Board and press E to accept.")
	_button("Leave Room", func():
		_net.send_message(Protocol.LEAVE_ROOM)
		_reset_session()
		_show_menu())
	_render_space()
	# Initial/authoritative body sync: the lobby snapshot carries everyone's spawn
	# position, so spawn (and prune) bodies here. Without this the local body would
	# not exist until the first POSITIONS delta — i.e. it would only appear once you
	# moved. POSITIONS deltas drive movement after this (full=true also prunes leavers).
	_apply_positions(_snapshot.get("positions", {}), true)

func _show_deploying() -> void:
	_screen = Screen.DEPLOYING
	_clear()
	var c: Dictionary = _snapshot.get("contract") if _snapshot.get("contract") != null else {}
	_h1("Contract — %s" % c.get("targetName", "?"))
	_label("site: %s    tier: %s    verb: %s" % [c.get("siteName", "?"), c.get("tier", "?"), c.get("primaryVerb", "?")])
	_label("")
	_label("Walk to the Quartermaster (E) to requisition, the Deploy Gate (E) to deploy.")
	_label("")
	_h2("Party bags")
	for p in _snapshot.get("players", []):
		_party_row(p)
	_render_space()
	# Same initial/authoritative body sync as the lobby (see _show_lobby): DEPLOYING
	# keeps the Collegium walkable, so keep bodies placed from the snapshot.
	_apply_positions(_snapshot.get("positions", {}), true)

func _show_field() -> void:
	_screen = Screen.FIELD
	_clear()
	_h1("The Field — %s" % _field.get("siteName", "?"))
	_label("target: %s" % _field.get("incarnateName", "?"))
	_label("you perceive: %s" % (", ".join(_channels) if not _channels.is_empty() else "nothing — you packed no perception gear"))
	_label("party exposure: %d" % _exposure)
	_label("")
	_h2("Signs you can read")
	if _signs.is_empty():
		_label("(nothing yet — observe, then probe)")
	for s in _signs:
		_label("[%s]  %s" % [s["channel"], s["token"]])
	_label("")
	_h2("Probe (needs the matching kit)")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)
	for stim in Catalog.STIMULI:
		var b := Button.new()
		b.text = "Present %s" % stim
		b.pressed.connect(func(): _net.send_message(Protocol.PROBE, {"stimulus": stim}))
		row.add_child(b)
	for line in _probe_log:
		_label(line)
	_label("")
	_label("Walk to the Extraction and press E to leave.")
	_render_space()

func _show_testament() -> void:
	_screen = Screen.TESTAMENT
	_world.visible = false
	_clear()
	_h1("Field Testament")
	_label("outcome: %s" % _testament.get("outcome", "?"))
	_label("expedition: %s" % _testament.get("expeditionId", "?"))
	_label("")
	_h2("The Archive")
	for e in _archive:
		_label("%s at %s — %s: %s" % [e.get("targetName", "?"), e.get("siteName", "?"), e.get("outcome", "?"), e.get("notes", "")])
	_label("")
	_button("Return to the Collegium", func():
		_reset_session()
		_show_menu())

func _show_reconnecting() -> void:
	_screen = Screen.RECONNECTING
	_world.visible = false
	_clear()
	_h1("Connection lost")
	if _reconnect_token == "":
		_label("No expedition to return to.")
		_button("Back to menu", func():
			_reset_session()
			_show_menu())
	else:
		_label("Your party holds your place. Reconnect to resume.")
		_button("Reconnect", func():
			_set_status("reconnecting...")
			_net.open(SERVER_URL))
		_button("Abandon (back to menu)", func():
			_reset_session()
			_show_menu()
			_net.open(SERVER_URL))

# ── Walkable world ───────────────────────────────────────────────────────────
# The client renders server truth and sends only intents. A body moves only when
# a server position arrives (never from input); station proximity is a display
# affordance, never an authorization (R104/R106/R108).

func _process(_delta: float) -> void:
	_follow_camera()
	_update_stations()
	_send_move_intent()

# Interaction: E opens the station in range, Esc closes an open popup. Discrete
# key edges (not held), read by physical location.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_E and _active_station != "" and not _menu_open:
		_open_station(_active_station)
		get_viewport().set_input_as_handled()
	elif event.physical_keycode == KEY_ESCAPE and _menu_open:
		_close_station()
		get_viewport().set_input_as_handled()

# Pick the space for the current phase and hand it to the render-only SpaceView.
# Renders the grid + markers only — positions are applied by the position-bearing
# handlers (initial sync, POSITIONS deltas, field spawn, resync), never re-snapped
# on a cosmetic rebuild (that would clobber live movement with a stale snapshot).
func _render_space() -> void:
	match _phase():
		Protocol.PHASE_WAITING, Protocol.PHASE_DEPLOYING:
			var c: Variant = _snapshot.get("collegium")
			if c == null:
				_world.visible = false
				return
			_space.set_space(c["grid"], c["stations"])
			_world.visible = true
			_log("phase=%s grid=%dx%d" % [_phase(), int(c["grid"]["width"]), int(c["grid"]["height"])])
		Protocol.PHASE_FIELD:
			if _field_site.is_empty():
				_world.visible = false
				return
			_space.set_space(_field_site["grid"], _field_site["nodes"])
			_world.visible = true
			_log("phase=FIELD grid=%dx%d" % [int(_field_site["grid"]["width"]), int(_field_site["grid"]["height"])])
		_:
			_world.visible = false

# Create/move a body per playerId at its feet px. `full` (a snapshot/resync full
# set) also prunes bodies no longer present; a `false` POSITIONS delta never
# prunes and touches only named players (mirrors server delta discipline, I6).
func _apply_positions(positions: Dictionary, full: bool) -> void:
	var before := _bodies.size()
	for pid in positions:
		var p: Dictionary = positions[pid]
		var feet := Vector2(float(p["x"]), float(p["y"]))
		var b: Player = _bodies.get(pid)
		if b == null:
			b = BODY.instantiate()
			_body_root.add_child(b)
			b.setup(feet, pid == _self_id, _display_name_plain(pid))
			_bodies[pid] = b
		else:
			b.target = feet
			b.is_self = (pid == _self_id)
	if full:
		for pid in _bodies.keys():
			if not positions.has(pid):
				_bodies[pid].queue_free()
				_bodies.erase(pid)
	if _bodies.size() != before:   # only on a real join/leave, not every 20 Hz delta
		_log("bodies=%d" % _bodies.size())

func _clear_bodies() -> void:
	for b in _bodies.values():
		b.queue_free()
	_bodies.clear()

func _phase() -> String:
	return str(_snapshot.get("phase", ""))

# A body to steer exists only in a walkable phase with a rendered world.
func _walkable() -> bool:
	if not _world.visible:
		return false
	var ph := _phase()
	return ph == Protocol.PHASE_WAITING or ph == Protocol.PHASE_DEPLOYING or ph == Protocol.PHASE_FIELD

# Emit MOVE only on an intent *edge* (a key down/up), plus one {0,0} when leaving
# a walkable phase — the server keeps applying the last intent each tick, so
# resending every frame would be noise. Raw {-1,0,1}; the server normalizes.
func _send_move_intent() -> void:
	if not _walkable() or _menu_open:   # a menu open freezes the Seeker in place
		if _last_intent != Vector2i.ZERO:
			_net.send_message(Protocol.MOVE, {"dx": 0, "dy": 0})
			_last_intent = Vector2i.ZERO
		return
	var v := Vector2i(
		_dir_axis(KEY_D, KEY_RIGHT, KEY_A, KEY_LEFT),
		_dir_axis(KEY_S, KEY_DOWN, KEY_W, KEY_UP))
	# Default is run; holding Shift asks the server for the slower walk register.
	# The walk flag only matters while moving, so a shift toggle when standing
	# still (v == 0) does not spam an edge — the next real move sends the current
	# state. Speed itself is the server's decision (I1); this only sends intent.
	var walk := Input.is_physical_key_pressed(KEY_SHIFT)
	var moving := v != Vector2i.ZERO
	if v != _last_intent or (moving and walk != _last_walk):
		_last_intent = v
		_last_walk = walk
		_net.send_message(Protocol.MOVE, {"dx": v.x, "dy": v.y, "walk": walk})
		_log("MOVE dx=%d dy=%d walk=%s" % [v.x, v.y, walk])

# WASD (primary) or arrow keys, read by *physical* location so it's layout-agnostic.
func _dir_axis(pos_a: Key, pos_b: Key, neg_a: Key, neg_b: Key) -> int:
	var pos := Input.is_physical_key_pressed(pos_a) or Input.is_physical_key_pressed(pos_b)
	var neg := Input.is_physical_key_pressed(neg_a) or Input.is_physical_key_pressed(neg_b)
	return int(pos) - int(neg)

# ── Stations ─────────────────────────────────────────────────────────────────
# The prompt/popup are pure client affordances off the server-given position; the
# station action is still an intent the server re-validates (NOT_AT_*), R106/R108.

const _STATION_LABEL := {
	"CONTRACT_BOARD": "Contract Board", "QUARTERMASTER": "Quartermaster",
	"DEPLOY_GATE": "Deploy Gate", "EXTRACTION": "Extraction",
}

# Flavored charges per primary verb — a client-side rephrase of the server's verb
# so a card reads like scribed intent, not "VERB: BANISH". Seeded by contractId.
const VERB_FLAVOR := {
	"INVESTIGATE": [
		"Study it, and return with what you learn — not its head.",
		"Observe and survive; we want understanding, not a corpse.",
		"Read the thing well. Do not engage beyond need.",
	],
	"ELIMINATE": [
		"Put it down, and see that it stays down.",
		"End the thing. Leave nothing behind to rise.",
		"Silence it, by whatever holy means remain.",
	],
	"CAPTURE": [
		"Take it alive, and take it whole.",
		"Bind it, and deliver it breathing.",
		"Subdue the thing; do not slay it.",
	],
	"BANISH": [
		"Send it back by the proper rite.",
		"Unmake it with liturgy, not steel alone.",
		"Return it to whatever dark it crawled from.",
	],
}

func _update_stations() -> void:
	if _menu_open:
		_prompt.visible = false
		return
	_active_station = _nearest_station()
	_prompt.visible = _active_station != ""
	if _prompt.visible:
		_prompt.text = "Press E — %s" % _STATION_LABEL.get(_active_station, _active_station)

# Kind of the station whose centre the local body stands within, else "". Reads
# the local body's server target (feet px), never an integrated guess.
func _nearest_station() -> String:
	if not _world.visible:
		return ""
	var me: Variant = _self_pos()
	if me == null:
		return ""
	var ph := _phase()
	if ph == Protocol.PHASE_WAITING or ph == Protocol.PHASE_DEPLOYING:
		var c: Variant = _snapshot.get("collegium")
		if c == null:
			return ""
		for s in c["stations"]:
			if me.distance_to(_center_px(s["x"], s["y"])) <= STATION_RADIUS:
				return str(s["kind"])
	elif ph == Protocol.PHASE_FIELD and not _field_site.is_empty():
		for n in _field_site["nodes"]:
			if str(n["kind"]) == "EXTRACTION" and me.distance_to(_center_px(n["x"], n["y"])) <= EXTRACTION_RADIUS:
				return "EXTRACTION"
	return ""

func _self_pos() -> Variant:
	var b: Player = _bodies.get(_self_id)
	if b == null:
		return null
	return b.target

func _center_px(tx: int, ty: int) -> Vector2:
	return Vector2(tx * TILE + TILE * 0.5, ty * TILE + TILE * 0.5)

func _open_station(kind: String) -> void:
	_menu_open = true
	_popup_kind = kind
	_board_selection = {}          # a fresh open starts on the board grid, not a detail
	_prompt.visible = false
	_popup_title.text = _STATION_LABEL.get(kind, kind)
	# The Contract Board wears a wooden-board skin; every other station keeps the
	# default gothic-stone panel from the theme.
	if kind == "CONTRACT_BOARD" and _wood_sb != null:
		_popup.add_theme_stylebox_override("panel", _wood_sb)
	else:
		_popup.remove_theme_stylebox_override("panel")
	_clear_popup_body()
	_build_station_content(kind)
	_animate_body_in()
	_slide_popup_in()

# Slide the popup up from just below the screen to centre, backdrop fading in with
# it. Relatively quick (~0.3s, cubic ease-out). The await lets the PanelContainer
# compute its size so we can centre it; killing any in-flight tween keeps it
# re-entrant against a fast close→open.
func _slide_popup_in() -> void:
	if _popup_tween != null:
		_popup_tween.kill()
	_popup_dim.modulate.a = 0.0
	_popup_dim.visible = true
	await get_tree().process_frame
	if not _popup_dim.visible:            # closed during the wait
		return
	var vp := get_viewport_rect().size
	var target := ((vp - _popup.size) * 0.5).floor()
	_popup.position = Vector2(target.x, vp.y + 16.0)   # start off the bottom edge
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.tween_property(_popup_dim, "modulate:a", 1.0, 0.22).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_popup, "position", target, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _close_station() -> void:
	_menu_open = false
	_popup_kind = ""
	_board_selection = {}
	if not _popup_dim.visible:
		return
	if _popup_tween != null:
		_popup_tween.kill()
	# Drop back down a little and fade out, then hide + clear.
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.tween_property(_popup_dim, "modulate:a", 0.0, 0.16).set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(_popup, "position:y", _popup.position.y + 40.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_popup_tween.chain().tween_callback(func():
		_popup_dim.visible = false
		_clear_popup_body())

# A quick fade-in of the popup body — used on open and on each grid⇄detail swap.
func _animate_body_in() -> void:
	_popup_body.modulate.a = 0.0
	var t := _popup_body.create_tween().set_ease(Tween.EASE_OUT)
	t.tween_property(_popup_body, "modulate:a", 1.0, 0.12)

# Detach immediately (not just queue_free) so a rebuild never shows the old and new
# content in the same frame.
func _clear_popup_body() -> void:
	for c in _popup_body.get_children():
		_popup_body.remove_child(c)
		c.queue_free()

# Rebuild the current station's body in place — used when a station view has inner
# navigation (the Contract Board grid ⇄ a card's detail). Fades the new content in.
func _rebuild_popup_body() -> void:
	_clear_popup_body()
	_build_station_content(_popup_kind)
	_animate_body_in()

# Per-station content. v1 reuses the existing verbs; the richer per-station UIs
# (contract list, arsenal) are a later spec.
func _build_station_content(kind: String) -> void:
	match kind:
		"CONTRACT_BOARD":
			_build_contract_board()
		"QUARTERMASTER":
			var slots := Label.new()
			slots.text = _slots_text()
			_popup_body.add_child(slots)
			for item in Catalog.GEAR:
				var id: String = item["id"]
				var check := CheckBox.new()
				check.text = Catalog.item_label(item)
				check.button_pressed = id in _selected_items
				# Update selection + live slot count in place — no popup rebuild, so
				# the scroll position and the other checkboxes stay put.
				check.toggled.connect(func(on: bool):
					if on:
						if id not in _selected_items and _selected_items.size() >= Catalog.BAG_SLOTS:
							check.button_pressed = false  # revert; bag is full
							_set_status("the bag holds at most %d items" % Catalog.BAG_SLOTS)
							return
						if id not in _selected_items:
							_selected_items.append(id)
					else:
						_selected_items.erase(id)
					slots.text = _slots_text())
				_popup_body.add_child(check)
			_popup_button("Requisition (replaces your bag)", func(): _net.send_message(Protocol.REQUISITION, {"itemIds": _selected_items.duplicate()}))
		"DEPLOY_GATE":
			if _is_leader():
				_popup_button("DEPLOY the expedition", func(): _net.send_message(Protocol.DEPLOY))
			else:
				_popup_label("Only the party leader can deploy.")
		"EXTRACTION":
			_popup_button("EXTRACT — leave with what you learned", func(): _net.send_message(Protocol.EXTRACT))

func _slots_text() -> String:
	return "Requisition — %d of %d slots" % [_selected_items.size(), Catalog.BAG_SLOTS]

func _popup_label(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_popup_body.add_child(l)

func _popup_button(text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_pressed)
	_popup_body.add_child(b)

# ── Contract Board (R111) ─────────────────────────────────────────────────────
# Renders snapshot.board as parchment cards — name, site, threat pips (from tier),
# verb, and deliberately NO Incarnate art (mystery is the mechanic). Selecting a
# card previews it; Accept (leader) sends SELECT_CONTRACT. Proximity + leader are
# display hints only; the server re-validates and a raced NOT_*/PARTY_NOT_READY
# still surfaces in the status line (P62).

func _build_contract_board() -> void:
	if _board_selection.is_empty():
		var board: Array = _snapshot.get("board", [])
		_log("board cards=%d" % board.size())
		_popup_label("The needs of the world, written in blood and ink. Choose a contract.")
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 10)
		grid.add_theme_constant_override("v_separation", 10)
		_popup_body.add_child(grid)
		var idx := 0
		for c in board:
			grid.add_child(_make_contract_card(c, idx))
			idx += 1
	else:
		_build_contract_detail(_board_selection)

func _make_contract_card(c: Dictionary, idx: int) -> Control:
	# The card is a themed Button (dark stone + gold border, hover from the theme);
	# its content sits on top with mouse filtering off so clicks reach the Button.
	var card := Button.new()
	card.custom_minimum_size = Vector2(182, 118)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # stay 1:1 with the texture
	card.pivot_offset = Vector2(91, 59)   # scale from the card's centre on hover
	card.flat = true
	var empty := StyleBoxEmpty.new()      # the card chrome IS the torn texture below
	for st in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(st, empty)
	card.pressed.connect(func(): _select_board_card(c))
	# Torn parchment background — a unique tear pattern per card, drawn full-size
	# (not 9-slice) so the tear keeps its shape; the wood shows through the gaps.
	var bg := TextureRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	if not _parch_tex.is_empty():
		bg.texture = _parch_tex[idx % _parch_tex.size()]
	card.add_child(bg)
	card.mouse_entered.connect(func(): _hover_card(card, 1.045); bg.modulate = Color(1.10, 1.07, 1.0))
	card.mouse_exited.connect(func(): _hover_card(card, 1.0); bg.modulate = Color.WHITE)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left", 9)
	pad.add_theme_constant_override("margin_right", 9)
	pad.add_theme_constant_override("margin_top", 11)   # clear the pin at the top
	pad.add_theme_constant_override("margin_bottom", 8)
	card.add_child(pad)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 3)
	pad.add_child(v)
	v.add_child(_card_label(str(c.get("targetName", "?")), 15, Color(0.24, 0.15, 0.06), true))
	v.add_child(_card_label(str(c.get("siteName", "?")), 10, Color(0.42, 0.33, 0.20), false))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(spacer)
	var threat := HBoxContainer.new()
	threat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threat.add_child(_card_label("Threat ", 10, Color(0.55, 0.16, 0.14), false))
	var pips := ThreatPips.new()
	pips.set_tier(str(c.get("tier", "APPRENTICE")))
	threat.add_child(pips)
	v.add_child(threat)
	v.add_child(_card_label(_verb_word(str(c.get("primaryVerb", "?"))), 11, Color(0.44, 0.26, 0.12), false))
	# A red wax seal pinning the paper to the board (top-centre, over the edge).
	card.add_child(_wax_seal())
	return card

# Lift a card toward the viewer on hover (scale from its centre pivot).
func _hover_card(card: Control, s: float) -> void:
	if not is_instance_valid(card):
		return
	var t := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2(s, s), 0.09)

# A small round wax seal, positioned straddling the top edge of a card.
func _wax_seal() -> Panel:
	var seal := Panel.new()
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.62, 0.13, 0.13)
	sb.set_corner_radius_all(7)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.32, 0.05, 0.05)
	seal.add_theme_stylebox_override("panel", sb)
	seal.anchor_left = 0.5
	seal.anchor_right = 0.5
	seal.anchor_top = 0.0
	seal.anchor_bottom = 0.0
	seal.offset_left = -7.0
	seal.offset_right = 7.0
	seal.offset_top = -5.0
	seal.offset_bottom = 9.0
	return seal

func _card_label(text: String, size: int, color: Color, do_wrap: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if do_wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _build_contract_detail(c: Dictionary) -> void:
	var title := Label.new()
	title.text = str(c.get("targetName", "?"))
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.90, 0.78, 0.45))
	_popup_body.add_child(title)
	_popup_label("Site: %s" % c.get("siteName", "?"))
	var threat := HBoxContainer.new()
	threat.add_child(_card_label("Threat  ", 12, Color(0.82, 0.55, 0.55), false))
	var pips := ThreatPips.new()
	pips.set_tier(str(c.get("tier", "APPRENTICE")))
	threat.add_child(pips)
	_popup_body.add_child(threat)
	# A flavored charge instead of a bare "verb: X" — seeded by the contractId, so
	# each contract reads a little differently but stably (client-side prose over
	# the server's verb; authored intel text is a later enhancement).
	_popup_label(_contract_brief(c))
	_popup_label("The Collegium does not hunt for glory, but for understanding.")
	# Accept is a leader affordance; the server still gates leader/board/ready (P62).
	if _is_leader():
		if not _all_ready():
			_popup_label("The whole party must be Ready before you can accept.")
		_popup_button("Accept this contract", func():
			_net.send_message(Protocol.SELECT_CONTRACT, {"contractId": c.get("contractId", "")}))
	else:
		_popup_label("Only the party leader can accept the contract.")
	_popup_button("← Back to the board", func(): _select_board_card({}))

func _select_board_card(c: Dictionary) -> void:
	_board_selection = c
	if not c.is_empty():
		_log("select %s" % c.get("contractId", ""))
	# Cross-fade: fade the current view out, then rebuild (which fades the new in).
	var t := _popup_body.create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(_popup_body, "modulate:a", 0.0, 0.07)
	t.tween_callback(_rebuild_popup_body)

# Client-side mirror of the server's ghost-proof allReady (connected players only);
# a display hint for the Accept affordance — the server remains the authority.
func _all_ready() -> bool:
	var players: Array = _snapshot.get("players", [])
	if players.is_empty():
		return false
	for p in players:
		if p.get("connected", true) and not p.get("readyState", false):
			return false
	return true

# The station popup's look: a gothic Theme applied to `_popup` that cascades to
# every child (buttons, labels, checkboxes). The panel itself is a 9-slice
# StyleBoxTexture built from assets/ui/panel.png (dark stone + aged-gold frame),
# with a StyleBoxFlat fallback so a missing/late texture import never crashes the
# popup. Palette-locked to the game's charcoal-and-gold register (art direction).
func _build_popup_theme() -> Theme:
	var th := Theme.new()
	var panel_sb: StyleBox
	var tex := load("res://assets/ui/panel.png") as Texture2D
	if tex != null:
		var sbt := StyleBoxTexture.new()
		sbt.texture = tex
		sbt.set_texture_margin_all(12.0)   # 9-slice: matches gen_panel.py MARGIN
		sbt.set_content_margin_all(12.0)   # inset children off the frame
		panel_sb = sbt
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.10, 0.086, 0.15)
		flat.set_border_width_all(2)
		flat.border_color = Color(0.72, 0.57, 0.18)
		flat.set_content_margin_all(14.0)
		panel_sb = flat
	th.set_stylebox("panel", "PanelContainer", panel_sb)
	# Buttons: dark stone with a gold border, brighter on hover, sunk when pressed.
	th.set_stylebox("normal", "Button", _btn_box(Color(0.13, 0.11, 0.17), Color(0.42, 0.32, 0.13)))
	th.set_stylebox("hover", "Button", _btn_box(Color(0.18, 0.145, 0.22), Color(0.79, 0.64, 0.29)))
	th.set_stylebox("pressed", "Button", _btn_box(Color(0.09, 0.075, 0.12), Color(0.52, 0.41, 0.16)))
	th.set_color("font_color", "Button", Color(0.86, 0.78, 0.56))
	th.set_color("font_hover_color", "Button", Color(0.97, 0.88, 0.64))
	th.set_color("font_color", "Label", Color(0.87, 0.83, 0.73))
	th.set_color("font_color", "CheckBox", Color(0.86, 0.81, 0.69))
	return th

func _btn_box(bg: Color, border: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.set_border_width_all(1)
	b.border_color = border
	b.content_margin_left = 10.0
	b.content_margin_right = 10.0
	b.content_margin_top = 5.0
	b.content_margin_bottom = 5.0
	return b

# A 9-slice StyleBox from a texture, with a flat fallback if the texture is missing
# or not yet imported (so the popup never breaks on a cold asset).
func _texture_sb(path: String, margin: float, content: float, bg: Color, border: Color, mod_color: Color = Color.WHITE) -> StyleBox:
	var tex := load(path) as Texture2D
	if tex != null:
		var sb := StyleBoxTexture.new()
		sb.texture = tex
		sb.set_texture_margin_all(margin)
		sb.set_content_margin_all(content)
		sb.modulate_color = mod_color
		return sb
	var flat := StyleBoxFlat.new()
	flat.bg_color = bg
	flat.set_border_width_all(2)
	flat.border_color = border
	flat.set_content_margin_all(content)
	return flat

# The flavored charge for a contract, chosen stably from its id.
func _contract_brief(c: Dictionary) -> String:
	var verb := str(c.get("primaryVerb", ""))
	var options: Array = VERB_FLAVOR.get(verb, ["The charge is unclear; read the signs and decide."])
	var idx: int = absi(str(c.get("contractId", "")).hash()) % options.size()
	return str(options[idx])

# "INVESTIGATE" -> "Investigate" (String.capitalize() would split all-caps letters).
func _verb_word(verb: String) -> String:
	if verb.is_empty():
		return "?"
	return verb.substr(0, 1) + verb.substr(1).to_lower()

# Follow the local body, clamped inside the map; center on axes smaller than the
# view. Reads the body's server target, never an integrated guess.
func _follow_camera() -> void:
	if not _world.visible:
		return
	var b: Player = _bodies.get(_self_id)
	if b == null:
		return
	var bounds := _space.grid_size_px()
	if bounds == Vector2.ZERO:
		return
	var view := get_viewport_rect().size / _camera.zoom
	var half := view * 0.5
	var cam := b.position
	cam.x = bounds.x * 0.5 if bounds.x <= view.x else clampf(cam.x, half.x, bounds.x - half.x)
	cam.y = bounds.y * 0.5 if bounds.y <= view.y else clampf(cam.y, half.y, bounds.y - half.y)
	_camera.position = cam

func _display_name_plain(player_id: String) -> String:
	for p in _snapshot.get("players", []):
		if p["playerId"] == player_id:
			return p["displayName"]
	return player_id

func _log(msg: String) -> void:
	print("[client] ", msg)

# ── Helpers ──────────────────────────────────────────────────────────────────

func _player_row(p: Dictionary) -> String:
	var marks := ""
	if p.get("isLeader", false):
		marks += " ★"
	if p["playerId"] == _self_id:
		marks += " (you)"
	if not p.get("connected", true):
		marks += " (disconnected)"
	var ready_label := "ready" if p.get("readyState", false) else "not ready"
	var bag: Array = p.get("bag", [])
	var bag_note := "" if bag.is_empty() else "  |  bag: " + ", ".join(bag.map(func(i): return Catalog.short_name(i)))
	return "%s%s — %s%s" % [p["displayName"], marks, ready_label, bag_note]

# One party member as a row: the text plus, for the leader looking at a
# disconnected teammate, a Kick button (server re-validates everything; P39
# means a connected player can never be kicked even if a stale row shows one).
func _party_row(p: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)
	var l := Label.new()
	l.text = _player_row(p)
	row.add_child(l)
	if _is_leader() and not p.get("connected", true) and p["playerId"] != _self_id:
		var pid: String = p["playerId"]
		var b := Button.new()
		b.text = "Kick"
		b.pressed.connect(func(): _net.send_message(Protocol.KICK_PLAYER, {"playerId": pid}))
		row.add_child(b)

func _display_name(player_id: String) -> String:
	for p in _snapshot.get("players", []):
		if p["playerId"] == player_id:
			return p["displayName"] + (" (you)" if player_id == _self_id else "")
	return player_id

func _is_leader() -> bool:
	for p in _snapshot.get("players", []):
		if p["playerId"] == _self_id:
			return p.get("isLeader", false)
	return false

func _reset_session() -> void:
	_self_id = ""
	_set_token("")
	_snapshot = {}
	_field = {}
	_field_site = {}
	_channels = []
	_signs = []
	_probe_log = []
	_exposure = 0
	_testament = {}
	_archive = []
	_selected_items = []
	_pending_join = false
	_last_intent = Vector2i.ZERO
	_active_station = ""
	_clear_bodies()
	if _popup_dim:
		_close_station()
	if _world:
		_world.visible = false

func _set_status(text: String) -> void:
	_status.text = text

func _set_token(token: String) -> void:
	_reconnect_token = token
	if token == "":
		DirAccess.remove_absolute(TOKEN_PATH)
	else:
		var f := FileAccess.open(TOKEN_PATH, FileAccess.WRITE)
		if f:
			f.store_string(token)

func _load_token() -> String:
	if not FileAccess.file_exists(TOKEN_PATH):
		return ""
	var f := FileAccess.open(TOKEN_PATH, FileAccess.READ)
	return f.get_as_text().strip_edges() if f else ""

# ── UI builders ──────────────────────────────────────────────────────────────

func _clear() -> void:
	for child in _root.get_children():
		child.queue_free()

func _h1(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	_root.add_child(l)

func _h2(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 18)
	_root.add_child(l)

func _label(text: String) -> void:
	var l := Label.new()
	l.text = text
	_root.add_child(l)

func _button(text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.pressed.connect(on_pressed)
	_root.add_child(b)

func _make_line_edit(placeholder: String, initial: String) -> LineEdit:
	var e := LineEdit.new()
	e.placeholder_text = placeholder
	e.text = initial
	e.custom_minimum_size = Vector2(280, 0)
	_root.add_child(e)
	return e
