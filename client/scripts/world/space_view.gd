class_name SpaceView
extends Node2D
## Render-only tile-space view (R102), built from nodes/scenes: a `TileMapLayer`
## (greybox `TileSet`) for the grid and instanced `marker.tscn`s for the
## stations/nodes. The same surface renders the Collegium and the field, because
## both are `{ grid, <markers> }`. Holds no NetClient/protocol ref and no phase
## knowledge — it renders what `set_space` gives it and sends nothing (P53).

const StationNames = preload("res://scripts/core/station_names.gd")

const TILE := 16       # mirrors shared TILE_SIZE (render constant)
const SOLID := "#"     # mirrors shared TILE_SOLID
const SOURCE_ID := 0   # the single atlas source in tiles.tres
# The atlas is 4x2 of 16x16 cells (gen_collegium_tiles.py, TD-081):
#   row 0  four flagstone variants
#   (0,1)  a flag lying under a wall — carries the shadow the wall casts down onto it
#   (1..3,1) three wall variants
const FLOOR_VARIANTS := 4
const WALL_VARIANTS := 3
const UNDER_WALL_CELL := Vector2i(0, 1)


## Which variant a tile takes — a pure function of its own coordinates, so the hall looks the same
## on every client and every launch (P144). Not `randi()`: two players standing in the same room
## must be standing on the same floor.
static func _variant(tx: int, ty: int, n: int) -> int:
	var h := (tx * 374761393 + ty * 668265263) & 0x7FFFFFFF
	h = (h ^ (h >> 13)) * 1274126177 & 0x7FFFFFFF
	return (h >> 11) % n
const MARKER := preload("res://scenes/marker.tscn")
const Fonts := preload("res://scripts/ui/fonts.gd")

# A station is an OBJECT, not a coloured square with its name floating over it (TD-081 T313/T314).
# The proximity prompt already reads "Press E: <Station>" on approach, so a permanent caption in the
# default sans was the same information twice, in the wrong typeface, never switched off. An object
# you can recognise does not need one — and if it does, the object is wrong.
# Anything without art here (the field's nodes) still falls back to the labelled marker.
const STATION_ART := {
	"CONTRACT_BOARD": "res://assets/ui/stations/contract_board.png",
	"QUARTERMASTER": "res://assets/ui/stations/quartermaster.png",
	"DEPLOY_GATE": "res://assets/ui/stations/deploy_gate.png",
}

# ── Lighting (TD-081 T312) ───────────────────────────────────────────────────
# `SpaceView` is a Node2D, so Light2D genuinely reaches it — TD-047's "lights don't work" finding is
# about CONTROL nodes and was over-applied for four specs (TD-083). This is the bible's lighting
# pillar (TD-043) satisfied literally rather than approximated with additive sprites.
#
# A CanvasModulate is half the effect: without it the tiles render at their authored value and a
# light can only ADD, which gives a bright hall with a brighter pool in it rather than a dark hall
# with light carved out of it. It affects this CanvasLayer only, so the HUD (its own layers) is
# untouched.
# The AMBIENT is the knob for "how dark is this hall", never the texture. Darkening the diffuse
# darkens the lit pools too and defeats the rig; darkening the ambient deepens only what no lamp
# reaches, so contrast goes UP and the stone stays readable where light falls (author's call after
# T312: the intermediate near-black passes had the right mood but lost the floor entirely).
const DARK := Color(0.25, 0.22, 0.20)     # what the hall looks like away from every flame
const LIGHT_WARM := Color(1.0, 0.76, 0.45)
# 0.45, not 0.90. A 2D light ADDS, so at the core it was contributing ~230 to a channel: the dark
# floor has the headroom to take that, but anything already bright does not — the Seeker's skin
# clipped straight to orange and read as a glowing character. The floor still lights well because it
# is dark (it has all the headroom in the room); the cap exists for everything that is not.
const LIGHT_ENERGY := 0.45
const LIGHT_REACH := 6.5                  # in tiles, to the edge of the falloff
const MAX_LIGHTS := 6                     # the budget ceiling (R298); asserted, not hoped for
const DUST_COUNT := 24                    # well inside the 60-particle ceiling

@onready var _tiles: TileMapLayer = $Tiles
@onready var _markers: Node2D = $Markers
@onready var _lights: Node2D = $Lights
@onready var _modulate: CanvasModulate = $Modulate
@onready var _dust_root: Node2D = $Dust

var _grid: Dictionary = {}

## Replace what is drawn: repaint the tile grid and re-place the markers.
func set_space(grid: Dictionary, markers: Array) -> void:
	_grid = grid
	_paint_tiles(grid)
	_light_space(grid, markers)
	_dust(grid)
	_place_markers(markers)

## Pixel extent of the current grid — used to clamp the camera.
func grid_size_px() -> Vector2:
	if _grid.is_empty():
		return Vector2.ZERO
	return Vector2(int(_grid["width"]) * TILE, int(_grid["height"]) * TILE)

func _paint_tiles(grid: Dictionary) -> void:
	_tiles.clear()
	var rows: Array = grid["rows"]
	var w := int(grid["width"])
	var h := int(grid["height"])
	for ty in h:
		var row: String = str(rows[ty])
		for tx in w:
			var solid := tx < row.length() and row[tx] == SOLID
			var cell: Vector2i
			if solid:
				cell = Vector2i(1 + _variant(tx, ty, WALL_VARIANTS), 1)
			elif ty > 0 and _solid_at(rows, tx, ty - 1):
				# A wall stands directly above: this flag takes its shadow. Top-down convention puts
				# the light overhead, so this is the join the eye actually checks.
				cell = UNDER_WALL_CELL
			else:
				cell = Vector2i(_variant(tx, ty, FLOOR_VARIANTS), 0)
			_tiles.set_cell(Vector2i(tx, ty), SOURCE_ID, cell)

## Hang the hall's lights. Positions are DERIVED from the snapshot — a light per station, one over
## the central atrium, and two on the walk between them — so decoration never invents geometry the
## server did not send (P143).
func _light_space(grid: Dictionary, markers: Array) -> void:
	for n in _lights.get_children():
		n.queue_free()
	if OS.get_cmdline_user_args().has("--lights-off"):
		_modulate.color = Color(1, 1, 1)      # the unlit control: no darkening, no lamps
		return
	_modulate.color = DARK

	var w := int(grid.get("width", 0))
	var h := int(grid.get("height", 0))
	var centre := Vector2(w * TILE * 0.5, h * TILE * 0.5)
	# The atrium lamp is offset off the spawn tile. It sat 8px from it, so the player materialised
	# inside the light's core — a lamp stands beside you, not on your head.
	var at: Array[Vector2] = [centre + Vector2(0, TILE * -2.0)]
	for m in markers:
		at.append(Vector2(int(m["x"]) * TILE + TILE * 0.5, int(m["y"]) * TILE + TILE * 0.5))
	# The walk: halfway between the atrium and the two furthest stations, so crossing the hall
	# passes through light rather than through one unbroken dark middle.
	var stations := at.slice(1)
	stations.sort_custom(func(a, b): return a.distance_to(centre) > b.distance_to(centre))
	for i in mini(2, stations.size()):
		at.append(centre.lerp(stations[i], 0.55))

	for i in mini(MAX_LIGHTS, at.size()):
		var l := PointLight2D.new()
		l.texture = _light_tex()
		l.color = LIGHT_WARM
		l.energy = LIGHT_ENERGY
		# `texture_scale` sizes the falloff off the 256px radial, in tiles.
		l.texture_scale = (LIGHT_REACH * 2.0 * TILE) / 256.0
		l.position = at[i]
		_lights.add_child(l)


## Dust hanging in the hall's air (R297). Same grammar as the title screen's: it DRIFTS rather than
## rising — a negative gravity reads as heat or smoke, which is what this room is not — it is slow
## enough to be noticed only after a moment, and its opacity varies per mote so the field is
## near-invisible except where a lamp finds it.
##
## Unlike the title's, this one is a WORLD object, so the lights reach it: a mote is dim in the dark
## and catches the light when it drifts through a pool, which is the whole reason to put it here
## rather than over the top as a UI overlay.
func _dust(grid: Dictionary) -> void:
	for n in _dust_root.get_children():
		n.queue_free()
	if OS.get_cmdline_user_args().has("--lights-off"):
		return
	var w := int(grid.get("width", 0)) * TILE
	var h := int(grid.get("height", 0)) * TILE
	var p := CPUParticles2D.new()
	p.texture = _light_tex()
	p.amount = DUST_COUNT
	p.lifetime = 46.0
	p.lifetime_randomness = 0.6
	p.preprocess = 46.0                  # the air is already in motion when the hall opens
	p.randomness = 0.7
	p.position = Vector2(w * 0.5, h * 0.5)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(w * 0.5, h * 0.5)
	p.direction = Vector2(1, 0)
	p.spread = 180.0                     # no preferred direction: still air, not a draught
	p.gravity = Vector2(0.6, -0.25)
	p.initial_velocity_min = 0.2
	p.initial_velocity_max = 1.4
	p.scale_amount_min = 0.006           # ~1px off the 128px radial
	p.scale_amount_max = 0.018
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.25, Color(1, 1, 1, 1.0))
	ramp.add_point(0.72, Color(1, 1, 1, 1.0))
	p.color_ramp = ramp
	p.color = Color(0.96, 0.90, 0.76, 0.30)
	p.z_index = 2                        # above the floor, below nothing that matters
	_dust_root.add_child(p)


## The lamp's falloff, built once. A deterministic generator rebuilt per space change is exactly the
## per-frame-adjacent waste S6/TD-064 exists to stop.
static var _light_tex_cache: GradientTexture2D = null

static func _light_tex() -> GradientTexture2D:
	if _light_tex_cache != null:
		return _light_tex_cache
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	# A touch of curve: a linear falloff reads as a cone edge, not as lamplight.
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 256
	t.height = 256
	_light_tex_cache = t
	return t


static func _solid_at(rows: Array, tx: int, ty: int) -> bool:
	if ty < 0 or ty >= rows.size():
		return false
	var row: String = str(rows[ty])
	return tx < row.length() and row[tx] == SOLID


## A notice hung ABOVE a station, in the world, rather than a subtitle across the foot
## of the screen. The prompt is about a thing you are standing in front of, so it belongs
## on that thing — a caption at the bottom of the viewport reads as UI chrome and makes
## the player look away from what they are addressing.
##
## It FADES rather than snapping: a notice that pops on and off at the radius edge
## flickers when you stand on the boundary, and the fade also reads as the station
## noticing you.
const NOTICE_W := 150.0
const NOTICE_H := 30.0
const KEY_E := "res://assets/ui/shared/key_e.png"
const FADE := 0.16

func set_notice(kind: String, text: String, warn: bool, keyed: bool = false) -> void:
	for c in _markers.get_children():
		if not (c is Sprite2D):
			continue
		var n: Control = c.get_node_or_null("Notice")
		if c.get_meta("station_kind", "") != kind:
			if n != null:
				_fade(n, 0.0)
			continue
		if n == null:
			n = _notice()
			c.add_child(n)
		# EARLY-OUT. set_notice runs every frame from _update_stations, and re-laying a
		# Container each frame (setting `size` while it recomputes its own minimum) thrashed
		# layout badly enough to hang the client. Nothing here changes unless the words do.
		var stamp := "%s|%s|%s" % [text, warn, keyed]
		if n.get_meta("stamp", "") != stamp:
			n.set_meta("stamp", stamp)
			_paint(n, text, warn, keyed)
			# Centre on the row's OWN width, not a guessed box: the words plus the keycap
			# are wider than any fixed NOTICE_W, so a fixed offset threw it left and clipped.
			# ONE LINE, deliberately. Wrapping was attempted twice and abandoned: an
			# autowrapped Label inside an HBoxContainer reports its minimum height at its
			# minimum WIDTH (one word per line), which measured 585px and threw the notice
			# off the top of the screen; measuring against the draw width instead left it
			# clipped to a fragment. The viewport clamp below is what the overflow actually
			# needed, so the notice stays a single line and short copy is the discipline.
			var m := n.get_combined_minimum_size()
			var w: float = maxf(m.x, 1.0)
			var h: float = maxf(m.y, NOTICE_H)
			n.size = Vector2(w, h)
			n.set_meta("w", w)
			n.set_meta("h", h)
		# EVERY FRAME, not only on change: the camera moves, so a notice centred on a
		# station near a wall walks off the edge of the screen as the player approaches.
		# Position only — no layout — so this stays cheap.
		_place_in_view(n, c as Sprite2D, float(n.get_meta("w", NOTICE_W)))
		# `keyed` carries its own words, so an empty `text` is NOT an empty notice —
		# checking text alone faded the keycap hint straight back out.
		_fade(n, 1.0 if (text != "" or keyed) else 0.0)


func clear_notices() -> void:
	for c in _markers.get_children():
		if c is Sprite2D:
			var n: Control = c.get_node_or_null("Notice")
			if n != null:
				_fade(n, 0.0)


## Centre the notice over its station, then keep it inside the viewport.
##
## A notice belongs to a thing in the world, so it is centred on that thing — but the
## Hall's stations stand against walls, and a centred label on a station near the left
## wall simply hangs off the screen (author playtest). Clamped in SCREEN space against
## the live camera, then converted back to the node's local space, so the notice slides
## along the station rather than being cut in half by the frame edge.
##
## THE RULE THIS ESTABLISHES: anything that points at a world object — prompt, hint,
## damage number, name — must be clamped to the viewport, because the camera decides
## where the object is and the camera is not a designer.
const VIEW_MARGIN := 10.0

static func _place_in_view(n: Control, host: Sprite2D, w: float) -> void:
	var y: float = -float(host.texture.get_height()) - float(n.get_meta("h", NOTICE_H)) + 4.0
	var xf := host.get_global_transform_with_canvas()
	var sc: float = maxf(xf.get_scale().x, 0.001)
	var vw: float = n.get_viewport_rect().size.x
	var want_left: float = xf.origin.x - w * sc * 0.5          # centred on the station
	var lo := VIEW_MARGIN
	var hi: float = maxf(vw - VIEW_MARGIN - w * sc, lo)        # never negative-width
	var left: float = clampf(want_left, lo, hi)
	n.position = Vector2((left - xf.origin.x) / sc, y)


static func _fade(n: Control, to: float) -> void:
	# Compare against the TARGET, not the current alpha. _update_stations runs every
	# frame, so comparing current alpha restarted the tween each frame and it never
	# got to step — the notice sat at zero and looked like it was never created.
	if is_equal_approx(float(n.get_meta("fade_to", -1.0)), to):
		return
	n.set_meta("fade_to", to)
	if n.has_meta("tw"):
		var old: Tween = n.get_meta("tw")
		if old != null and old.is_valid():
			old.kill()
	var tw := n.create_tween()
	tw.tween_property(n, "modulate:a", to, FADE)
	n.set_meta("tw", tw)


## The notice is a row — words, a drawn keycap, words — so the key is READ rather than
## parsed out of a sentence. Body text takes the project face (Almendra, TD-097), which has
## a true lowercase — the notice is a sentence a station says, not an inscription.
static func _notice() -> Control:
	var root := HBoxContainer.new()
	root.name = "Notice"          # must match the get_node above, or every call adds ANOTHER
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 3)
	root.modulate.a = 0.0

	root.add_child(_line("pre"))
	var key := TextureRect.new()
	key.name = "Key"
	key.texture = load(KEY_E) as Texture2D
	key.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	key.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	key.custom_minimum_size = Vector2(11, 11)
	key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(key)
	root.add_child(_line("post"))
	return root


static func _line(n: String) -> Label:
	var l := Label.new()
	l.name = n
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 7)
	l.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.02, 0.95))
	l.add_theme_constant_override("outline_size", 4)
	return l


static func _paint(n: Control, text: String, warn: bool, keyed: bool) -> void:
	var pre: Label = n.get_node("pre")
	var post: Label = n.get_node("post")
	var key: TextureRect = n.get_node("Key")
	var tone := Color(0.94, 0.76, 0.64) if warn else Color(0.96, 0.90, 0.76)
	pre.add_theme_color_override("font_color", tone)
	post.add_theme_color_override("font_color", tone)
	key.visible = keyed
	if keyed:
		pre.text = "Press"
		post.text = "to interact"
	else:
		pre.text = text
		post.text = ""


func _place_markers(markers: Array) -> void:
	for c in _markers.get_children():
		c.queue_free()
	for m in markers:
		var kind := str(m["kind"])
		var art: String = STATION_ART.get(kind, "")
		var tex := load(art) as Texture2D if art != "" and ResourceLoader.exists(art) else null
		if tex != null:
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			# Anchor the object's FOOT to the bottom of its tile: it stands in the room the way the
			# Seeker does, rather than floating centred on a grid square.
			sp.offset = Vector2(0, -tex.get_height() * 0.5)
			sp.position = Vector2(int(m["x"]) * TILE + TILE * 0.5, int(m["y"]) * TILE + TILE)
			sp.set_meta("station_kind", kind)
			_markers.add_child(sp)
		else:
			var node := MARKER.instantiate()
			node.position = Vector2(int(m["x"]) * TILE + TILE * 0.5, int(m["y"]) * TILE + TILE * 0.5)
			var label := node.get_node_or_null("Kind")
			if label:
				# The player never reads the wire's enum: DEPLOY_GATE renders "Deploy Gate" (R224).
				label.text = StationNames.of(kind)
			_markers.add_child(node)
