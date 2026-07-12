extends RefCounted
## Contract Board — the bottom bar (extracted from main.gd for organization, TD-046 pass).
##
## Three gilt-edged zones along the board's foot (Prototype v1): the petition-type LEGEND
## (verb badge → sacred name), the ACTIVE ASSIGNMENT (the sealed charge, trait-free), and
## the STATUS column. All render-only static factories — `build()` takes the resolved inner
## size, the authoritative `contract` (or null), and the pre-formatted requester signature;
## no scene/socket state is touched. Consumed via preload as `BoardBar` (TD-029/30).

const BoardGeo = preload("res://scripts/ui/board_geometry.gd")
const VerbBadge = preload("res://scripts/ui/verb_badge.gd")
const Notice = preload("res://scripts/ui/notice.gd")

# The three-zone row. Caller positions it (it knows inner/z); this only builds the content.
static func build(inner: Vector2, contract: Variant, sig: String) -> HBoxContainer:
	var barh := BoardGeo.bar_height(inner)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(inner.x * 0.96, barh)
	row.size = row.custom_minimum_size
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Left — the petition-type legend keyed to each card's upper-left glyph (reference icon key).
	row.add_child(_legend(Vector2(inner.x * 0.24, barh)))
	# Centre — the ACTIVE ASSIGNMENT: the sealed charge shown as a small writ, or empty state.
	row.add_child(_assignment(contract, sig))
	# Right — the charge's standing (New / Sealed / Deployed).
	row.add_child(_status(Vector2(inner.x * 0.22, barh), contract != null))
	return row

# The bottom-left legend: four rows of [verb badge] + sacred name.
static func _legend(size: Vector2) -> Control:
	var p := _bar_frame(size)
	var v := _bar_body(p, "PETITION TYPES")
	for verb in ["INVESTIGATE", "ELIMINATE", "CAPTURE", "BANISH"]:
		var rowc := HBoxContainer.new()
		rowc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rowc.add_theme_constant_override("separation", 7)
		var badge := VerbBadge.new()
		badge.set_verb(verb)
		badge.set_tint(Color(0.86, 0.72, 0.40))   # gilt, so the sigil doesn't vanish on the dark bar
		badge.custom_minimum_size = Vector2(12, 12)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bwrap := Control.new()                 # a fixed slot so the row metrics stay steady
		bwrap.custom_minimum_size = Vector2(12, 12)
		bwrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bwrap.add_child(badge)
		rowc.add_child(bwrap)
		rowc.add_child(_label(VerbBadge.LABEL[verb], 8, Color(0.92, 0.85, 0.70)))
		v.add_child(rowc)
	return p

# The bottom-centre ACTIVE ASSIGNMENT: a small sealed-writ readout, trait-free.
static func _assignment(contract: Variant, sig: String) -> Control:
	var p := _bar_frame(Vector2(0, 0))
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := _bar_body(p, "ACTIVE ASSIGNMENT")
	if contract == null:
		v.add_child(_label("— no charge sealed —", 9, Color(0.80, 0.72, 0.55)))
		v.add_child(_label("Awaiting the leader's seal.", 8, Color(0.66, 0.58, 0.44)))
		return p
	var cd := contract as Dictionary
	v.add_child(_label(str(cd.get("targetName", "?")), 10, Color(0.90, 0.82, 0.62)))
	v.add_child(_label("%s   ·   at %s" % [Notice.headline(str(cd.get("primaryVerb", ""))),
		cd.get("siteName", "?")], 8, Color(0.80, 0.72, 0.55)))
	v.add_child(_label(sig, 7, Color(0.62, 0.54, 0.40)))
	return p

# The bottom-right status legend (New / Sealed / Deployed).
static func _status(size: Vector2, sealed: bool) -> Control:
	var p := _bar_frame(size)
	var v := _bar_body(p, "STATUS")
	v.add_child(_status_row("New", not sealed, Color(0.80, 0.72, 0.55)))
	v.add_child(_status_row("Sealed", sealed, Color(0.86, 0.66, 0.30)))
	v.add_child(_status_row("Deployed", false, Color(0.55, 0.48, 0.36)))
	return p

static func _status_row(text: String, on: bool, col: Color) -> Control:
	var rowc := HBoxContainer.new()
	rowc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rowc.add_theme_constant_override("separation", 7)
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(9, 9)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var db := StyleBoxFlat.new()
	db.bg_color = col if on else Color(0.20, 0.16, 0.11)
	db.set_corner_radius_all(5)
	db.set_border_width_all(1)
	db.border_color = Color(0.42, 0.30, 0.14)
	dot.add_theme_stylebox_override("panel", db)
	var wrap := CenterContainer.new()
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.custom_minimum_size = Vector2(11, 15)
	wrap.add_child(dot)
	rowc.add_child(wrap)
	rowc.add_child(_label(text, 8, col if on else Color(0.55, 0.48, 0.36)))
	return rowc

# A dark gilt-edged bar-panel frame (shared shell for the three bottom zones).
static func _bar_frame(size: Vector2) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.08, 0.05, 0.94)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.42, 0.30, 0.14)
	sb.set_corner_radius_all(2)
	p.add_theme_stylebox_override("panel", sb)
	return p

# The padded VBox inside a bar-panel, seeded with a gilt caption + rule. Returns the VBox.
static func _bar_body(p: Panel, title: String) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for s in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		m.add_theme_constant_override(s, 5)
	p.add_child(m)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	m.add_child(v)
	v.add_child(_label(title, 7, Color(0.72, 0.56, 0.26)))
	var rule := ColorRect.new()
	rule.color = Color(0.42, 0.28, 0.16, 0.5)
	rule.custom_minimum_size = Vector2(0, 1)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(rule)
	return v

static func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
