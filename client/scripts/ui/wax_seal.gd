extends Control
## The Collegium's wax seal — the ONE generic seal (TD-060; was Origin-keyed, archived).
## Oxblood wax with the order's device debossed: the leader stamps it on an open charge
## (reversible SELECT_CONTRACT, R124/TD-041). It asserts the COLLEGIUM's taking-up, never
## a genus — the asserted Origin is prose in the reader, not wax. Pure display. Preloaded
## as `WaxSeal`, not a global class_name, so it resolves headless (TD-029/30). Texture is
## authored by `assets/ui/gen_emblems.py` (@consumes collegium_logo.png).

const SEAL_TEX := "res://assets/ui/seal_collegium.png"
# A firm dark edge held over a FAINT (unsealed) seal, so a pending charge never washes
# to bare parchment — the fill fades but the ring stays (DESIGN heritage).
const RIM := Color(0x12 / 255.0, 0x10 / 255.0, 0x0C / 255.0, 0.85)

var _tex: Texture2D
var _faint := false

func _ready() -> void:
	_tex = load(SEAL_TEX) as Texture2D
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # painted emblem scales smoothly
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(20, 20)
	queue_redraw()

# Unsealed/pending: the wax fill fades, but a firm ring is kept so the seal still reads.
func set_faint(faint: bool) -> void:
	_faint = faint
	queue_redraw()

func _draw() -> void:
	if _tex == null:
		return
	var rect := Rect2(Vector2.ZERO, size)
	if _faint:
		draw_texture_rect(_tex, rect, false, Color(1, 1, 1, 0.5))
		var c := size * 0.5
		draw_arc(c, minf(size.x, size.y) * 0.5 - 1.5, 0.0, TAU, 40, RIM, 1.5)
	else:
		draw_texture_rect(_tex, rect, false)
