extends Control
## Origin-keyed wax seal — a hand-painted RASTER emblem (TD-046; was runtime-drawn).
## The wax colour and pressed sigil encode the contract's ASSERTED Origin
## (Belief / Sin / Relic), a claim the contract makes — falsifiable, never the hidden
## trait roll (I3) — so a player reads the board at a glance without spoiling anything.
## Pure display. Preloaded as `WaxSeal`, not a global class_name, so it resolves in a
## headless run (TD-029/30). Textures are authored by `assets/ui/gen_emblems.py`.

const SEAL_TEX := {
	"BELIEF": "res://assets/ui/seal_belief.png",
	"SIN":    "res://assets/ui/seal_sin.png",
	"RELIC":  "res://assets/ui/seal_relic.png",
}
# A firm dark edge held over a FAINT (unsealed) seal, so a pending charge never washes
# to bare parchment — the fill fades but the ring stays (DESIGN heritage).
const RIM := Color(0x12 / 255.0, 0x10 / 255.0, 0x0C / 255.0, 0.85)

var _origin := "SIN"
var _tex: Texture2D
var _faint := false

func set_origin(o: String) -> void:
	_origin = o if SEAL_TEX.has(o) else "SIN"
	_tex = load(SEAL_TEX[_origin]) as Texture2D
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
