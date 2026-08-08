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
	# Almendra has no variable weight axis, so the old numeric weight resolves to a role.
	var font := Fonts.heading() if weight >= 600 else Fonts.body()
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


## A menu choice in the Collegium's own voice: gilt Almendra, no button chrome, and the laurel marking
## whichever line has focus. Lives here because THREE screens now speak it — the title menu, and the
## pause menu that echoes it — and a third copy would drift from the other two.
##
## Moved verbatim from `main.gd._title_option` (TD-077/TD-084 tuning intact): the sigils keep their
## space when unlit so marking never shifts the lettering (P133), they ease over 175ms rather than
## snapping, and the selected line warms by +12% luminance — emphasis, not a highlight.
static func choice(host: Node, text: String, size: int, on_pressed: Callable) -> Button:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 5)

	var left := laurel(true)
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", size)
	var font := Fonts.body()
	if font != null:
		b.add_theme_font_override("font", font)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Color(0.86, 0.74, 0.46) if st == "font_color" else Color(1.0, 0.92, 0.66))
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	b.pressed.connect(on_pressed)
	var right := laurel(false)

	# The sigils keep their space when unlit, so marking an option never shifts the lettering
	# (P133). They EASE rather than snap: at 34x30 an instant appearance reads as a glitch, and
	# arrowing down a menu snapping four of them on and off reads as flicker. Each tween is stored
	# on the node so a fast keyboard scroll kills the previous one instead of racing it.
	var kill := func(n: Control, key: String) -> void:
		# `has_meta` first: `get_meta(key, default)` still logs an error for a missing key, which
		# would print four times on every focus change.
		if n.has_meta(key):
			var prev := n.get_meta(key) as Tween
			if prev != null and prev.is_valid():
				prev.kill()
	# The Collegium setting its seal on the chosen action: 175ms, inside the brief's 150-200ms, and
	# then an idle breath so the mark is never quite static. Both tweens are held on the node so a
	# fast keyboard scroll kills its predecessor instead of racing it.
	var fade := func(n: Control, to: float) -> void:
		kill.call(n, "fade")
		kill.call(n, "breathe")
		var t := n.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(n, "modulate:a", to, 0.175)
		n.set_meta("fade", t)
		if to <= 0.0:
			return
		# Extremely gentle: a 14% swing over nine seconds. If you can see it happen, it is too much.
		var br := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		br.tween_interval(0.175)
		br.tween_property(n, "modulate:a", 0.86, 4.5)
		br.tween_property(n, "modulate:a", 1.0, 4.5)
		n.set_meta("breathe", br)
	var mark := func(on: bool) -> void:
		var a := 1.0 if on else 0.0
		fade.call(left, a)
		fade.call(right, a)
		# The selected line warms, but only just: +12% luminance, inside the brief's 10-15%. It was
		# +23%, which read as a highlight rather than as emphasis.
		b.add_theme_color_override("font_color",
			Color(0.96, 0.83, 0.52) if on else Color(0.86, 0.74, 0.46))
	b.focus_entered.connect(func(): mark.call(true))
	b.focus_exited.connect(func(): mark.call(false))
	b.mouse_entered.connect(func(): b.grab_focus())

	row.add_child(left)
	row.add_child(b)
	row.add_child(right)
	host.add_child(row)
	return b


## A quill-line scrollbar: a thin brass rule with a gilt grabber, so a scrolling region
## on parchment does not show the stock grey engine bar. Applied to ONE node, never
## through a Theme — the popup Theme is shared with the Contract Board (TD-089).
static func ink_scrollbar(bar: ScrollBar) -> void:
	if bar == null:
		return
	bar.custom_minimum_size = Vector2(7, 0)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.34, 0.26, 0.15, 0.30)
	track.content_margin_left = 3.0
	track.content_margin_right = 3.0
	bar.add_theme_stylebox_override("scroll", track)
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.52, 0.40, 0.19)
	grab.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("grabber", grab)
	var lit := StyleBoxFlat.new()
	lit.bg_color = Color(0.80, 0.64, 0.32)
	lit.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("grabber_highlight", lit)
	bar.add_theme_stylebox_override("grabber_pressed", lit)
