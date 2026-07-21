extends Control
## The quill-line scrollbar (TD-061 / R194): the reader's scroll position drawn as the
## user's ornament reference — a thin vertical line with a dot finial at each end and a
## chevroned diamond (lozenge) thumb riding it. Sits OUTSIDE the parchment sheet, on the
## dimmed board, in aged brass/gilt (candlelit register, no bloom — R175 heritage).
## INTERACTIVE (author ruling): the diamond drags, clicking the line jumps; wheel scrolling
## elsewhere is mirrored both ways. A view over one ScrollContainer's value — it holds no
## state beyond drag bookkeeping, emits nothing, and hides when the writ fits (P112).
## Preloaded, not a global class_name, so it resolves headless (TD-029/30).

const LINE := Color(0.52, 0.40, 0.19)        # aged brass line + finials
const THUMB := Color(0.80, 0.64, 0.32)       # gilt lozenge, brighter under drag
const THUMB_DRAG := Color(0.92, 0.76, 0.40)

const FINIAL_R := 2.5                        # end-dot radius
const DIAMOND_R := 7.0                       # lozenge half-diagonal
const END_INSET := 8.0                       # travel inset so the lozenge never eats a finial

var _scroll: ScrollContainer
var _dragging := false

func attach(scroll: ScrollContainer) -> void:
	_scroll = scroll
	# Width floor only — the HEIGHT is the caller's (it sizes the line to the sheet);
	# assigning the whole Vector2 here collapsed the line to zero span.
	custom_minimum_size.x = maxf(custom_minimum_size.x, DIAMOND_R * 2.0 + 4.0)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var vsb := scroll.get_v_scroll_bar()
	vsb.value_changed.connect(func(_v): queue_redraw())
	vsb.changed.connect(_refresh)
	resized.connect(queue_redraw)
	_refresh()

# Hidden entirely when the writ fits without scrolling — an ornament with nothing to
# say would read as a broken control.
func _refresh() -> void:
	if _scroll == null:
		return
	var vsb := _scroll.get_v_scroll_bar()
	visible = vsb.max_value - vsb.page > 0.5
	queue_redraw()

func _ratio() -> float:
	if _scroll == null:
		return 0.0
	var vsb := _scroll.get_v_scroll_bar()
	var span := vsb.max_value - vsb.page
	return 0.0 if span <= 0.0 else clampf(vsb.value / span, 0.0, 1.0)

func _apply_ratio(r: float) -> void:
	if _scroll == null:
		return
	var vsb := _scroll.get_v_scroll_bar()
	_scroll.scroll_vertical = int(round(clampf(r, 0.0, 1.0) * (vsb.max_value - vsb.page)))

func _travel() -> Vector2:
	# Top/bottom y of the lozenge centre's travel.
	return Vector2(FINIAL_R + END_INSET, size.y - FINIAL_R - END_INSET)

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		if e.pressed:
			_dragging = true
			var t := _travel()
			_apply_ratio((e.position.y - t.x) / maxf(1.0, t.y - t.x))
			accept_event()
		else:
			_dragging = false
			queue_redraw()
	elif e is InputEventMouseMotion and _dragging:
		var t := _travel()
		_apply_ratio((e.position.y - t.x) / maxf(1.0, t.y - t.x))
		accept_event()

func _draw() -> void:
	var cx := size.x * 0.5
	var top := Vector2(cx, FINIAL_R)
	var bot := Vector2(cx, size.y - FINIAL_R)
	draw_line(top, bot, LINE, 1.5)
	draw_circle(top, FINIAL_R, LINE)
	draw_circle(bot, FINIAL_R, LINE)
	# The lozenge: an outlined rotated square with an inner chevron pair (^ over v),
	# riding the line at the scroll ratio.
	var t := _travel()
	var c := Vector2(cx, lerpf(t.x, t.y, _ratio()))
	var col := THUMB_DRAG if _dragging else THUMB
	var r := DIAMOND_R
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0), c + Vector2(0, -r)])
	# A dark fill so the board never shows through the lozenge, then the gilt outline.
	draw_colored_polygon(PackedVector2Array(pts.slice(0, 4)), Color(0.09, 0.06, 0.035, 0.85))
	draw_polyline(pts, col, 1.2, true)
	var cr := r * 0.42
	draw_polyline(PackedVector2Array([c + Vector2(-cr, -1.2), c + Vector2(0, -1.2 - cr), c + Vector2(cr, -1.2)]), col, 1.0, true)
	draw_polyline(PackedVector2Array([c + Vector2(-cr, 1.2), c + Vector2(0, 1.2 + cr), c + Vector2(cr, 1.2)]), col, 1.0, true)
