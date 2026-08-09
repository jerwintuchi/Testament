extends RefCounted
## The Collegium's stores — the ROOM the Quartermaster stands in (TD-101).
##
## Builds the environment only: the ashlar wall, the two shelving frames, the
## inspection counter and its lamp. It owns no items and no interaction; `shelf.gd`
## puts objects on the boards and `counter.gd` receives the one being inspected.
##
## Why a room and not a panel: the brief's §14 — the player must read a location, not
## a menu with a background. Everything here is scenery, so nothing in it is focusable
## and nothing responds to the mouse.
##
## LIGHT IS BAKED. `Light2D` cannot reach `Control` nodes (TD-047, re-confirmed for the
## world layer by TD-083), and this screen is entirely Control-based. The single moving
## thing is the lamp's flicker, a looping tween on `modulate` — no `_process`, no
## particle emitter, so it costs nothing per frame.

const Widgets := preload("res://scripts/ui/widgets.gd")
const Fonts   := preload("res://scripts/ui/fonts.gd")

const WALL    := "res://assets/ui/stations/qm_wall.png"
const SHELF   := "res://assets/ui/stations/qm_shelf.png"
const BOARD   := "res://assets/ui/stations/qm_board.png"
const LABEL   := "res://assets/ui/stations/qm_label.png"
const COUNTER := "res://assets/ui/stations/qm_counter.png"
const PROPS   := "res://assets/ui/stations/qm_props.png"

const SHELF_M   := 16      # 9-slice margins, matching gen_qm_room.py
const BOARD_M   := 4
const LABEL_M   := 7
const COUNTER_M := 16
const PROP_PX   := 24

# Prop indices in qm_props.png.
const P_LEDGER := 0
const P_CANDLE := 1
const P_INK    := 2
const P_SCALE  := 3

# ── the room's geometry, in fractions of the viewport ────────────────────────
# Fractions, never fixed pixels: the canon is that anything on screen is sized from
# the viewport so it cannot run off it (TD-098).
const HEADER_H  := 0.115
const LEFT_X    := 0.030
const LEFT_W    := 0.585
const RIGHT_X   := 0.635
const RIGHT_W   := 0.340
const SHELVES_Y := 0.135
const SHELVES_H := 0.415
const COUNTER_Y := 0.590
const COUNTER_H := 0.190

# The ink of this room. Warmer and darker than the writ's parchment, because you are
# in a cellar store rather than reading a document.
const INK_WARM  := Color(0.82, 0.72, 0.52)
const INK_FAINT := Color(0.62, 0.54, 0.40)


## Builds the room into `host` and returns the rects the other modules need.
## Nothing returned is a node the caller may reparent — they are geometry.
static func build(host: Control, vp: Vector2) -> Dictionary:
	_wall(host, vp)

	var shelf_rect := Rect2(vp.x * LEFT_X, vp.y * SHELVES_Y, vp.x * LEFT_W, vp.y * SHELVES_H)
	var counter_rect := Rect2(vp.x * LEFT_X, vp.y * COUNTER_Y, vp.x * LEFT_W, vp.y * COUNTER_H)
	var right_rect := Rect2(vp.x * RIGHT_X, vp.y * SHELVES_Y, vp.x * RIGHT_W, vp.y * 0.72)

	_header(host, vp)
	var shelving := _shelving(host, shelf_rect)
	_counter(host, counter_rect)

	return {
		"shelf_rect": shelf_rect,
		"counter_rect": counter_rect,
		"right_rect": right_rect,
		"units": shelving[0],    # one rect per shelf unit: where instruments may stand
		"dress": shelving[1],    # the upper boards: stock only, never an instrument
		"frames": shelving[2],   # the shelving units themselves, for their labels
	}


# ── the environment ─────────────────────────────────────────────────────────

static func _wall(host: Control, vp: Vector2) -> void:
	# A tiling ashlar backdrop. `navestone` is the nave's own stone, so the stores and
	# the Great Hall are the same building (TD-081).
	var w := TextureRect.new()
	w.texture = load(WALL) as Texture2D
	w.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	w.stretch_mode = TextureRect.STRETCH_TILE
	w.set_anchors_preset(Control.PRESET_FULL_RECT)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(w)

	# The room falls off into darkness at the edges, so the lamp-lit middle is where
	# the eye settles. One baked gradient, not a full-frame additive layer.
	var vig := ColorRect.new()
	vig.color = Color(0, 0, 0, 0.34)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(vig)


static func _header(host: Control, vp: Vector2) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(vp.x * LEFT_X, vp.y * 0.030)
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(box)

	var t := Widgets.card_label("QUARTERMASTER", 15, INK_WARM, false, false)
	t.add_theme_font_override("font", Fonts.heading())
	box.add_child(t)
	var s := Widgets.card_label("COLLEGIUM STORES · EXPEDITION ISSUE", 8, INK_FAINT, false, false)
	box.add_child(s)


static func _shelving(host: Control, rect: Rect2) -> Array:
	# Two units, because there are exactly two kinds of instrument. The reference's
	# PROVISIONS / RELICS / TOOLS do not exist in the catalog and are not invented
	# here — the brief's own §4 forbids that.
	var units: Array = []
	var dress: Array = []
	var frames: Array = []
	var unit_h := rect.size.y / 2.0
	for i in 2:
		var top := rect.position.y + unit_h * i
		var frame := _nine(SHELF, SHELF_M)
		frame.position = Vector2(rect.position.x, top)
		frame.size = Vector2(rect.size.x, unit_h - 3.0)
		host.add_child(frame)
		frames.append(Rect2(frame.position, frame.size))

		var board_h := 12.0
		# An UPPER board carrying stock only. A unit tall enough for one row left a
		# band of dead black above the instruments, which reads as an empty rack rather
		# than a store — the brief's §4 wants shelving that looks used.
		var upper := _nine(BOARD, BOARD_M)
		upper.position = Vector2(rect.position.x + 5.0, top + 24.0)
		upper.size = Vector2(rect.size.x - 10.0, board_h)
		host.add_child(upper)
		dress.append(Rect2(
			upper.position.x + 6.0, upper.position.y - 16.0,
			upper.size.x - 12.0, 16.0))

		# The plank objects stand on, at the foot of the unit.
		var board := _nine(BOARD, BOARD_M)
		board.position = Vector2(rect.position.x + 5.0, top + unit_h - board_h - 9.0)
		board.size = Vector2(rect.size.x - 10.0, board_h)
		host.add_child(board)

		# Objects stand ON the board's lit top edge.
		units.append(Rect2(
			board.position.x + 6.0, upper.position.y + board_h,
			board.size.x - 12.0, board.position.y - (upper.position.y + board_h)))
	return [units, dress, frames]


## A shelf's label plate. Public so `shelf.gd` can name each unit from the catalog's
## own kinds rather than from a string this file invented.
static func label_plate(host: Control, text: String, at: Vector2, width: float) -> Control:
	var plate := _nine(LABEL, LABEL_M)
	plate.position = at
	plate.size = Vector2(width, 14)
	host.add_child(plate)
	var l := Widgets.card_label(text, 8, Color(0.20, 0.16, 0.10), false, true)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(l)
	return plate


static func _counter(host: Control, rect: Rect2) -> void:
	var c := _nine(COUNTER, COUNTER_M)
	c.position = rect.position
	c.size = rect.size
	host.add_child(c)

	# Four props, and only four. The brief is explicit that the counter must not be
	# cluttered (§8) — the object under inspection is the thing that matters.
	_prop(host, P_LEDGER, Vector2(rect.position.x + 10.0, rect.position.y - 12.0))
	_prop(host, P_INK,    Vector2(rect.position.x + 38.0, rect.position.y - 10.0))
	_prop(host, P_SCALE,  Vector2(rect.end.x - 40.0, rect.position.y - 14.0))
	var candle := _prop(host, P_CANDLE, Vector2(rect.end.x - 72.0, rect.position.y - 16.0))
	_flicker(candle)


static func _prop(host: Control, index: int, at: Vector2) -> TextureRect:
	var t := TextureRect.new()
	var at_tex := AtlasTexture.new()
	at_tex.atlas = load(PROPS) as Texture2D
	at_tex.region = Rect2(index * PROP_PX, 0, PROP_PX, PROP_PX)
	t.texture = at_tex
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.position = at
	t.size = Vector2(PROP_PX, PROP_PX)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(t)
	return t


## The room's one moving thing. A looping tween, NOT a particle emitter and NOT
## `_process`: the budget allows twenty particles for dust and nothing for a flame
## that a modulate can carry just as well.
static func _flicker(node: CanvasItem) -> void:
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "modulate", Color(1.06, 1.02, 0.94), 1.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", Color(0.94, 0.92, 0.90), 2.3).set_trans(Tween.TRANS_SINE)


# ── builders ────────────────────────────────────────────────────────────────

static func _nine(path: String, margin: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(margin))
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p
