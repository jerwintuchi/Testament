extends Control
## Origin-keyed wax seal — commission-wall vocabulary (R111/R117). The wax colour
## and pressed sigil encode the contract's ASSERTED Origin (Belief / Sin / Relic),
## which is a claim the contract makes — falsifiable, never the hidden trait roll —
## so a player learns to read the board at a glance without spoiling anything (I3).
## Pure display. Consumed via preload as `WaxSeal`, not a global class_name, so it
## resolves in a headless MCP run (TD-029/30 convention, same as protocol.gd).

const R := 9.0   # wax radius (px); the control sizes itself to 2R square
const OUTLINE := Color(0x12 / 255.0, 0x10 / 255.0, 0x0C / 255.0)  # Ash&Ember black — a full-
                                       # strength outer ring, so the seal keeps a ≥3:1 edge
                                       # against parchment even when its fill goes faint.
const FAINT_PAPER := Color(0.80, 0.72, 0.55)  # the tone the faint fill washes toward

# Asserted origin -> wax fill + darker rim. Distinct hues so the three read apart
# instantly: Belief indigo (thought), Sin crimson (deed), Relic tarnished gold (matter).
# Hue is REDUNDANT though — the pressed sigil SHAPE is the primary Origin cue (DESIGN).
const WAX := {
	"BELIEF": { "fill": Color(0.24, 0.27, 0.52), "rim": Color(0.11, 0.13, 0.30) },
	"SIN":    { "fill": Color(0.64, 0.14, 0.14), "rim": Color(0.32, 0.05, 0.05) },
	"RELIC":  { "fill": Color(0.51, 0.40, 0.14), "rim": Color(0.28, 0.20, 0.06) },
}

var _origin := "SIN"
var _faint := false   # unsealed (pending) — fill washes toward parchment; ring + sigil stay firm

func set_origin(o: String) -> void:
	_origin = o if WAX.has(o) else "SIN"
	custom_minimum_size = Vector2(R * 2.0, R * 2.0)
	queue_redraw()

# Unsealed/faint (the leader has not stamped this charge yet): only the fill fades,
# so it never reads as bare parchment (DESIGN — faint keeps a full-strength ring).
func set_faint(faint: bool) -> void:
	_faint = faint
	queue_redraw()

func _draw() -> void:
	var c := Vector2(R, R)
	var pal: Dictionary = WAX[_origin]
	draw_circle(c, R, OUTLINE)             # full-strength black edge (survives a faint fill)
	draw_circle(c, R - 1.0, pal["rim"])    # rim
	var body: Color = pal["fill"]
	if _faint:
		body = body.lerp(FAINT_PAPER, 0.6) # washed, pending — but ring + sigil below stay firm
	draw_circle(c, R - 2.0, body)          # wax body
	# A pressed sigil, one per genus — the Origin cue that does not depend on hue.
	# A pale impression on the dark wax; kept full-strength so it reads in gloom / when faint.
	var ink: Color = (pal["fill"] as Color).lightened(0.62)
	match _origin:
		"BELIEF":
			# An open eye — corrupted thought, watched.
			draw_arc(c, 4.4, 0.22, PI - 0.22, 16, ink, 1.6)
			draw_arc(c, 4.4, PI + 0.22, TAU - 0.22, 16, ink, 1.6)
			draw_circle(c, 1.8, ink)
		"SIN":
			# An inverted cross — corrupted deed.
			draw_line(c + Vector2(0.0, -4.8), c + Vector2(0.0, 4.8), ink, 1.8)
			draw_line(c + Vector2(-3.2, -1.8), c + Vector2(3.2, -1.8), ink, 1.8)
		"RELIC":
			# A diamond reliquary — corrupted matter.
			var d := PackedVector2Array([
				c + Vector2(0.0, -4.8), c + Vector2(3.8, 0.0),
				c + Vector2(0.0, 4.8), c + Vector2(-3.8, 0.0),
				c + Vector2(0.0, -4.8)])
			draw_polyline(d, ink, 1.6)
