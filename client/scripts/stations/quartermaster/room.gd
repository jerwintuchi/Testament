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
const BoardDecor := preload("res://scripts/board/board_decor.gd")

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

# Dust motes in the candle's reach. Declared here so `tools/qm_budget.py` can read it.
const DUST_COUNT := 14

# Where the candle stands, as a fraction of the frame. ONE constant read by both the
# prop and the light rig, so the flame and the light it casts can never drift apart —
# the same coupling the board keeps between its sconce and `torch_rig` (P95).
# Where the candle stands across the counter. Its VERTICAL position is derived, not
# declared: a candle stands ON the surface, so its feet come from `COUNTER_Y` and only
# the flame's height above them is a constant. Declaring both independently is how the
# first pass ended up with a candle hovering seven pixels off the bench.
# The lamp at the NEAR end of the bench. A FILL: weak and wide, so the far instruments
# are browsable without the bench losing its place as the lit spot. It has a visible
# fixture on purpose — a light with no source is a cheat, and the board couples every
# flame to its sconce (P95).
#
# It stands on the counter rather than hanging on the wall, and that is a correction:
# hung at the shelf end it was drawn BEHIND the shelving, which fills that whole side
# of the room, so the fixture was invisible while its light was not. A lamp standing by
# the paperwork is both plausible and actually on screen.
const LAMP_FX     := 0.058
const LAMP_ENERGY := 0.34

const CANDLE_FX   := 0.500
const CANDLE_FEET := 5.0     # how far the base sinks into the surface it stands on
const FLAME_UP    := 4.0     # the flame, measured down from the prop's top edge

# Prop indices in qm_props.png.
const P_LEDGER := 0
const P_CANDLE := 1
const P_INK    := 2
const P_SCALE  := 3
const P_WAX    := 4
const P_PAPERS := 5
const P_LAMP   := 6

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
# The right column runs nearly to the foot of the frame: at 0.72 it left a band of
# dead black under the rite while the RECORD — the thing with the most to say — was
# squeezed to 119px and hid its WARNING behind a scroll (R374/§19).
const RIGHT_H   := 0.800

# The ink of this room. Warmer and darker than the writ's parchment, because you are
# in a cellar store rather than reading a document.
const INK_WARM  := Color(0.82, 0.72, 0.52)
const INK_FAINT := Color(0.62, 0.54, 0.40)


## The room's light: one candle on the counter, packed for `board_surface.gdshader`.
##
## Light2D cannot reach Control nodes (TD-047, re-confirmed TD-083), which is precisely
## why that shader exists — it samples a normal map and its own uniform lights. The
## stores borrow it rather than inventing a second lighting path, so this room and the
## Contract Board are lit by the same code.
##
## A generous radius, unlike the board's tight 0.24 sconce halo: the board wants its
## wall to stay dungeon-dark around a framed object, while a WORKROOM should read as
## occupied — the light has to reach the shelves the player is being asked to browse.
## The candle prop's top-left corner. ONE source for the object and its light.
static func candle_pos(vp: Vector2) -> Vector2:
	return Vector2(vp.x * CANDLE_FX - PROP_PX * 0.5,
		vp.y * COUNTER_Y - PROP_PX + CANDLE_FEET)


static func lamp_pos(vp: Vector2) -> Vector2:
	# Feet on the counter, derived exactly as the candle's are, so neither can float.
	return Vector2(vp.x * LAMP_FX - PROP_PX * 0.5,
		vp.y * COUNTER_Y - PROP_PX + CANDLE_FEET)


static func candle_rig(vp: Vector2) -> Array:
	var flame := candle_pos(vp) + Vector2(PROP_PX * 0.5, FLAME_UP)
	var lamp := lamp_pos(vp) + Vector2(PROP_PX * 0.44, PROP_PX * 0.5)
	return [
		{
			"uv": Vector2(flame.x / vp.x, flame.y / vp.y),
			"color": Color(1.0, 0.74, 0.44),
			"radius": 0.44,
			"energy": 0.9,
		},
		{
			# The fill. Weak and wide: it lifts the far shelves off black without
			# competing with the bench, and it is warm-neutral rather than a second
			# candle, because two equal flames would flatten the room again.
			"uv": Vector2(lamp.x / vp.x, lamp.y / vp.y),
			"color": Color(0.92, 0.80, 0.62),
			"radius": 0.52,
			"energy": LAMP_ENERGY,
		},
	]


## A surface material lit by this room's candle. Thin wrapper so no call site has to
## remember to pass the rig — forgetting it would silently light the stores from the
## Contract Board's torches, which are not in this room.
static func lit(vp: Vector2, normal_path: String, ambient: float = 0.34,
		diffuse_gain: float = 1.0, tile: Vector2 = Vector2.ONE) -> ShaderMaterial:
	return BoardDecor.surface_material(vp, normal_path, ambient, diffuse_gain, tile,
		1.0, candle_rig(vp))


## Builds the room into `host` and returns the rects the other modules need.
## Nothing returned is a node the caller may reparent — they are geometry.
static func build(host: Control, vp: Vector2) -> Dictionary:
	_wall(host, vp)

	var shelf_rect := Rect2(vp.x * LEFT_X, vp.y * SHELVES_Y, vp.x * LEFT_W, vp.y * SHELVES_H)
	var counter_rect := Rect2(vp.x * LEFT_X, vp.y * COUNTER_Y, vp.x * LEFT_W, vp.y * COUNTER_H)
	var right_rect := Rect2(vp.x * RIGHT_X, vp.y * SHELVES_Y, vp.x * RIGHT_W, vp.y * RIGHT_H)

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
	# Tiled sampling: the shader repeats the 64px stone across the frame, so the wall is
	# one draw and one small texture rather than a screen-sized image.
	w.material = lit(vp, "res://assets/ui/stations/qm_wall_n.png", 0.22, 1.0,
		Vector2(vp.x / 64.0, vp.y / 64.0))
	host.add_child(w)

	# The room falls off into darkness at the edges, so the lamp-lit middle is where
	# the eye settles. One baked gradient, not a full-frame additive layer.
	var vig := ColorRect.new()
	vig.color = Color(0, 0, 0, 0.26)
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
		frame.material = lit(vp_of(host), "res://assets/ui/stations/qm_shelf_n.png", 0.13)
		host.add_child(frame)
		frames.append(Rect2(frame.position, frame.size))

		var board_h := 12.0
		# An UPPER board carrying stock only. A unit tall enough for one row left a
		# band of dead black above the instruments, which reads as an empty rack rather
		# than a store — the brief's §4 wants shelving that looks used.
		var upper := _nine(BOARD, BOARD_M)
		upper.position = Vector2(rect.position.x + 5.0, top + 24.0)
		upper.size = Vector2(rect.size.x - 10.0, board_h)
		upper.material = lit(vp_of(host), "res://assets/ui/stations/qm_board_n.png", 0.24)
		host.add_child(upper)
		dress.append(Rect2(
			upper.position.x + 6.0, upper.position.y - 16.0,
			upper.size.x - 12.0, 16.0))

		# The plank objects stand on, at the foot of the unit.
		var board := _nine(BOARD, BOARD_M)
		board.position = Vector2(rect.position.x + 5.0, top + unit_h - board_h - 9.0)
		board.size = Vector2(rect.size.x - 10.0, board_h)
		board.material = lit(vp_of(host), "res://assets/ui/stations/qm_board_n.png", 0.24)
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
	c.material = lit(vp_of(host), "res://assets/ui/stations/qm_counter_n.png", 0.32)
	host.add_child(c)

	# THREE ZONES (R371), so the bench reads as a place someone works rather than a
	# plank with ornaments on it: the Quartermaster WRITES on the left, the instrument
	# is inspected in the middle, and the SEALING tools live on the right, next to the
	# light. The centre is deliberately clear — that space is where the object lands.
	#
	# Every prop is scenery: ignore-filtered, unfocusable, no tooltip (P169). A room
	# must not offer an affordance it will not honour.
	var top := rect.position.y - 19.0
	# left — the lamp, then the writing set beside it
	var vp0 := vp_of(host)
	_flicker(_prop(host, P_LAMP, lamp_pos(vp0)))
	_prop(host, P_PAPERS, Vector2(rect.position.x + 36.0, top + 2.0))
	_prop(host, P_LEDGER, Vector2(rect.position.x + 60.0, top))
	_prop(host, P_INK,    Vector2(rect.position.x + 86.0, top + 1.0))
	# right — the sealing end, and the light that serves it
	_prop(host, P_SCALE,  Vector2(rect.end.x - 34.0, top - 1.0))
	_prop(host, P_WAX,    Vector2(rect.end.x - 62.0, top + 2.0))
	# Placed FROM the rig's constants, so flame and light are the same point by
	# construction (the coupling the board keeps between its sconce and `torch_rig`, P95).
	var vp := vp_of(host)
	var candle := _prop(host, P_CANDLE, candle_pos(vp))
	_flicker(candle)
	_dust(host, rect)


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


## A little dust in the candle's reach — the room is old and worked in (R377). Kept
## to a handful and confined to the counter's warm end: this is a dusty storeroom, not
## weather, and the brief is explicit that fog is wrong for it.
static func _dust(host: Control, rect: Rect2) -> void:
	var p := CPUParticles2D.new()
	p.amount = DUST_COUNT
	p.lifetime = 9.0
	p.preprocess = 6.0
	p.position = Vector2(rect.end.x - 70.0, rect.position.y - 6.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(58.0, 26.0)
	p.direction = Vector2(-1, -0.35)
	p.spread = 26.0
	p.gravity = Vector2(0, -1.5)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 4.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.0
	p.color = Color(0.86, 0.76, 0.56, 0.30)
	host.add_child(p)


## The room's one moving thing. A looping tween, NOT a particle emitter and NOT
## `_process`: the budget allows twenty particles for dust and nothing for a flame
## that a modulate can carry just as well.
static func _flicker(node: CanvasItem) -> void:
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "modulate", Color(1.06, 1.02, 0.94), 1.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", Color(0.94, 0.92, 0.90), 2.3).set_trans(Tween.TRANS_SINE)


# ── builders ────────────────────────────────────────────────────────────────

## The frame this room is drawn into. The shader needs it for the aspect ratio and for
## placing lights in screen space, and the sub-builders only receive rects.
static func vp_of(host: Control) -> Vector2:
	return host.get_viewport().get_visible_rect().size


static func _nine(path: String, margin: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(margin))
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p
