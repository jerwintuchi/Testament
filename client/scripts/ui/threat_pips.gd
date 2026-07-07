extends Control
# Consumed via preload as `ThreatPips`, not a global class_name, so it resolves in
# a headless MCP run (TD-029/TD-030 convention, same as protocol.gd).
## Reusable threat readout (R117): filled diamonds up to the contract's tier, over
## a fixed maximum. Pure display — it maps the server's `tier` string to a pip
## count and never sees or shows a trait value. Reused on the Contract Board cards
## and the Deploy Gate summary.

const MAX_PIPS := 5
const PIP := 12                        # px per pip cell
const FILLED := Color(0.80, 0.29, 0.29)  # threat red (danger accent, art direction)
const EMPTY := Color(0.34, 0.30, 0.30)

# Tier → how many pips are lit. Only three tiers exist today (signs.ts Tier);
# raising the ceiling later is a data change here, not a shape change.
const TIER_LEVEL := { "APPRENTICE": 3, "JOURNEYMAN": 4, "MASTER": 5 }

var _level := 0

func set_tier(tier: String) -> void:
	_level = int(TIER_LEVEL.get(tier, 1))
	custom_minimum_size = Vector2(MAX_PIPS * PIP, PIP)
	queue_redraw()

func _draw() -> void:
	for i in MAX_PIPS:
		var cx := i * PIP + PIP * 0.5
		var cy := PIP * 0.5
		var r := 4.0
		var pts := PackedVector2Array([
			Vector2(cx, cy - r), Vector2(cx + r, cy),
			Vector2(cx, cy + r), Vector2(cx - r, cy)])
		if i < _level:
			draw_colored_polygon(pts, FILLED)
		else:
			var outline := pts
			outline.append(pts[0])
			draw_polyline(outline, EMPTY, 1.0)
