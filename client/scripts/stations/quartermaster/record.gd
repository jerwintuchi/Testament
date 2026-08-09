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


## `host` takes the scrolling body; `action_host` takes the commit button, which is
## pinned OUTSIDE the scroll — a long record must never carry the decision off-screen.
static func build(host: Node, action_host: Node = null) -> Dictionary:
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
	var name_l := Widgets.card_label("", 15, PopupTheme.INK, false, false)
	name_l.add_theme_font_override("font", Fonts.heading())
	var class_l := Widgets.card_label("", 9, Color(0.44, 0.34, 0.14), false, false)
	titles.add_child(name_l)
	titles.add_child(class_l)

	root.add_child(Widgets.hrule(PopupTheme.RULE))
	var asks := Widgets.card_label("", 11, PopupTheme.INK, true, false)
	asks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(asks)
	var note := Widgets.card_label("", 9, PopupTheme.INK_DIM, true, false)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(note)
	# The handling note is a WARNING and is labelled as one: a heading, then the text,
	# in muted burgundy. Unheaded, it read as one more line of description.
	var warn_head := Widgets.card_label("WARNING", 8, Color(0.46, 0.19, 0.15), false, false)
	warn_head.add_theme_font_override("font", Fonts.heading())
	root.add_child(warn_head)
	var care := Widgets.card_label("", 8, Color(0.44, 0.20, 0.16, 0.90), true, false)
	care.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(care)
	var party := Widgets.card_label("", 9, Color(0.24, 0.40, 0.32, 0.95), true, false)
	party.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(party)

	var foot_rule := Widgets.hrule(Color(PopupTheme.RULE.r, PopupTheme.RULE.g, PopupTheme.RULE.b, 0.30))
	root.add_child(foot_rule)
	var foot := Widgets.card_label("", 6, Color(PopupTheme.INK_DIM.r, PopupTheme.INK_DIM.g, PopupTheme.INK_DIM.b, 0.45), true, false)
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
		"party": party, "foot": foot, "foot_rule": foot_rule, "action": act}


## `state` is "shelf" (can be packed), "packed" (can be removed) or "full".
static func show_item(view: Dictionary, item: Dictionary, tex: Texture2D,
		state: String, act: Callable, carried_by: Array = []) -> void:
	if item.is_empty():
		clear(view)
		return
	var rec := Lore.of(String(item["id"]))
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
	b.add_theme_font_size_override("font_size", 11)
	var f := Fonts.heading()
	if f != null:
		b.add_theme_font_override("font", f)
