extends RefCounted
## The field record for the selected instrument — a Collegium document, not a tooltip.
##
## Reads as something filed: a ruled head, the classification, the question the
## instrument settles, a short hand, a handling note, and the property footer. No
## statistics: an instrument is described by what it DOES (R320/P149), and the only
## number anywhere near this screen is how many slots are left.

const Widgets    := preload("res://scripts/ui/widgets.gd")
const PopupTheme := preload("res://scripts/ui/popup_theme.gd")
const Fonts      := preload("res://scripts/ui/fonts.gd")
const Lore       := preload("res://scripts/stations/quartermaster/lore.gd")

const ICON_PX := 24


## A divider with a cross at its heart: a rule that STRETCHES with a glyph laid over
## its centre, which does not.
##
## NOT a 9-slice. A 9-slice stretches its CENTRE, and the centre is precisely where the
## ornament has to sit — the first attempt smeared the cross across the whole width as
## a heavy bar. `qm_rule.png` is retired; two nodes cost less than a texture that
## cannot be drawn correctly.
static func _ornament_rule() -> Control:
	var wrap := Control.new()
	wrap.custom_minimum_size = Vector2(0, 11)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var line := ColorRect.new()
	line.color = Color(PopupTheme.RULE.r, PopupTheme.RULE.g, PopupTheme.RULE.b, 0.55)
	line.set_anchors_preset(Control.PRESET_TOP_WIDE)
	line.offset_top = 4.0
	line.offset_bottom = 5.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(line)

	var cross := Widgets.card_label("\u2720", 10, Color(0.34, 0.26, 0.14), false, true)
	cross.set_anchors_preset(Control.PRESET_FULL_RECT)
	cross.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cross.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(cross)
	return wrap



## `host` takes the scrolling body; `action_host` takes the commit button, which is
## pinned OUTSIDE the scroll — a long record must never carry the decision off-screen.
## `plate` is the record board's own engraved title plate (TD-113). The instrument's
## NAME is written there rather than in this column: the frame already has a place for a
## title, and moving it out gives the short right-hand column a whole heading back.
static func build(host: Node, action_host: Node = null, plate: Label = null) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.custom_minimum_size = Vector2(150, 0)   # so the wrap has a width to work against
	host.add_child(root)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	root.add_child(head)
	var icon := TextureRect.new()
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	head.add_child(icon)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", 0)
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(titles)
	# Name large and prominent; classification smaller and GOLD, because a Collegium
	# classification is an assertion by the order (R374/R376).
	# `clip_text` on every NON-WRAPPING label in this column, and it is load-bearing.
	# A Label that does not wrap reports its full text width as its MINIMUM width, and
	# a VBoxContainer is at least as wide as its widest child — so a long instrument
	# name silently widened the whole record past the sheet, and the wrapping prose
	# below then wrapped to that wider column and ran off the paper. The visible defect
	# was a clipped sentence; the cause was a heading three rows above it.
	# Clipping a name that overruns is the right trade: a name is recognisable from its
	# first word, a field note is not.
	# The name is engraved on the frame's plate; this column carries the classification,
	# which is the assertion the Collegium makes ABOUT the named thing (R374/R376).
	var name_l: Label = plate if plate != null else \
		Widgets.card_label("", 15, PopupTheme.INK, false, false)
	if plate == null:
		name_l.add_theme_font_override("font", Fonts.heading())
		name_l.clip_text = true
		titles.add_child(name_l)
	var class_l := Widgets.card_label("", 11, Color(0.44, 0.34, 0.14), false, false)
	class_l.clip_text = true
	class_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	class_l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	titles.add_child(class_l)

	var rule_a := _ornament_rule()
	root.add_child(rule_a)
	var asks := Widgets.card_label("", 12, PopupTheme.INK, true, false)
	asks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(asks)
	var rule_b := _ornament_rule()
	root.add_child(rule_b)
	# The body is filed under a heading, the way a record actually is.
	var rec_head := Widgets.card_label("QUARTERMASTER RECORD", 10, Color(0.34, 0.26, 0.14), false, false)
	rec_head.add_theme_font_override("font", Fonts.heading())
	rec_head.clip_text = true
	root.add_child(rec_head)
	var note := Widgets.card_label("", 11, PopupTheme.INK_DIM, true, false)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(note)
	# The handling note is a WARNING and is labelled as one: a heading, then the text,
	# in muted burgundy. Unheaded, it read as one more line of description.
	root.add_child(_ornament_rule())
	var warn_head := Widgets.card_label("WARNING", 10, Color(0.46, 0.19, 0.15), false, false)
	warn_head.add_theme_font_override("font", Fonts.heading())
	warn_head.clip_text = true
	root.add_child(warn_head)
	var care := Widgets.card_label("", 10, Color(0.44, 0.20, 0.16, 0.90), true, false)
	care.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(care)
	var party := Widgets.card_label("", 11, Color(0.24, 0.40, 0.32, 0.95), true, false)
	party.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(party)

	var foot_rule := Widgets.hrule(Color(PopupTheme.RULE.r, PopupTheme.RULE.g, PopupTheme.RULE.b, 0.30))
	root.add_child(foot_rule)
	var foot := Widgets.card_label("", 10, Color(PopupTheme.INK_DIM.r, PopupTheme.INK_DIM.g, PopupTheme.INK_DIM.b, 0.45), true, false)
	foot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(foot)

	# The one action in the record: it is where a decision is made, so the verb lives
	# beside the thing being decided rather than in a toolbar — but pinned, not scrolled.
	var act := Button.new()
	act.visible = false
	_ink(act)
	(action_host if action_host != null else root).add_child(act)

	return {"root": root, "icon": icon, "name": name_l, "class": class_l,
		"asks": asks, "note": note, "care": care, "warn_head": warn_head,
		"party": party, "foot": foot, "foot_rule": foot_rule, "action": act,
		# The head and the two rules that bracket the question. Hidden when nothing is
		# selected: with the name moved to the frame's plate the head row holds only a
		# blank icon, and an empty row between two rules reads as a document with a
		# section torn out of it rather than as one waiting to be filled in.
		"head": head, "rule_a": rule_a, "rule_b": rule_b}


## `state` is "shelf" (can be packed), "packed" (can be removed) or "full".
static func show_item(view: Dictionary, item: Dictionary, tex: Texture2D,
		state: String, act: Callable, carried_by: Array = []) -> void:
	if item.is_empty():
		clear(view)
		return
	var rec := Lore.of(String(item["id"]))
	for k in ["head", "rule_a", "rule_b"]:
		(view[k] as Control).visible = true
	(view["icon"] as TextureRect).texture = tex
	(view["name"] as Label).text = String(item["name"]).to_upper()
	(view["class"] as Label).text = String(rec["class"])
	(view["asks"] as Label).text = "\"%s\"" % rec["asks"]
	(view["note"] as Label).text = String(rec["note"])
	(view["care"] as Label).text = String(rec["care"])
	(view["warn_head"] as Control).visible = not String(rec["care"]).is_empty()
	(view["foot"] as Label).text = Lore.FOOTER
	(view["foot_rule"] as Control).visible = true

	# The party half of the decision. Perception is distributed (TD-007), so a second
	# copy of an instrument the party already holds buys nothing — this is the one
	# thing the old screen could not tell you, and the bag ships party-visible for it.
	var party: Label = view["party"]
	if carried_by.is_empty():
		party.text = ""
	elif carried_by.size() == 1:
		party.text = "%s already carries this." % carried_by[0]
	else:
		party.text = "%s already carry this." % ", ".join(carried_by)

	var b: Button = view["action"]
	for c in b.pressed.get_connections():
		b.pressed.disconnect(c["callable"])
	b.visible = true
	match state:
		"packed":
			b.text = "Take it back out"
			b.disabled = false
		"full":
			b.text = "The pack is full"
			b.disabled = true
		_:
			b.text = "Pack it"
			b.disabled = false
	if not b.disabled:
		b.pressed.connect(act)


static func clear(view: Dictionary) -> void:
	for k in ["head", "rule_a", "rule_b"]:
		(view[k] as Control).visible = false
	(view["icon"] as TextureRect).texture = null
	(view["name"] as Label).text = ""
	(view["class"] as Label).text = ""
	(view["asks"] as Label).text = ""
	(view["note"] as Label).text = "Choose an instrument from the register to read its record."
	(view["care"] as Label).text = ""
	(view["warn_head"] as Control).visible = false
	(view["party"] as Label).text = ""
	(view["foot"] as Label).text = ""
	(view["foot_rule"] as Control).visible = false
	(view["action"] as Button).visible = false


static func _ink(b: Button) -> void:
	b.add_theme_stylebox_override("normal", PopupTheme.ruled(PopupTheme.RULE))
	for st in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, PopupTheme.ruled(PopupTheme.RULE_LIT))
	b.add_theme_stylebox_override("disabled",
		PopupTheme.ruled(Color(PopupTheme.RULE.r, PopupTheme.RULE.g, PopupTheme.RULE.b, 0.25)))
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, PopupTheme.INK)
	b.add_theme_color_override("font_disabled_color",
		Color(PopupTheme.INK.r, PopupTheme.INK.g, PopupTheme.INK.b, 0.35))
	b.add_theme_font_size_override("font_size", 13)
	var f := Fonts.heading()
	if f != null:
		b.add_theme_font_override("font", f)
