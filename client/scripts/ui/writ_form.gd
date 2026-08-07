extends RefCounted
## A Collegium document you fill in (TD-080). Preloaded as `WritForm`, never a global class_name so
## a headless parse/import resolves it (TD-029/30).
##
## The join screen and the first-run name rite are the same object: aged parchment laid over the
## Great Hall, ruled lines instead of input boxes, Cinzel throughout, and the laurel marking whichever
## action has focus. It replaces a purple-navy panel with a yellow studded frame and filled buttons —
## chrome that turned the screen back into a dialog, which is exactly what R232 exists to stop.
##
## Ink on paper, not gilt on stone: the writ is the one lit thing in the frame, and it is the hall's
## own light falling on a document rather than a window opened over it.
##
## Builds onto a passed-in host, the `add_torches` / `RiteBanner` idiom. Render + input only: it
## emits what the player typed through callbacks and never touches the socket (I1, S3.5).

const Fonts := preload("res://scripts/ui/fonts.gd")
const Widgets := preload("res://scripts/ui/widgets.gd")

# The Contract Board's own live parchment. Reused as an ASSET, not as a code dependency on `board/` —
# a writ and a notice are the same material, and authoring a second parchment would be two things to
# keep in sync (and one of them would drift).
const PARCH := "res://assets/ui/board/parch_v1_0.png"

const INK := Color(0.16, 0.12, 0.07)          # iron-gall on paper
const INK_DIM := Color(0.30, 0.24, 0.15)
const RULE := Color(0.34, 0.26, 0.15, 0.55)

## A blank vertical spacer. A Label with empty text would also occupy space, but it carries a font,
## a colour and a minimum height it does not need — this is the thing it actually is.
static func _gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## One field: a small caption over a ruled line the text sits on. No box — a box is the thing that
## reads as a form control, and this is meant to read as a document.
static func _field(host: Node, caption: String, placeholder: String, value: String) -> LineEdit:
	var cap := Label.new()
	cap.text = caption
	cap.add_theme_font_size_override("font_size", 7)
	cap.add_theme_color_override("font_color", INK_DIM)
	var f := Fonts.cinzel(600)
	if f != null:
		cap.add_theme_font_override("font", f)
	host.add_child(cap)

	var e := LineEdit.new()
	e.text = value
	e.placeholder_text = placeholder
	e.alignment = HORIZONTAL_ALIGNMENT_LEFT
	e.add_theme_font_size_override("font_size", 12)
	var ef := Fonts.cinzel(500)
	if ef != null:
		e.add_theme_font_override("font", ef)
	e.add_theme_color_override("font_color", INK)
	e.add_theme_color_override("font_placeholder_color", Color(0.42, 0.35, 0.24, 0.75))
	e.add_theme_color_override("caret_color", INK)
	# Every stylebox emptied: the ruled line below IS the field, so any panel, border or focus box
	# Godot would otherwise draw is chrome we are here to remove.
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "focus", "read_only"]:
		e.add_theme_stylebox_override(st, empty)
	host.add_child(e)

	var rule := ColorRect.new()
	rule.color = RULE
	rule.custom_minimum_size = Vector2(0, 1)
	host.add_child(rule)
	return e


## An action on the writ: Cinzel, unfilled, with the laurel marking focus — the title screen's own
## language, so a choice reads the same way wherever it is made.
static func action(host: Node, text: String, on_pressed: Callable) -> Button:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 5)

	var left := Widgets.laurel(true)
	var b := Button.new()
	b.text = text
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.add_theme_font_size_override("font_size", 12)
	var f := Fonts.cinzel(600)
	if f != null:
		b.add_theme_font_override("font", f)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled", "focus"]:
		b.add_theme_stylebox_override(st, empty)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, INK)
	b.pressed.connect(on_pressed)
	var right := Widgets.laurel(false)

	var mark := func(on: bool) -> void:
		var a := 1.0 if on else 0.0
		for n: Control in [left, right]:
			if n.has_meta("fade"):
				var prev := n.get_meta("fade") as Tween
				if prev != null and prev.is_valid():
					prev.kill()
			var t := n.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			t.tween_property(n, "modulate:a", a, 0.175)
			n.set_meta("fade", t)
	b.focus_entered.connect(func(): mark.call(true))
	b.focus_exited.connect(func(): mark.call(false))
	b.mouse_entered.connect(func(): b.grab_focus())

	row.add_child(left)
	row.add_child(b)
	row.add_child(right)
	host.add_child(row)
	return b


## The writ itself. `fields` is [[caption, placeholder, value], …]; returns the parchment node and
## the LineEdits, so the caller owns what to do with what was typed (it never leaves this module).
##
## The parchment is a **NinePatchRect behind a MarginContainer**, not a sized TextureRect. The host
## here is `_root`, a VBoxContainer — it reassigns its children's size every layout pass, so an
## absolutely-positioned sheet is stretched full-width and its content shoved to one side (which is
## exactly what the first attempt did). Letting the CONTENT drive the height and nine-slicing the
## paper behind it means the writ is always exactly as tall as what is written on it, and the
## deckled edge survives because only the middle stretches.
static func build(host: Control, vp: Vector2, title: String, fields: Array) -> Dictionary:
	var wrap := MarginContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wrap.custom_minimum_size = Vector2(roundf(minf(vp.x * 0.46, 296.0)), 0)
	host.add_child(wrap)

	var sheet := NinePatchRect.new()
	sheet.texture = load(PARCH) as Texture2D
	sheet.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Small patch margins: the deckled tear is the character of this paper, so it must not stretch.
	for side in ["left", "top", "right", "bottom"]:
		sheet.set("patch_margin_" + side, 14)
	sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(sheet)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 26)
	pad.add_theme_constant_override("margin_right", 26)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_bottom", 18)
	wrap.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	pad.add_child(col)

	var head := Label.new()
	head.text = title
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 13)
	head.add_theme_color_override("font_color", INK)
	var hf := Fonts.cinzel(700)
	if hf != null:
		head.add_theme_font_override("font", hf)
	col.add_child(head)
	var hr := ColorRect.new()
	hr.color = RULE
	hr.custom_minimum_size = Vector2(0, 1)
	col.add_child(hr)
	col.add_child(_gap(7))

	var edits: Array[LineEdit] = []
	for spec in fields:
		edits.append(_field(col, spec[0], spec[1], spec[2]))
		col.add_child(_gap(7))

	return {"sheet": wrap, "column": col, "edits": edits}


## The way in: the writ settles onto the hall over ~250ms. Simple, per the author — a fade and a
## small settle, nothing theatrical. Reduced motion gets the end state directly.
static func arrive(sheet: Control, reduced: bool) -> void:
	if reduced:
		return
	var to := sheet.position
	sheet.modulate.a = 0.0
	sheet.position = to + Vector2(0, 6)
	var t := sheet.create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(sheet, "modulate:a", 1.0, 0.25)
	t.tween_property(sheet, "position", to, 0.25)
