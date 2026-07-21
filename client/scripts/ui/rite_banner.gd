extends RefCounted
## The souls-like CONTRACT SEALED ceremony banner (TD-063/R205; extracted TD-067). Preloaded
## as `RiteBanner`, never a global class_name (TD-029/30).
##
## Owns a TRANSIENT CanvasLayer overlay, so it follows the `BoardDecor.add_torches(host, …)`
## idiom — a static builder that creates nodes on a passed-in host and self-frees — rather
## than a persistent scene (it is fire-and-forget, code-built, no editor layout).
##
## A wide dark band with big gilt letter-spaced CONTRACT SEALED over the target's name. Fired
## for EVERY room member from the one CONTRACT_SELECTION broadcast (the ceremony is shared —
## cooperation is the pillar); replaces the stamp toast. Pure display: ignores the mouse,
## renders only broadcast payload fields, frees itself, emits nothing (P117). Reduced motion
## shows it statically — the information is load-bearing, the motion is not.

const Fonts = preload("res://scripts/ui/fonts.gd")

static func show(host: Node, title: String, sub: String, reduced_motion: bool) -> void:
	var lay := CanvasLayer.new()
	lay.layer = 90
	host.add_child(lay)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(root)
	var band := TextureRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.texture = _band_gradient()
	band.anchor_left = 0.0; band.anchor_right = 1.0
	band.anchor_top = 0.38; band.anchor_bottom = 0.38
	band.offset_top = -36.0; band.offset_bottom = 36.0
	root.add_child(band)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	band.add_child(v)
	var tf := Fonts.cinzel(700)
	if tf != null:
		tf.set("spacing_glyph", 5)     # the souls-register letterspacing
	var tl := Label.new()
	tl.text = title
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if tf != null:
		tl.add_theme_font_override("font", tf)
	tl.add_theme_font_size_override("font_size", 26)
	tl.add_theme_color_override("font_color", Color(0.90, 0.76, 0.42))
	tl.add_theme_color_override("font_outline_color", Color(0.05, 0.035, 0.02, 0.9))
	tl.add_theme_constant_override("outline_size", 5)
	v.add_child(tl)
	var sl := Label.new()
	sl.text = sub
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.add_theme_font_size_override("font_size", 13)
	sl.add_theme_color_override("font_color", Color(0.85, 0.79, 0.65))
	sl.add_theme_color_override("font_outline_color", Color(0.05, 0.035, 0.02, 0.85))
	sl.add_theme_constant_override("outline_size", 4)
	v.add_child(sl)
	if reduced_motion:
		host.get_tree().create_timer(1.8).timeout.connect(lay.queue_free)
		return
	root.modulate.a = 0.0
	await host.get_tree().process_frame          # band sized → pivot for the settle drift
	if not is_instance_valid(band):
		return
	band.pivot_offset = band.size * 0.5
	band.scale = Vector2(1.05, 1.05)
	var tw := root.create_tween()
	tw.tween_property(root, "modulate:a", 1.0, 0.30)
	tw.parallel().tween_property(band, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.30)
	tw.tween_property(root, "modulate:a", 0.0, 0.60)
	tw.tween_callback(lay.queue_free)

# The banner's dark band: transparent → near-black → transparent, horizontally.
static func _band_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.5, 0.82, 1.0])
	g.colors = PackedColorArray([
		Color(0, 0, 0, 0), Color(0.02, 0.015, 0.01, 0.80), Color(0.02, 0.015, 0.01, 0.88),
		Color(0.02, 0.015, 0.01, 0.80), Color(0, 0, 0, 0)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 256
	t.height = 8
	t.fill_from = Vector2(0.0, 0.0)
	t.fill_to = Vector2(1.0, 0.0)
	return t
