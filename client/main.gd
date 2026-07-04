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

func _ready() -> void:
	_net = NetClient.new()
	add_child(_net)
	_net.message_received.connect(_on_message)
	_net.socket_opened.connect(_on_socket_opened)
	_net.socket_closed.connect(_on_socket_closed)

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
			_show_deploying()
		Protocol.FIELD_STARTED:
			_field = payload["fieldData"]
			_set_token(payload["reconnectToken"])
			_signs = payload["signs"]
			_channels = payload["perceivedChannels"]
			_probe_log = []
			_exposure = 0
			_snapshot["phase"] = Protocol.PHASE_FIELD
			_show_field()
		Protocol.PROBE_RESULT:
			_ingest_probe_result(payload)
		Protocol.FIELD_TESTAMENT:
			_testament = payload["testament"]
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
				_signs = fs["signs"]
				_channels = fs["perceivedChannels"]
				_archive = fs["archiveEntries"]
				_probe_log = []
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

func _ingest_probe_result(payload: Dictionary) -> void:
	_exposure = int(payload["exposure"])
	var who: String = _display_name(payload["playerId"])
	var line: String
	if payload["sign"] != null:
		var sign: Dictionary = payload["sign"]
		line = "%s presented %s — [%s] %s" % [who, payload["stimulus"], sign["channel"], sign["token"]]
		if not _signs.any(func(s): return s["channel"] == sign["channel"] and s["token"] == sign["token"]):
			_signs.append(sign)
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
	if _is_leader():
		_button("Accept Contract  (leader — needs all ready)", func(): _net.send_message(Protocol.ACCEPT_CONTRACT))
	_button("Leave Room", func():
		_net.send_message(Protocol.LEAVE_ROOM)
		_reset_session()
		_show_menu())

func _show_deploying() -> void:
	_screen = Screen.DEPLOYING
	_clear()
	var c: Dictionary = _snapshot.get("contract") if _snapshot.get("contract") != null else {}
	_h1("Contract — %s" % c.get("targetName", "?"))
	_label("site: %s    tier: %s    verb: %s" % [c.get("siteName", "?"), c.get("tier", "?"), c.get("primaryVerb", "?")])
	_label("")
	_h2("Requisition (%d of %d slots)" % [_selected_items.size(), Catalog.BAG_SLOTS])
	for item in Catalog.GEAR:
		var id: String = item["id"]
		var check := CheckBox.new()
		check.text = Catalog.item_label(item)
		check.button_pressed = id in _selected_items
		check.toggled.connect(func(on: bool): _on_item_toggled(id, on))
		_root.add_child(check)
	_button("Requisition (replaces your bag)", func():
		_net.send_message(Protocol.REQUISITION, {"itemIds": _selected_items.duplicate()}))
	_label("")
	_h2("Party bags")
	for p in _snapshot.get("players", []):
		_party_row(p)
	if _is_leader():
		_label("")
		_button("DEPLOY  (leader)", func(): _net.send_message(Protocol.DEPLOY))

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
	_button("EXTRACT — leave with what you learned", func(): _net.send_message(Protocol.EXTRACT))

func _show_testament() -> void:
	_screen = Screen.TESTAMENT
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

# ── Helpers ──────────────────────────────────────────────────────────────────

func _on_item_toggled(id: String, on: bool) -> void:
	if on and id not in _selected_items:
		if _selected_items.size() >= Catalog.BAG_SLOTS:
			_set_status("the bag holds at most %d items" % Catalog.BAG_SLOTS)
		else:
			_selected_items.append(id)
	elif not on:
		_selected_items.erase(id)
	_show_deploying()

func _player_row(p: Dictionary) -> String:
	var marks := ""
	if p.get("isLeader", false):
		marks += " ★"
	if p["playerId"] == _self_id:
		marks += " (you)"
	if not p.get("connected", true):
		marks += " (disconnected)"
	var ready := "ready" if p.get("readyState", false) else "not ready"
	var bag: Array = p.get("bag", [])
	var bag_note := "" if bag.is_empty() else "  |  bag: " + ", ".join(bag.map(func(i): return Catalog.short_name(i)))
	return "%s%s — %s%s" % [p["displayName"], marks, ready, bag_note]

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
	_channels = []
	_signs = []
	_probe_log = []
	_exposure = 0
	_testament = {}
	_archive = []
	_selected_items = []
	_pending_join = false

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
