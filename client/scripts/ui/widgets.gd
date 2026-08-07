## Shared render-only UI widget builders: pure/transient Control factories (labels, rules,
## focus rings, engraved lettering) used across the placeholder screens and the Contract Board.
## A preloaded RefCounted namespace (S3.2) — no state, no owned nodes; `h1` builds on a host.
extends RefCounted

const Fonts = preload("res://scripts/ui/fonts.gd")

# The Ash & Ember ink ramp. Shared: the live writs on the wall and the enlarged reader both
# ink their headlines with it, so it lives here rather than being duplicated once the reader
# moves out of main.gd (TD-067 T230). The parchment floor tone guarantees these clear the
# 4.5:1 contrast floor wherever a writ lands (T145/L1).
const INK := Color("2A2115")
const INK_SOFT := Color("3D3120")

static func card_label(text: String, size: int, color: Color, do_wrap: bool, center: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if do_wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if center:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

# A thin ruled line (a scribe's rule under a heading).
static func hrule(color: Color) -> Control:
	var r := ColorRect.new()
	r.color = color
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

# A gilt keyboard-focus ring (T146 / L6): a gold border + soft warm glow, drawn as a control's
# `focus` stylebox so Tab-traversal is always visible on the dark wall. Reused by the live
# notices and the seal stamp so keyboard focus reads the same everywhere.
static func focus_ring() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.95, 0.80, 0.38)          # gilt gold
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0.90, 0.68, 0.26, 0.55)    # warm bleed off the gilt edge
	sb.shadow_size = 5
	return sb

# One line of ENGRAVED lettering: a dark incised cut with a lit face riding a pixel below it,
# so the glyphs read as chiselled into the plank rather than inked onto it (carved cathedral
# signage). Both labels share the rect; only the face carries the soft down-right AO.
static func engraved_line(text: String, size: int, face_color: Color, weight: int) -> Control:
	var font := Fonts.cinzel(weight)
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size = Vector2(0, size + 1)
	for pass_i in 2:
		var is_cut := pass_i == 0
		var l := card_label(text, size, Color(0.05, 0.03, 0.01, 0.92) if is_cut else face_color, false, true)
		if font != null:
			l.add_theme_font_override("font", font)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position.y = -1.0 if is_cut else 0.0
		if not is_cut:
			# Aged gilt: worn back off full strength so it reads as centuries-old leaf.
			l.modulate = Color(1, 1, 1, 0.94)
			l.add_theme_constant_override("shadow_offset_x", 1)
			l.add_theme_constant_override("shadow_offset_y", 1)
			l.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.01, 0.85))
		row.add_child(l)
	return row

static func h1(host: Node, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 17)
	host.add_child(l)


## The Collegium's laurel, one branch, marking a chosen action (TD-077, shared by TD-080).
## The art is the RIGHT branch; the left is it mirrored, so the pair opens outward around the word
## the way the crest's wreath opens around the blade. Starts unlit and KEEPS ITS SPACE, so marking
## an option never shifts the lettering (P133).
##
## Lives here rather than in either caller because both the title menu and the join writ mark focus
## with it — it is shared visual language, and a second copy would drift.
static func laurel(pointing_right: bool) -> TextureRect:
	var s := TextureRect.new()
	s.texture = load("res://assets/ui/shared/menu_sigil.png") as Texture2D
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# 17x15 LOGICAL for 34x30 of art: at a 720p window PixelScale renders the 640x360 viewport into
	# 1280x720 device pixels, so half the art's size on this side of the scale is 1:1 on that one.
	s.custom_minimum_size = Vector2(17, 15)
	s.flip_h = pointing_right          # the art points right; the LEFT copy is the mirrored one
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s.modulate.a = 0.0
	return s
