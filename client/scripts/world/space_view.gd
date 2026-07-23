class_name SpaceView
extends Node2D
## Render-only tile-space view (R102), built from nodes/scenes: a `TileMapLayer`
## (greybox `TileSet`) for the grid and instanced `marker.tscn`s for the
## stations/nodes. The same surface renders the Collegium and the field, because
## both are `{ grid, <markers> }`. Holds no NetClient/protocol ref and no phase
## knowledge — it renders what `set_space` gives it and sends nothing (P53).

const TILE := 16       # mirrors shared TILE_SIZE (render constant)
const SOLID := "#"     # mirrors shared TILE_SOLID
const SOURCE_ID := 0   # the single atlas source in tiles.tres
const FLOOR_CELL := Vector2i(0, 0)   # atlas coords: floor tile
const SOLID_CELL := Vector2i(1, 0)   # atlas coords: wall tile
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
			_tiles.set_cell(Vector2i(tx, ty), SOURCE_ID, SOLID_CELL if solid else FLOOR_CELL)

func _place_markers(markers: Array) -> void:
	for c in _markers.get_children():
		c.queue_free()
	for m in markers:
		var node := MARKER.instantiate()
		node.position = Vector2(int(m["x"]) * TILE + TILE * 0.5, int(m["y"]) * TILE + TILE * 0.5)
		var label := node.get_node_or_null("Kind")
		if label:
			label.text = str(m["kind"])
		_markers.add_child(node)
