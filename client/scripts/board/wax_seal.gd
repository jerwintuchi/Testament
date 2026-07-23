extends Control
## The Collegium's wax seal — the ONE generic seal (TD-060; was Origin-keyed, archived).
## Oxblood wax with the order's device debossed: the leader stamps it on an open charge
## (reversible SELECT_CONTRACT, R124/TD-041). It asserts the COLLEGIUM's taking-up, never
## a genus — the asserted Origin is prose in the reader, not wax. Pure display. Preloaded
## as `WaxSeal`, not a global class_name, so it resolves headless (TD-029/30). Texture is
## authored by `assets/ui/gen_emblems.py` (@consumes collegium_logo.png).

const SEAL_TEX := "res://assets/ui/seal_collegium.png"
# The EMPTY SOCKET (TD-063/R203): unsealed, the control draws only a low-opacity dashed
# circle marking where the wax will land — the old ghost-wax texture + solid ring are gone
# (author ruling: broken lines, lower opacity, no faint seal).
const RIM := Color(0x12 / 255.0, 0x10 / 255.0, 0x0C / 255.0, 0.30)
const DASHES := 12          # arcs around the socket
const DASH_FRAC := 0.55     # portion of each slot that is ink (the rest is gap)

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
	# A centred SQUARE, whatever rect the container hands us (TD-062/R197): filling the
	# whole rect stretched the wax into an oval whenever the control ran taller than wide.
	var s := minf(size.x, size.y)
	if _faint:
		# The empty socket: a centred dashed circle, nothing else (R203).
		var c := size * 0.5
		var r := s * 0.5 - 2.0
		var slot := TAU / DASHES
		for i in DASHES:
			draw_arc(c, r, i * slot, i * slot + slot * DASH_FRAC, 6, RIM, 1.5)
	else:
		draw_texture_rect(_tex, Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s)), false)
