extends RefCounted
## The Quartermaster — the Collegium's stores, and the coordinator for its parts.
##
## TD-101 turned this from a writ with a list on it into a ROOM: shelving on the left,
## an inspection counter beneath it, the record and the expedition pack on the right.
## The interaction is physical throughout — browse, handle, inspect, pack, seal — and
## this file owns none of it directly. It wires:
##
##   room.gd     the environment (wall, shelving, counter, lamp)
##   shelf.gd    the instruments as objects, hover, and the item state machine
##   counter.gd  the carry to and from the inspection surface
##   record.gd   the ledger entry for whatever is on the counter
##   pack.gd     the expedition pack and the flight into it
##   seal_rite.gd the closing ceremony
##
## Dependencies run ONE WAY (register → the rest), so no `preload` is cyclic — the
## trap TD-067 recorded when `main.gd` was decomposed.
##
## Render + intent only (S3.5): it never touches `_net`. `on_requisition` carries the
## sealed pack out; the shell owns the socket and the server validates regardless, so
## everything here is an affordance (P148).
##
## What sealing does NOT do: deploy. Requisition stays reversible until the leader
## deploys at the Deploy Gate, which is the server's phase gate and the deliberate
## commitment boundary. The rite commits THE PACK, and says so.

const Widgets    := preload("res://scripts/ui/widgets.gd")
const PopupTheme := preload("res://scripts/ui/popup_theme.gd")
const Fonts      := preload("res://scripts/ui/fonts.gd")
const Catalog    := preload("res://scripts/core/catalog.gd")
const Room       := preload("res://scripts/stations/quartermaster/room.gd")
const Shelf      := preload("res://scripts/stations/quartermaster/shelf.gd")
const Counter    := preload("res://scripts/stations/quartermaster/counter.gd")
const Pack       := preload("res://scripts/stations/quartermaster/pack.gd")
const Record     := preload("res://scripts/stations/quartermaster/record.gd")
const Lore       := preload("res://scripts/stations/quartermaster/lore.gd")
const SealRite   := preload("res://scripts/stations/quartermaster/seal_rite.gd")

const SHEET := "res://assets/ui/board/parch_v1_0.png"

# ── the render budget (canon: performance.md P0/P3) ─────────────────────────
#
# Stated before the room was built, and CHECKED here rather than asserted: a still
# capture cannot show a frame cost, so the room counts itself once at build and warns
# if it has grown. `tools/qm_budget.py` proves these constants are load-bearing.
const NODE_BUDGET     := 220   # every Control the room instantiates, counted once
const PARTICLE_BUDGET := 20    # dust in the lamp light; the room ships with zero

# What an instrument settles, in a hunter's words — never the wire enum (R320).
const ANSWERS := {
	"RESIDUE": "what did it leave behind?", "STRESS_MARK": "what hurts it?",
	"REACTION": "what does it shrug off?", "SPOOR": "how does it hunt?",
	"LITURGY": "how can it be ended without killing?", "OMEN": "what does it do before it strikes?",
}


static func build(body: Node, host: Node, selected: Array,
		on_change: Callable, on_requisition: Callable, reduced: bool,
		can_issue: bool = true, party: Array = []) -> Dictionary:
	var vp: Vector2 = (host as Node).get_viewport().get_visible_rect().size

	# One root, filling the frame, holding the whole room. Objects are positioned
	# ABSOLUTELY inside it — see shelf.gd for why a container would break the carry.
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.custom_minimum_size = vp
	body.add_child(root)

	var view := {
		"host": host, "root": root, "vp": vp,
		"packed": selected, "sel": "", "sealed": false,
		"on_change": on_change, "on_requisition": on_requisition, "reduced": reduced,
		"can_issue": can_issue, "party": party, "items": {},
	}

	var geo := Room.build(root, vp)
	view["counter"] = Counter.build(root, geo["counter_rect"])
	view["items"] = Shelf.build(root, view, geo["units"],
		func(id): _select(view, String(id)), geo["dress"], geo["frames"])

	_right_column(view, root, geo["right_rect"])

	refresh(view)
	_report_budget(root)
	return view


## Counts what the room actually built and says so, once. A capture proves how the
## stores LOOK and says nothing about what they cost — this is the number that does,
## and it is printed rather than trusted (performance.md P3).
static func _report_budget(root: Control) -> void:
	var n := _descendants(root)
	print("[client] qm nodes=%d/%d particles=0/%d" % [n, NODE_BUDGET, PARTICLE_BUDGET])
	if n > NODE_BUDGET:
		push_warning("Quartermaster room over node budget: %d > %d" % [n, NODE_BUDGET])


static func _descendants(n: Node) -> int:
	var total := 0
	for c in n.get_children():
		total += 1 + _descendants(c)
	return total


# ── the right-hand column: record, pack, tally, seal ────────────────────────

static func _right_column(view: Dictionary, root: Control, rect: Rect2) -> void:
	# The record sits on the board's own parchment — the one paper object in a room
	# made of wood and iron, which is what a filed document should look like.
	# A PanelContainer, NOT a Panel. A Panel does not lay out its children, so an
	# anchored column ignores the stylebox's content margin and the record's text runs
	# off both edges of the paper — which is exactly what the first pass shipped, and
	# exactly the trap `pack.gd` already carries a comment about.
	var sheet := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(SHEET) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, 18.0)
	sb.set_content_margin_all(11.0)
	sheet.add_theme_stylebox_override("panel", sb)
	# The three bands are computed from what they CONTAIN, not as fractions of the
	# column. Fractions put the pack's 76px of case into a 61px slot, and it drew
	# straight through the tally beneath it — the record simply takes what is left.
	var pack_h := 76.0
	var foot_h := 52.0
	var record_h := maxf(rect.size.y - pack_h - foot_h - 12.0, 60.0)

	sheet.position = rect.position
	sheet.size = Vector2(rect.size.x, record_h)
	root.add_child(sheet)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	sheet.add_child(col)

	# The record's BODY scrolls; its action is pinned beneath. A long note otherwise
	# grows the column past the paper and the decision walks off the sheet — the same
	# failure the writ version hit, for the same reason.
	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(body_scroll)
	Widgets.ink_scrollbar(body_scroll.get_v_scroll_bar())
	view["record"] = Record.build(body_scroll, col)

	# The pack, below the record. Its own object, in leather and iron.
	var pack_host := Control.new()
	pack_host.position = Vector2(rect.position.x, rect.position.y + record_h + 5.0)
	pack_host.size = Vector2(rect.size.x, pack_h)
	root.add_child(pack_host)
	var pack_col := VBoxContainer.new()
	pack_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_col.add_theme_constant_override("separation", 2)
	pack_host.add_child(pack_col)
	view["pack"] = Pack.build(pack_col, Catalog.BAG_SLOTS)

	# The tally and the rite, at the foot.
	var foot := VBoxContainer.new()
	foot.position = Vector2(rect.position.x, rect.position.y + record_h + pack_h + 11.0)
	foot.size = Vector2(rect.size.x, foot_h)
	foot.add_theme_constant_override("separation", 1)
	root.add_child(foot)

	var tally := HBoxContainer.new()
	tally.alignment = BoxContainer.ALIGNMENT_CENTER
	tally.add_theme_constant_override("separation", 14)
	foot.add_child(tally)
	var packed_l := Widgets.card_label("", 9, Room.INK_WARM, false, false)
	var shape_l := Widgets.card_label("", 9, Room.INK_FAINT, false, false)
	tally.add_child(packed_l); tally.add_child(shape_l)
	view["packed_label"] = packed_l
	view["shape_label"] = shape_l

	# Why the counter cannot issue yet. The server refuses REQUISITION outside
	# DEPLOYING (R65 — the bag is a bet on the contract's intel) and the station is
	# reachable before then, so the reason is stated rather than discovered as an error.
	var gate := Widgets.card_label("", 8, Color(0.72, 0.42, 0.34), true, true)
	gate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot.add_child(gate)
	view["gate_label"] = gate

	var seal := Button.new()
	seal.text = "SEAL & DEPART"
	_seal_ink(seal)
	seal.pressed.connect(func(): _seal(view))
	foot.add_child(seal)
	view["seal"] = seal


static func refresh(view: Dictionary) -> void:
	var packed: Array = view["packed"]
	var full := packed.size() >= Catalog.BAG_SLOTS

	Pack.refresh(view["pack"], packed, func(id): return icon_for(id),
		func(id): _remove(view, String(id)))

	# A packed instrument is IN THE CASE, so it is not on the shelf either. Hidden
	# rather than dimmed: the room is physical, and a thing cannot be in two places.
	for id in view["items"].keys():
		var rec: Dictionary = view["items"][id]
		var on: bool = String(id) in packed
		var node: Control = rec["node"]
		var shadow: Control = rec["shadow"]
		if on:
			node.visible = false
			shadow.visible = false
		elif String(view["sel"]) != String(id):
			node.visible = true
			shadow.visible = true

	(view["packed_label"] as Label).text = "PACKED  %d / %d" % [packed.size(), Catalog.BAG_SLOTS]
	(view["shape_label"] as Label).text = _shape(packed)
	var issuable: bool = view["can_issue"]
	(view["seal"] as Button).disabled = view["sealed"] or not issuable or packed.is_empty()
	(view["gate_label"] as Label).text = ("" if issuable else
		"The Collegium issues instruments against a contract.\nTake one from the board first.")

	var sel := String(view["sel"])
	if sel == "":
		Record.clear(view["record"])
		Counter.set_caption(view["counter"], "")
	else:
		var item := Catalog.item_by_id(sel)
		var state := "packed" if sel in packed else ("full" if full else "shelf")
		Record.show_item(view["record"], item, icon_for(sel), state,
			func(): _act(view, sel), _carried_by(view, sel))
		Counter.set_caption(view["counter"], String(item.get("name", "")).to_upper())


## The instrument icons. Delegated to `shelf.gd`, which owns the sheet — kept here as
## a forward because `pack.gd` and `record.gd` are handed a callable, not a module.
static func icon_for(item_id: String) -> AtlasTexture:
	return Shelf.icon_for(item_id)


## The pack's SHAPE, which the tally cannot say. Burden was considered and rejected:
## every instrument costs exactly one slot, so a weight would either restate
## "PACKED n/4" or reintroduce the per-item cost TD-091 cut — and the reference's
## `Uses`/`Weight`/`LOAD` are the same forbidden ladder. What is actually worth knowing
## is the Observe/Test split, the real tradeoff the two shelves exist to make.
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

## Sealing, from outside the module — the same entry the button uses, so a capture
## exercises the real rite rather than a staged end state.
static func seal(view: Dictionary) -> void:
	_seal(view)


## Selecting an instrument, from outside the module. Debug captures use this so they
## exercise the REAL path — setting `sel` and refreshing skips the carry entirely, and
## the first `--qm-pick` capture showed a record filled for an object still on its shelf.
static func select(view: Dictionary, id: String) -> void:
	_select(view, id)


## Selecting brings the object to the counter. The previous one goes back to its exact
## shelf position FIRST — the counter holds one thing, and nothing is ever destroyed
## to make room for the next (R365).
static func _select(view: Dictionary, id: String) -> void:
	if view["sealed"] or String(view["sel"]) == id:
		return
	var prev := String(view["sel"])
	var items: Dictionary = view["items"]
	var reduced: bool = view["reduced"]

	if prev != "" and items.has(prev) and not (prev in view["packed"]):
		Counter.carry_out(items[prev], reduced)

	view["sel"] = id
	if not items.has(id):
		refresh(view)
		return

	# The record fills when the instrument LANDS, so the screen keeps pace with the
	# hand rather than running ahead of it.
	Counter.carry_in(view["counter"], items[id], reduced, func():
		items[id]["state"] = Shelf.ON_COUNTER
		refresh(view))


static func _act(view: Dictionary, id: String) -> void:
	if id in view["packed"]:
		_remove(view, id)
	else:
		_pack(view, id)


static func _pack(view: Dictionary, id: String) -> void:
	var packed: Array = view["packed"]
	if view["sealed"] or id in packed or packed.size() >= Catalog.BAG_SLOTS:
		return
	# The flight starts from the COUNTER, because that is where the object is — it was
	# carried there when it was chosen. Flying it from the shelf would contradict what
	# the player is looking at.
	var items: Dictionary = view["items"]
	var from: Control = items[id]["node"] if items.has(id) else null
	var slot_index := packed.size()
	Pack.fly_in(view["host"], view["pack"], from, icon_for(id), slot_index, view["reduced"],
		func():
			if items.has(id):
				items[id]["state"] = Shelf.PACKED
			packed.append(id)
			view["sel"] = ""
			(view["on_change"] as Callable).call(packed)
			refresh(view))


## Taking an instrument back out returns it to its shelf position. It never blinks
## out: the physical illusion is the whole point of the redesign (R367).
static func _remove(view: Dictionary, id: String) -> void:
	if view["sealed"]:
		return
	var packed: Array = view["packed"]
	packed.erase(id)
	var items: Dictionary = view["items"]
	if items.has(id):
		var rec: Dictionary = items[id]
		rec["state"] = Shelf.AVAILABLE
		(rec["node"] as Control).position = rec["home"]
		(rec["node"] as Control).visible = true
		(rec["shadow"] as Control).visible = true
	if String(view["sel"]) == id:
		view["sel"] = ""
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

static func _seal_ink(b: Button) -> void:
	# The rite's own button: brass on dark wood, not ink on paper — it belongs to the
	# room, not to the record.
	b.add_theme_stylebox_override("normal", _plate(Color(0.42, 0.33, 0.18, 0.85)))
	for st in ["hover", "pressed", "focus"]:
		b.add_theme_stylebox_override(st, _plate(Color(0.62, 0.49, 0.26, 0.95)))
	b.add_theme_stylebox_override("disabled", _plate(Color(0.30, 0.24, 0.14, 0.40)))
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Room.INK_WARM)
	b.add_theme_color_override("font_disabled_color", Color(0.52, 0.46, 0.36, 0.45))
	b.add_theme_font_size_override("font_size", 11)
	var f := Fonts.heading()
	if f != null:
		b.add_theme_font_override("font", f)


static func _plate(edge: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.07, 0.05, 0.80)
	sb.border_color = edge
	sb.set_border_width_all(1)
	sb.set_content_margin_all(5)
	return sb


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


## Ids the lore table is missing — the two halves cannot drift apart silently.
static func missing_ids() -> Array:
	var missing: Array = []
	for item in Catalog.GEAR:
		if Lore.of(String(item["id"])).is_empty():
			missing.append(String(item["id"]))
	return missing
