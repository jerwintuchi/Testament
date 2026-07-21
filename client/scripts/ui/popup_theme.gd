extends RefCounted
## The station popup's gothic Theme (TD-067). Preloaded as `PopupTheme`, never a global
## class_name (TD-029/30).
##
## Applied to `_popup` so it cascades to every child (buttons, labels, checkboxes). The
## panel is a 9-slice StyleBoxTexture from assets/ui/panel.png (dark stone + aged-gold
## frame), with a StyleBoxFlat fallback so a missing/late texture import never crashes the
## popup. Palette-locked to the game's charcoal-and-gold register (art direction).

static func build() -> Theme:
	var th := Theme.new()
	var panel_sb: StyleBox
	var tex := load("res://assets/ui/panel.png") as Texture2D
	if tex != null:
		var sbt := StyleBoxTexture.new()
		sbt.texture = tex
		sbt.set_texture_margin_all(12.0)   # 9-slice: matches gen_panel.py MARGIN
		sbt.set_content_margin_all(12.0)   # inset children off the frame
		panel_sb = sbt
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.10, 0.086, 0.15)
		flat.set_border_width_all(2)
		flat.border_color = Color(0.72, 0.57, 0.18)
		flat.set_content_margin_all(14.0)
		panel_sb = flat
	th.set_stylebox("panel", "PanelContainer", panel_sb)
	# Buttons: dark stone with a gold border, brighter on hover, sunk when pressed.
	th.set_stylebox("normal", "Button", _btn_box(Color(0.145, 0.10, 0.055), Color(0.46, 0.34, 0.15)))
	th.set_stylebox("hover", "Button", _btn_box(Color(0.20, 0.14, 0.08), Color(0.79, 0.64, 0.29)))
	th.set_stylebox("pressed", "Button", _btn_box(Color(0.10, 0.07, 0.04), Color(0.54, 0.42, 0.17)))
	th.set_color("font_color", "Button", Color(0.86, 0.78, 0.56))
	th.set_color("font_hover_color", "Button", Color(0.97, 0.88, 0.64))
	th.set_color("font_color", "Label", Color(0.87, 0.83, 0.73))
	th.set_color("font_color", "CheckBox", Color(0.86, 0.81, 0.69))
	# Tooltips in the scene's register (TD-062/R198): a near-black warm panel with a brass
	# hairline + parchment-tone text — never Godot's default grey bubble.
	var tip := StyleBoxFlat.new()
	tip.bg_color = Color(0.085, 0.065, 0.045, 0.96)
	tip.set_border_width_all(1)
	tip.border_color = Color(0.52, 0.40, 0.19)
	tip.content_margin_left = 8.0; tip.content_margin_right = 8.0
	tip.content_margin_top = 4.0; tip.content_margin_bottom = 4.0
	th.set_stylebox("panel", "TooltipPanel", tip)
	th.set_color("font_color", "TooltipLabel", Color(0.87, 0.80, 0.62))
	th.set_font_size("font_size", "TooltipLabel", 12)
	return th

static func _btn_box(bg: Color, border: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.set_border_width_all(1)
	b.border_color = border
	b.content_margin_left = 10.0
	b.content_margin_right = 10.0
	b.content_margin_top = 5.0
	b.content_margin_bottom = 5.0
	return b
