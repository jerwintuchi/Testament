extends RefCounted
## The Quartermaster's requisition writ (TD-090 Phase A, R318–R321).
##
## The Quartermaster is a LENDING COUNTER, not a shop or a storage room: there is no
## currency in Testament (TD-091), and instruments are not owned — the Collegium's
## reliquary issues four of them against a writ. So the screen is a form you sign,
## and the four slots are the mechanic, not a footnote.
##
## Interaction is CLICK-TO-ASSIGN, never drag-and-drop: mobile is a target platform
## (TD-042), and a drag needs a touch state machine, is fiddly at this scale, and
## breaks the keyboard/gamepad focus the board already uses. Click an instrument to
## sign for it; click a filled slot to give it back.
##
## Render-only, per S3.5: it takes intents out through callables and never touches
## `_net`. Styling is applied by these builders, NEVER through the popup `Theme` —
## that Theme is shared with the Contract Board, whose writs are measured against the
## font they are drawn in (TD-089).

const Fonts       := preload("res://scripts/ui/fonts.gd")
const Widgets     := preload("res://scripts/ui/widgets.gd")
const PopupTheme  := preload("res://scripts/ui/popup_theme.gd")
const Catalog     := preload("res://scripts/core/catalog.gd")

const ICONS := "res://assets/ui/stations/gear_icons.png"
const ICON_PX := 24

# Sheet order matches the authored columns in art/src/gen_gear_icons.lua.
const ICON_INDEX := {
	"ashen-lens": 0, "chirurgeons-glass": 1, "witness-prism": 2, "trackers-fetish": 3,
	"cantors-ear": 4, "augurs-bead": 5,
	"censer-of-embers": 6, "phial-of-hoarfrost": 7, "consecrated-salt": 8,
	"lantern-of-the-creed": 9,
}

# What each instrument ANSWERS, in a hunter's words. The player never reads the wire
# enum (R320) and never a rating (R320/P149) — a channel name is an engineering term
# leaking into the fiction, so the row states the QUESTION the instrument settles.
const ANSWERS := {
	"RESIDUE":     "what did it leave behind?",
	"STRESS_MARK": "what hurts it?",
	"REACTION":    "what does it shrug off?",
	"SPOOR":       "how does it hunt?",
	"LITURGY":     "how can it be ended without killing?",
	"OMEN":        "what does it do before it strikes?",
}
const PRESENTS := {
	"FLAME": "offer it flame, and watch",
	"COLD":  "offer it cold, and watch",
	"SALT":  "offer it salt, and watch",
	"LIGHT": "offer it light, and watch",
}

# ── public API ───────────────────────────────────────────────────────────────

## Builds the writ into `body` and returns a view handle for `refresh`.
## `on_toggle(item_id)` and `on_requisition()` carry intents out.
static func build(body: Node, selected: Array, on_toggle: Callable, on_requisition: Callable) -> Dictionary:
	var view := {"slots": [], "rows": {}, "count": null, "action": null}

	# The slots first: bounded capacity is the mechanic (R319), so it is the first
	# thing the eye lands on. Four marks that fill — never "2 of 4" in a sentence,
	# which makes the player parse a number to learn what a row of marks says at once.
	var slots := HBoxContainer.new()
	slots.add_theme_constant_override("separation", 6)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(slots)
	for i in range(Catalog.BAG_SLOTS):
		var slot := _slot()
		slots.add_child(slot)
		view["slots"].append(slot)

	var count := Widgets.card_label("", 10, PopupTheme.INK_DIM, false, true)
	count.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(count)
	view["count"] = count
	body.add_child(Widgets.hrule(PopupTheme.RULE))

	# Two groups, named for the spine verbs they serve. This is the whole tradeoff
	# made visible: how many slots for looking, how many for trying.
	_group(body, "Instruments of Sight", "PERCEPTION", selected, on_toggle, view)
	_group(body, "Instruments of Trial", "PROBE", selected, on_toggle, view)

	body.add_child(Widgets.hrule(PopupTheme.RULE))
	var act := Button.new()
	act.text = "Sign for these instruments"
	_ink(act)
	act.pressed.connect(on_requisition)
	body.add_child(act)
	view["action"] = act

	refresh(view, selected)
	return view


## Repaints selection state in place. Called on every toggle, so it must not rebuild:
## a rebuild would lose scroll and re-instantiate every row (S6 — update the smallest
## subtree that reflects the change).
static func refresh(view: Dictionary, selected: Array) -> void:
	var slots: Array = view["slots"]
	for i in range(slots.size()):
		var tex: TextureRect = (slots[i] as Control).get_node("Held")
		if i < selected.size():
			tex.texture = _icon(String(selected[i]))
			tex.modulate = Color(1, 1, 1, 1)
		else:
			tex.texture = null
	var full := selected.size() >= Catalog.BAG_SLOTS
	for id in view["rows"].keys():
		var entry: Dictionary = view["rows"][id]
		var row: Button = entry["row"]
		var on: bool = String(id) in selected
		(entry["mark"] as Label).text = "×" if on else ""
		# A full bag dims what you cannot add, but never hides it — the wall of
		# instruments is information even when you cannot carry it.
		row.modulate = Color(1, 1, 1, 0.45) if (full and not on) else Color(1, 1, 1, 1)
	var left := Catalog.BAG_SLOTS - selected.size()
	view["count"].text = ("the bag is full" if left <= 0
		else "%d of %d slots still open" % [left, Catalog.BAG_SLOTS])
	(view["action"] as Button).disabled = selected.is_empty()

# ── builders ─────────────────────────────────────────────────────────────────

static func _icon(item_id: String) -> AtlasTexture:
	var sheet := load(ICONS) as Texture2D
	if sheet == null or not ICON_INDEX.has(item_id):
		return null
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(int(ICON_INDEX[item_id]) * ICON_PX, 0, ICON_PX, ICON_PX)
	return at

static func _slot() -> Control:
	var p := Panel.new()
	p.custom_minimum_size = Vector2(ICON_PX + 6, ICON_PX + 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.30, 0.24, 0.15, 0.10)   # a shallow recess in the paper
	sb.set_border_width_all(1)
	sb.border_color = PopupTheme.RULE
	p.add_theme_stylebox_override("panel", sb)
	var t := TextureRect.new()
	t.name = "Held"
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # 1:1, never resampled
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(t)
	return p

static func _group(body: Node, title: String, kind: String,
		selected: Array, on_toggle: Callable, view: Dictionary) -> void:
	var h := Widgets.card_label(title.to_upper(), 9, PopupTheme.INK_DIM, false, false)
	h.add_theme_constant_override("line_spacing", 2)
	body.add_child(h)
	for item in Catalog.GEAR:
		if String(item["kind"]) != kind:
			continue
		var built := _row(item, on_toggle)
		body.add_child(built["row"])
		view["rows"][String(item["id"])] = built

static func _row(item: Dictionary, on_toggle: Callable) -> Dictionary:
	var id := String(item["id"])
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, ICON_PX + 8)
	b.add_theme_stylebox_override("normal", PopupTheme.ruled(Color(0, 0, 0, 0)))
	for st in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, PopupTheme.ruled(PopupTheme.RULE_LIT))
	b.pressed.connect(func(): on_toggle.call(id))
	b.tooltip_text = "Click to sign for it; click its slot to give it back."

	# The contents ignore the mouse so the whole row stays one click target — the
	# alternative is manual hit-testing, which breaks keyboard focus.
	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	b.add_child(box)

	var ic := TextureRect.new()
	ic.texture = _icon(id)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(ic)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(col)
	col.add_child(Widgets.card_label(String(item["name"]), 12, PopupTheme.INK, false, false))
	col.add_child(Widgets.card_label(_says(item), 9, PopupTheme.INK_DIM, false, false))

	# The mark, in the writ's own language: an X struck in the margin, as on the
	# options writ. Same idiom the player already knows from two other screens.
	var mark := Widgets.card_label("", 15, PopupTheme.INK, false, true)
	mark.custom_minimum_size = Vector2(14, 0)
	box.add_child(mark)
	return {"row": b, "mark": mark}

static func _says(item: Dictionary) -> String:
	if String(item["kind"]) == "PERCEPTION":
		return "Answers: %s" % ANSWERS.get(String(item["channel"]), "?")
	return String(PRESENTS.get(String(item["stimulus"]), "?"))

static func _ink(b: Button) -> void:
	b.add_theme_stylebox_override("normal", PopupTheme.ruled(PopupTheme.RULE))
	for st in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, PopupTheme.ruled(PopupTheme.RULE_LIT))
	b.add_theme_stylebox_override("disabled",
		PopupTheme.ruled(Color(PopupTheme.RULE.r, PopupTheme.RULE.g, PopupTheme.RULE.b, 0.25)))
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, PopupTheme.INK)
	b.add_theme_color_override("font_disabled_color", Color(PopupTheme.INK.r, PopupTheme.INK.g, PopupTheme.INK.b, 0.35))
	b.add_theme_font_size_override("font_size", 12)
	var f := Fonts.cinzel(600)
	if f != null:
		b.add_theme_font_override("font", f)
