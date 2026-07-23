extends Control
## Primary-verb type badge — a hand-painted RASTER sigil (TD-046; was runtime-drawn).
## It encodes the contract's PRIMARY VERB, which is asserted intel, never the hidden
## trait roll (I3). Pure display; preloaded as `VerbBadge` (TD-029/30 convention).
##
## The PNG is a PALE sigil on transparent, so a runtime modulate tints it either
## ink-on-parchment (notice corner) or gilt-on-dark (the board legend), keeping its form.

const SZ := 16.0

const BADGE_TEX := {
	"INVESTIGATE": "res://assets/ui/badge_investigate.png",
	"ELIMINATE":   "res://assets/ui/badge_eliminate.png",
	"CAPTURE":     "res://assets/ui/badge_capture.png",
	"BANISH":      "res://assets/ui/badge_banish.png",
}
const INK := Color(0x2A / 255.0, 0x21 / 255.0, 0x15 / 255.0)   # #2A2115 — brown-black ink

# Sacred-register label per verb, used by the board legend so the icon key reads in the
# Collegium's own words (INVESTIGATE→Inquiry, etc.); mirrors Notice.headline intent.
const LABEL := {
	"INVESTIGATE": "Inquiry",
	"ELIMINATE": "Sanction",
	"CAPTURE": "Containment",
	"BANISH": "Rite of Banishment",
}

var _verb := "INVESTIGATE"
var _tex: Texture2D
var _col := INK        # tint; ink on parchment (cards), overridden gilt on the dark bar

func set_verb(v: String) -> void:
	_verb = v if BADGE_TEX.has(v) else "INVESTIGATE"
	_tex = load(BADGE_TEX[_verb]) as Texture2D
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	custom_minimum_size = Vector2(SZ, SZ)
	queue_redraw()

# Recolour the sigil (e.g. gilt on the dark bottom-bar legend, where ink would vanish).
func set_tint(c: Color) -> void:
	_col = c
	queue_redraw()

func _draw() -> void:
	if _tex != null:
		draw_texture_rect(_tex, Rect2(Vector2.ZERO, size), false, _col)
