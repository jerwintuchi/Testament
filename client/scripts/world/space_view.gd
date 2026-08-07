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
const DARK := Color(0.32, 0.28, 0.26)     # what the hall looks like away from every flame
const LIGHT_WARM := Color(1.0, 0.76, 0.45)
const LIGHT_ENERGY := 1.20
const LIGHT_REACH := 6.5                  # in tiles, to the edge of the falloff
const MAX_LIGHTS := 6                     # the budget ceiling (R298); asserted, not hoped for

@onready var _tiles: TileMapLayer = $Tiles
@onready var _markers: Node2D = $Markers
@onready var _lights: Node2D = $Lights
@onready var _modulate: CanvasModulate = $Modulate

var _grid: Dictionary = {}

## Replace what is drawn: repaint the tile grid and re-place the markers.
func set_space(grid: Dictionary, markers: Array) -> void:
	_grid = grid
	_paint_tiles(grid)
	_light_space(grid, markers)
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
	var at: Array[Vector2] = [centre]
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


func _place_markers(markers: Array) -> void:
	for c in _markers.get_children():
		c.queue_free()
	for m in markers:
		var node := MARKER.instantiate()
		node.position = Vector2(int(m["x"]) * TILE + TILE * 0.5, int(m["y"]) * TILE + TILE * 0.5)
		var label := node.get_node_or_null("Kind")
		if label:
			# The player never reads the wire's enum: DEPLOY_GATE renders "Deploy Gate" (R224).
			label.text = StationNames.of(str(m["kind"]))
		_markers.add_child(node)
