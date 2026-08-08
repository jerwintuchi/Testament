extends RefCounted
## The Quartermaster's Register — the whole screen, and the coordinator for its parts.
##
## Composition: the shelf of available instruments on the left, the expedition pack on
## the right, the field record beneath, and the seal at the foot. Selection inspects;
## the record commits. Click-to-assign rather than drag-and-drop, because mobile is a
## target platform (TD-042) and a drag breaks the keyboard focus the board already uses.
##
## Render + intent only (S3.5): it never touches `_net`. `on_requisition` carries the
## sealed pack out; the shell owns the socket, and the server validates regardless —
## this screen is an affordance (P148).
##
## What sealing does NOT do: deploy. Requisition stays reversible until the leader
## deploys at the Deploy Gate, which is a server phase gate and the deliberate
## commitment boundary (you may re-pack freely, but never after seeing a sign). So the
## rite commits THE PACK and says so.

const Widgets    := preload("res://scripts/ui/widgets.gd")
const PopupTheme := preload("res://scripts/ui/popup_theme.gd")
const Fonts      := preload("res://scripts/ui/fonts.gd")
const Catalog    := preload("res://scripts/core/catalog.gd")
const Pack       := preload("res://scripts/stations/quartermaster/pack.gd")
const Record     := preload("res://scripts/stations/quartermaster/record.gd")
const Lore       := preload("res://scripts/stations/quartermaster/lore.gd")
const SealRite   := preload("res://scripts/stations/quartermaster/seal_rite.gd")

const ICONS   := "res://assets/ui/stations/gear_icons.png"
const ICON_PX := 24

const ICON_INDEX := {
	"ashen-lens": 0, "chirurgeons-glass": 1, "witness-prism": 2, "trackers-fetish": 3,
	"cantors-ear": 4, "augurs-bead": 5,
	"censer-of-embers": 6, "phial-of-hoarfrost": 7, "consecrated-salt": 8,
	"lantern-of-the-creed": 9,
}

# What an instrument settles, in a hunter's words — never the wire enum (R320).
const ANSWERS := {
	"RESIDUE": "what did it leave behind?", "STRESS_MARK": "what hurts it?",
	"REACTION": "what does it shrug off?", "SPOOR": "how does it hunt?",
	"LITURGY": "how can it be ended without killing?", "OMEN": "what does it do before it strikes?",
}


static func build(body: Node, host: Node, selected: Array,
		on_change: Callable, on_requisition: Callable, reduced: bool,
		can_issue: bool = true, party: Array = []) -> Dictionary:
	var view := {
		"host": host, "packed": selected, "sel": "", "sealed": false,
		"on_change": on_change, "on_requisition": on_requisition, "reduced": reduced,
		"can_issue": can_issue, "party": party, "rows": {},
	}

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 14)
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.custom_minimum_size = Vector2(0, 180)   # bounded: the record below must stay visible
	cols.size_flags_vertical = Control.SIZE_SHRINK_BEGIN   # a minimum, not a licence to grow
	body.add_child(cols)

	# ── left: the register of what may be drawn ──────────────────────────────
	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.30
	left_col.add_theme_constant_override("separation", 2)
	cols.add_child(left_col)
	left_col.add_child(_heading("AVAILABLE INSTRUMENTS"))
	# The register is longer than the sheet, so IT scrolls — not the whole writ. The
	# pack, the record and the rite stay put while the shelf is browsed.
	var shelf_scroll := ScrollContainer.new()
	shelf_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shelf_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(shelf_scroll)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 1)
	shelf_scroll.add_child(left)
	Widgets.ink_scrollbar(shelf_scroll.get_v_scroll_bar())
	view["shelf_scroll"] = shelf_scroll
	_shelf_group(left, "Instruments of Sight", "PERCEPTION", view)
	_shelf_group(left, "Instruments of Trial", "PROBE", view)

	# ── right: the pack itself ───────────────────────────────────────────────
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(112, 0)
	cols.add_child(right)
	view["pack"] = Pack.build(right, Catalog.BAG_SLOTS)

	# ── third column: the field record ───────────────────────────────────────
	# The brief stacks the record UNDER the columns. At this game's logical 640x360
	# that composition is ~370 units tall against a ~250-unit sheet, so it cannot fit
	# and the rite would sit permanently below the fold. Three columns is the honest
	# adaptation: the record keeps its own space, and the decision stays on screen.
	var rec_col := VBoxContainer.new()
	rec_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rec_col.size_flags_stretch_ratio = 1.25
	rec_col.add_theme_constant_override("separation", 2)
	cols.add_child(rec_col)
	rec_col.add_child(_heading("SELECTED INSTRUMENT"))
	# The record scrolls inside its column too. A long record is what pushed the rite
	# below the fold twice: whichever column is tallest sets the row height, so NONE of
	# them may grow without bound.
	var rec_scroll := ScrollContainer.new()
	rec_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rec_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rec_col.add_child(rec_scroll)
	Widgets.ink_scrollbar(rec_scroll.get_v_scroll_bar())
	view["record"] = Record.build(rec_scroll, rec_col)   # body scrolls, action stays put

	body.add_child(Widgets.hrule(PopupTheme.RULE))

	var tally := HBoxContainer.new()
	tally.alignment = BoxContainer.ALIGNMENT_CENTER
	tally.add_theme_constant_override("separation", 18)
	body.add_child(tally)
	var packed_l := Widgets.card_label("", 10, PopupTheme.INK, false, false)
	var shape_l := Widgets.card_label("", 10, PopupTheme.INK_DIM, false, false)
	tally.add_child(packed_l); tally.add_child(shape_l)
	view["packed_label"] = packed_l
	view["shape_label"] = shape_l

	# Why the counter cannot issue yet. The server refuses REQUISITION outside DEPLOYING
	# (R65 — the bag is a bet on the contract's intel), and the station is reachable
	# before then, so the reason is stated instead of discovered as an error toast.
	var gate := Widgets.card_label("", 9, Color(0.44, 0.20, 0.16, 0.95), true, true)
	gate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(gate)
	view["gate_label"] = gate

	var seal := Button.new()
	seal.text = "Seal Expedition Pack"
	Record._ink(seal)
	seal.pressed.connect(func(): _seal(view))
	body.add_child(seal)
	view["seal"] = seal

	refresh(view)
	return view


static func refresh(view: Dictionary) -> void:
	var packed: Array = view["packed"]
	var full := packed.size() >= Catalog.BAG_SLOTS

	Pack.refresh(view["pack"], packed, func(id): return icon_for(id),
		func(id): _remove(view, String(id)))

	for id in view["rows"].keys():
		var row: Button = view["rows"][id]["row"]
		var on: bool = String(id) in packed
		# Packed instruments leave the register — they are in the case now. Dimmed
		# rather than removed, so the shelf never reflows under the cursor.
		row.modulate = Color(1, 1, 1, 0.35) if on else (Color(1, 1, 1, 0.55) if full else Color(1, 1, 1, 1))
		var who := _carried_by(view, String(id))
		var mark: Label = view["rows"][id]["state"]
		if on:
			mark.text = "packed"
			mark.add_theme_color_override("font_color", Color(0.44, 0.34, 0.18, 0.95))
		elif not who.is_empty():
			# A second copy is a wasted slot, so it is called what it is.
			mark.text = "held"   # shorter than "carried", which clipped against the scrollbar
			mark.add_theme_color_override("font_color", Color(0.30, 0.42, 0.34, 0.95))
		else:
			mark.text = ""

	(view["packed_label"] as Label).text = "PACKED: %d / %d" % [packed.size(), Catalog.BAG_SLOTS]
	(view["shape_label"] as Label).text = _shape(packed)
	var issuable: bool = view["can_issue"]
	(view["seal"] as Button).disabled = view["sealed"] or not issuable or packed.is_empty()
	(view["gate_label"] as Label).text = ("" if issuable else
		"The Collegium issues instruments against a charge already taken up. "
		+ "Take a contract from the board, then muster at the Deploy Gate.")

	var sel := String(view["sel"])
	if sel == "":
		Record.clear(view["record"])
	else:
		var item := Catalog.item_by_id(sel)
		var state := "packed" if sel in packed else ("full" if full else "shelf")
		Record.show_item(view["record"], item, icon_for(sel), state,
			func(): _act(view, sel), _carried_by(view, sel))


static func icon_for(item_id: String) -> AtlasTexture:
	var sheet := load(ICONS) as Texture2D
	if sheet == null or not ICON_INDEX.has(item_id):
		return null
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(int(ICON_INDEX[item_id]) * ICON_PX, 0, ICON_PX, ICON_PX)
	return at


## The pack's SHAPE, which the tally cannot say. Burden was considered and rejected:
## every instrument costs exactly one slot, so a weight would either restate
## "PACKED: n/4" or reintroduce the per-item cost TD-091 cut. What is actually worth
## knowing is the Observe/Test split — the real tradeoff the two groups exist to make.
static func _shape(packed: Array) -> String:
	if packed.is_empty():
		return ""
	var sight := 0
	for id in packed:
		var it := Catalog.item_by_id(String(id))
		if not it.is_empty() and String(it["kind"]) == "PERCEPTION":
			sight += 1
	var trial := packed.size() - sight
	if sight > 0 and trial == 0:
		return "SET TO READ"
	if trial > 0 and sight == 0:
		return "SET TO TEST"
	return "EVENLY SET"


# ── interaction ─────────────────────────────────────────────────────────────

static func _select(view: Dictionary, id: String) -> void:
	view["sel"] = id
	refresh(view)


static func _act(view: Dictionary, id: String) -> void:
	if id in view["packed"]:
		_remove(view, id)
	else:
		_pack(view, id)


static func _pack(view: Dictionary, id: String) -> void:
	var packed: Array = view["packed"]
	if view["sealed"] or id in packed or packed.size() >= Catalog.BAG_SLOTS:
		return
	var from: Control = view["rows"][id]["icon"] if view["rows"].has(id) else null
	var slot_index := packed.size()
	# The state changes when the instrument LANDS, so the pack fills as it is watched.
	Pack.fly_in(view["host"], view["pack"], from, icon_for(id), slot_index, view["reduced"],
		func():
			packed.append(id)
			(view["on_change"] as Callable).call(packed)
			refresh(view))


static func _remove(view: Dictionary, id: String) -> void:
	if view["sealed"]:
		return
	var packed: Array = view["packed"]
	packed.erase(id)
	(view["on_change"] as Callable).call(packed)
	refresh(view)


static func _seal(view: Dictionary) -> void:
	if view["sealed"] or (view["packed"] as Array).is_empty():
		return
	view["sealed"] = true
	refresh(view)
	SealRite.press(view["host"], view["pack"], view["reduced"], func():
		(view["on_requisition"] as Callable).call())


# ── builders ────────────────────────────────────────────────────────────────

static func _heading(text: String) -> Label:
	var l := Widgets.card_label(text, 9, PopupTheme.INK_DIM, false, false)
	l.add_theme_constant_override("line_spacing", 2)
	return l


static func _shelf_group(host: Node, title: String, kind: String, view: Dictionary) -> void:
	var h := Widgets.card_label(title, 8, Color(PopupTheme.INK_DIM.r, PopupTheme.INK_DIM.g, PopupTheme.INK_DIM.b, 0.8), false, false)
	host.add_child(h)
	for item in Catalog.GEAR:
		if String(item["kind"]) != kind:
			continue
		var id := String(item["id"])
		var built := _row(item, view)
		host.add_child(built["row"])
		view["rows"][id] = built


static func _row(item: Dictionary, view: Dictionary) -> Dictionary:
	var id := String(item["id"])
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, ICON_PX + 6)
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_stylebox_override("normal", PopupTheme.ruled(Color(0, 0, 0, 0)))
	for st in ["hover", "pressed"]:
		b.add_theme_stylebox_override(st, PopupTheme.ruled(PopupTheme.RULE_LIT))
	b.add_theme_stylebox_override("focus", Widgets.focus_ring())
	b.pressed.connect(func(): _select(view, id))
	b.tooltip_text = "Read its record."

	var box := HBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 7)
	b.add_child(box)

	var ic := TextureRect.new()
	ic.texture = icon_for(id)
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
	col.add_child(Widgets.card_label(String(item["name"]), 11, PopupTheme.INK, false, false))
	col.add_child(Widgets.card_label(_says(item), 8, PopupTheme.INK_DIM, false, false))

	var state := Widgets.card_label("", 8, Color(0.44, 0.34, 0.18, 0.95), false, true)
	state.custom_minimum_size = Vector2(34, 0)
	box.add_child(state)
	return {"row": b, "icon": ic, "state": state}


## Names of other Seekers already carrying `id`. Empty when nobody is.
static func _carried_by(view: Dictionary, id: String) -> Array:
	var who: Array = []
	for p in view.get("party", []):
		if id in p.get("bag", []):
			who.append(String(p.get("name", "?")))
	return who


static func _says(item: Dictionary) -> String:
	if String(item["kind"]) == "PERCEPTION":
		return String(ANSWERS.get(String(item["channel"]), "?"))
	return "offer it %s, and watch" % String(item["stimulus"]).to_lower()
