## The lobby's room scroll (TD-071 / R228–R229): the party roster, the room code and the two
## actions, on a parchment that stays rolled up until you want it.
##
## CLOSED by default and costing no usable screen space — a small pinned tab carrying only the
## party's ready pips, so readiness is legible without opening anything. That is the author's
## constraint: the walkable Collegium is the screen, and the HUD must not sit on top of it.
##
## A node-owning component (canon S3.1): the parent drives it with `refresh(snapshot, self_id)`
## and it reports upward with signals. It never touches the socket — the shell owns that (S3.5),
## which is also what keeps it presentation-only (P124: opening or closing sends nothing and
## mutates nothing).
extends Control

const Fonts = preload("res://scripts/ui/fonts.gd")
const Widgets = preload("res://scripts/ui/widgets.gd")

signal ready_toggled
signal leave_pressed
signal kick_requested(player_id: String)

const INK := Color(0.16, 0.11, 0.05)
const INK_SOFT := Color(0.30, 0.22, 0.12)
const GILT := Color(0.86, 0.72, 0.42)
const PARTY_MAX := 4

var _open := false
var _snapshot: Dictionary = {}
var _self_id := ""
var _tab: Control
var _sheet: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# anchors AND offsets: set_anchors_preset alone leaves the offsets, so a Control added to an
	# already-sized parent stays 0x0 and its TOP_RIGHT children land off-screen.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Redraw from the snapshot. The roster is never accumulated client-side — what the server last
## said is the only truth this renders (P124).
func refresh(snapshot: Dictionary, self_id: String) -> void:
	_snapshot = snapshot
	_self_id = self_id
	_rebuild()


func is_open() -> bool:
	return _open


func toggle() -> void:
	set_open(not _open)


func set_open(open: bool) -> void:
	if _open == open:
		return
	_open = open
	_rebuild()


# ── Rendering ────────────────────────────────────────────────────────────────

func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	_tab = _build_tab()
	add_child(_tab)
	if _open:
		_sheet = _build_sheet()
		add_child(_sheet)


func _players() -> Array:
	var p: Variant = _snapshot.get("players", [])
	return p if p is Array else []


func _is_leader() -> bool:
	for p in _players():
		if p.get("playerId", "") == _self_id:
			return bool(p.get("isLeader", false))
	return false


## The closed state: a small parchment tab pinned to the top-right, showing only the ready pips.
## Clicking it opens the scroll, so the affordance is discoverable without a keybind.
func _build_tab() -> Control:
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Party  (Tab)"
	btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -104.0
	btn.offset_right = -6.0
	btn.offset_top = 6.0
	btn.offset_bottom = 26.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.13, 0.10, 0.06, 0.82)
	sb.border_color = Color(0.44, 0.34, 0.18, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(2)
	for st in ["normal", "hover", "pressed", "focus"]:
		btn.add_theme_stylebox_override(st, sb)
	btn.pressed.connect(toggle)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(row)
	row.add_child(Widgets.card_label("PARTY", 8, Color(0.68, 0.58, 0.38), false, false))
	# Ready pips: filled = ready, hollow = not, dim = an empty seat. Legible closed, which is the
	# whole reason the tab exists.
	var players := _players()
	for i in PARTY_MAX:
		var pip := "·"
		var col := Color(0.38, 0.32, 0.22)
		if i < players.size():
			var pl: Dictionary = players[i]
			if not pl.get("connected", true):
				pip = "×"
				col = Color(0.55, 0.30, 0.24)
			elif pl.get("readyState", false):
				pip = "●"
				col = Color(0.55, 0.78, 0.45)
			else:
				pip = "○"
				col = Color(0.80, 0.70, 0.44)
		row.add_child(Widgets.card_label(pip, 10, col, false, false))
	return btn


func _build_sheet() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -232.0
	panel.offset_right = -6.0
	panel.offset_top = 30.0
	panel.offset_bottom = 30.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.80, 0.71, 0.50, 0.96)      # parchment
	sb.border_color = Color(0.34, 0.24, 0.12)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(9.0)
	panel.add_theme_stylebox_override("panel", sb)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)

	# ── The code, large and unambiguous, with a copy affordance (R229). Reading it aloud off a
	#    body label was the old ask; a code you can paste is the production one.
	col.add_child(Widgets.card_label("ROOM", 8, INK_SOFT, false, false))
	var code := str(_snapshot.get("roomCode", "?"))
	var code_row := HBoxContainer.new()
	code_row.add_theme_constant_override("separation", 6)
	col.add_child(code_row)
	var code_lbl := Widgets.card_label(" ".join(code.split()), 19, INK, false, false)
	var f := Fonts.cinzel(700)
	if f != null:
		code_lbl.add_theme_font_override("font", f)
	code_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_row.add_child(code_lbl)
	var copy := Button.new()
	copy.text = "Copy"
	copy.add_theme_font_size_override("font_size", 9)
	copy.focus_mode = Control.FOCUS_NONE
	copy.tooltip_text = "Copy the room code"
	copy.pressed.connect(func():
		DisplayServer.clipboard_set(code)
		_flash(copy, "Copied"))
	code_row.add_child(copy)

	col.add_child(Widgets.hrule(Color(0.42, 0.30, 0.16, 0.6)))

	# ── The roster. Ready state is a PIP, never the words "not ready".
	for p in _players():
		col.add_child(_roster_row(p))
	for _i in range(PARTY_MAX - _players().size()):
		col.add_child(Widgets.card_label("○  —", 10, Color(0.46, 0.38, 0.26), false, false))

	col.add_child(Widgets.hrule(Color(0.42, 0.30, 0.16, 0.6)))

	# ── The two actions.
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 6)
	col.add_child(acts)
	var ready_btn := Button.new()
	ready_btn.text = "Ready"
	ready_btn.add_theme_font_size_override("font_size", 10)
	ready_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ready_btn.pressed.connect(func(): ready_toggled.emit())
	acts.add_child(ready_btn)
	var leave_btn := Button.new()
	leave_btn.text = "Leave"
	leave_btn.add_theme_font_size_override("font_size", 10)
	leave_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leave_btn.pressed.connect(func(): leave_pressed.emit())
	acts.add_child(leave_btn)
	return panel


func _roster_row(p: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	var connected: bool = p.get("connected", true)
	var ready: bool = p.get("readyState", false)
	var pip := "×" if not connected else ("●" if ready else "○")
	var pip_col := Color(0.55, 0.30, 0.24) if not connected else \
		(Color(0.30, 0.50, 0.22) if ready else Color(0.46, 0.38, 0.26))
	row.add_child(Widgets.card_label(pip, 11, pip_col, false, false))

	var name_s := str(p.get("displayName", "?"))
	if p.get("isLeader", false):
		name_s += "  ★"
	if p.get("playerId", "") == _self_id:
		name_s += "  (you)"
	var name_lbl := Widgets.card_label(name_s, 10, INK if connected else Color(0.48, 0.36, 0.28), false, false)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	# The leader may clear a ghost (R92 heritage). Affordance only — the server still authorises.
	if _is_leader() and not connected and p.get("playerId", "") != _self_id:
		var pid := str(p.get("playerId", ""))
		var kick := Button.new()
		kick.text = "✕"
		kick.add_theme_font_size_override("font_size", 9)
		kick.focus_mode = Control.FOCUS_NONE
		kick.tooltip_text = "Remove %s" % p.get("displayName", "")
		kick.pressed.connect(func(): kick_requested.emit(pid))
		row.add_child(kick)
	return row


func _flash(btn: Button, text: String) -> void:
	# Confirm in place rather than through the toast: the scroll is already open and looking at
	# the thing you just pressed.
	var was := btn.text
	btn.text = text
	var t := btn.create_tween()
	t.tween_interval(1.1)
	t.tween_callback(func():
		if is_instance_valid(btn):
			btn.text = was)
