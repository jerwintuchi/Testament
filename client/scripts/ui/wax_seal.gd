extends Control
## Origin-keyed wax seal — commission-wall vocabulary (R111/R117). The wax colour
## and pressed sigil encode the contract's ASSERTED Origin (Belief / Sin / Relic),
## which is a claim the contract makes — falsifiable, never the hidden trait roll —
## so a player learns to read the board at a glance without spoiling anything (I3).
## Pure display. Consumed via preload as `WaxSeal`, not a global class_name, so it
## resolves in a headless MCP run (TD-029/30 convention, same as protocol.gd).

const R := 9.0   # wax radius (px); the control sizes itself to 2R square

# Asserted origin -> wax fill + darker rim. Distinct hues so the three read apart
# instantly: Belief indigo (thought), Sin crimson (deed), Relic tarnished gold (matter).
const WAX := {
	"BELIEF": { "fill": Color(0.24, 0.27, 0.52), "rim": Color(0.11, 0.13, 0.30) },
	"SIN":    { "fill": Color(0.64, 0.14, 0.14), "rim": Color(0.32, 0.05, 0.05) },
	"RELIC":  { "fill": Color(0.51, 0.40, 0.14), "rim": Color(0.28, 0.20, 0.06) },
}

var _origin := "SIN"

func set_origin(o: String) -> void:
	_origin = o if WAX.has(o) else "SIN"
	custom_minimum_size = Vector2(R * 2.0, R * 2.0)
	queue_redraw()

func _draw() -> void:
	var c := Vector2(R, R)
	var pal: Dictionary = WAX[_origin]
	draw_circle(c, R, pal["rim"])          # rim
	draw_circle(c, R - 1.5, pal["fill"])   # wax body
	# A pale pressed sigil, one per genus. Lightened wax so it reads as impressed,
	# not painted on.
	var ink: Color = (pal["fill"] as Color).lightened(0.45)
	match _origin:
		"BELIEF":
			# An open eye — corrupted thought, watched.
			draw_arc(c, 4.2, 0.25, PI - 0.25, 14, ink, 1.2)
			draw_arc(c, 4.2, PI + 0.25, TAU - 0.25, 14, ink, 1.2)
			draw_circle(c, 1.5, ink)
		"SIN":
			# An inverted cross — corrupted deed.
			draw_line(c + Vector2(0.0, -4.6), c + Vector2(0.0, 4.6), ink, 1.4)
			draw_line(c + Vector2(-3.0, -1.8), c + Vector2(3.0, -1.8), ink, 1.4)
		"RELIC":
			# A diamond reliquary — corrupted matter.
			var d := PackedVector2Array([
				c + Vector2(0.0, -4.6), c + Vector2(3.6, 0.0),
				c + Vector2(0.0, 4.6), c + Vector2(-3.6, 0.0),
				c + Vector2(0.0, -4.6)])
			draw_polyline(d, ink, 1.2)
