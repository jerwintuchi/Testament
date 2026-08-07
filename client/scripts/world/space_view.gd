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

@onready var _tiles: TileMapLayer = $Tiles
@onready var _markers: Node2D = $Markers

var _grid: Dictionary = {}

## Replace what is drawn: repaint the tile grid and re-place the markers.
func set_space(grid: Dictionary, markers: Array) -> void:
	_grid = grid
	_paint_tiles(grid)
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
