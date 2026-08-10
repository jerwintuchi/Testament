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
const RITE      := "res://assets/ui/stations/qm_rite.png"
const RITE_SEAL := "res://assets/ui/stations/qm_rite_seal.png"
const RITE_M    := 10

# ── the render budget (canon: performance.md P0/P3) ─────────────────────────
#
# Stated before the room was built, and CHECKED here rather than asserted: a still
# capture cannot show a frame cost, so the room counts itself once at build and warns
# if it has grown. `tools/qm_budget.py` proves these constants are load-bearing.
const NODE_BUDGET     := 220   # every Control the room instantiates, counted once
const PARTICLE_BUDGET := 20    # dust in the lamp light (Room.DUST_COUNT)

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

	_right_column(view, root, geo["right_rect"], geo["satchel_rect"], geo["seal_rect"])

	refresh(view)
	_report_budget(root)
	return view


## Counts what the room actually built and says so, once. A capture proves how the
## stores LOOK and says nothing about what they cost — this is the number that does,
## and it is printed rather than trusted (performance.md P3).
static func _report_budget(root: Control) -> void:
	var n := _descendants(root)
	print("[client] qm nodes=%d/%d particles=%d/%d"
		% [n, NODE_BUDGET, Room.DUST_COUNT, PARTICLE_BUDGET])
	if n > NODE_BUDGET:
		push_warning("Quartermaster room over node budget: %d > %d" % [n, NODE_BUDGET])


static func _descendants(n: Node) -> int:
	var total := 0
	for c in n.get_children():
		total += 1 + _descendants(c)
	return total


# ── the right-hand column: record, pack, tally, seal ────────────────────────

static func _right_column(view: Dictionary, root: Control, rec_rect: Rect2,
		satchel_rect: Rect2, seal_rect: Rect2) -> void:
	# Row 1 right — the record, on the board's own parchment: the one paper object in a
	# room of wood and iron, which is what a filed document should look like.
	#
	# A PanelContainer, NOT a Panel. A Panel does not lay out its children, so an
	# anchored column ignores the stylebox's content margin and the record's text runs
	# off both edges of the paper — the trap `pack.gd` already carries a comment about.
	var sheet := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(SHEET) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, 18.0)
	sb.set_content_margin_all(11.0)
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.position = rec_rect.position
	sheet.size = rec_rect.size
	root.add_child(sheet)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	sheet.add_child(col)

	# The record's BODY scrolls; its action is pinned beneath. A long note otherwise
	# grows the column past the paper and the decision walks off the sheet.
	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(body_scroll)
	Widgets.ink_scrollbar(body_scroll.get_v_scroll_bar())
	view["record"] = Record.build(body_scroll, col)

	# Row 2 right — the open satchel, level with the counter. It sits BESIDE the bench
	# rather than under the record because that is where a bag being loaded actually is:
	# on the same surface as the hands loading it.
	var pack_host := Control.new()
	pack_host.position = satchel_rect.position
	pack_host.size = satchel_rect.size
	root.add_child(pack_host)
	var pack_col := VBoxContainer.new()
	pack_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	pack_col.add_theme_constant_override("separation", 2)
	pack_host.add_child(pack_col)
	view["pack"] = Pack.build(pack_col, Catalog.BAG_SLOTS)

	var tally := HBoxContainer.new()
	tally.alignment = BoxContainer.ALIGNMENT_CENTER
	tally.add_theme_constant_override("separation", 14)
	pack_col.add_child(tally)
	var packed_l := Widgets.card_label("", 9, Room.INK_WARM, false, false)
	var shape_l := Widgets.card_label("", 9, Room.INK_FAINT, false, false)
	tally.add_child(packed_l); tally.add_child(shape_l)
	view["packed_label"] = packed_l
	view["shape_label"] = shape_l

	# The foot — the rite, spanning the WHOLE width. It is the commitment, and tucked
	# into a column it read as one more control in a stack, which is what a menu does.
	var foot := VBoxContainer.new()
	foot.position = seal_rect.position
	foot.size = seal_rect.size
	foot.add_theme_constant_override("separation", 1)
	root.add_child(foot)

	# Why the counter cannot issue yet. The server refuses REQUISITION outside
	# DEPLOYING (R65 — the bag is a bet on the contract's intel) and the station is
	# reachable before then, so the reason is stated rather than met as an error.
	# NOT a child of the foot. This is the ROOT CAUSE of the overlap: a variable-height
	# message sharing a fixed-height container with the plate pushed the plate out of
	# its own rect and onto the motto positioned beneath it. The gate is a status line
	# about the counter, not part of the rite, so it sits above the foot on its own.
	var gate := Widgets.card_label("", 8, Color(0.72, 0.42, 0.34), true, true)
	gate.position = Vector2(seal_rect.position.x, seal_rect.position.y - 21.0)
	gate.size = Vector2(seal_rect.size.x, 20.0)
	gate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(gate)
	view["gate_label"] = gate

	# The rite, as a crimson plate rather than a bordered box. Its 9-slice CENTRE is a
	# uniform field, which is the only shape a 9-slice may safely take — the lesson the
	# altar cloth and the record's divider each taught once (TD-110).
	var seal := Button.new()
	seal.text = "SEAL & DEPART"
	seal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seal.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_seal_ink(seal)
	seal.pressed.connect(func(): _seal(view))
	foot.add_child(seal)
	view["seal"] = seal

	# The order's disc at the plate's left hand, and the motto beneath it. Both are
	# scenery: the plate is the control, and a seal you can click would be a second
	# button that does the same thing.
	# Beneath the plate, and a CHILD of the foot rather than a label positioned at
	# `seal_rect.end.y`. Absolute placement assumed the plate ends where its rect ends;
	# a container guarantees it.
	var motto := Widgets.card_label("\u2720   THE COLLEGIUM STANDS WITNESS   \u2720",
		8, Color(0.66, 0.56, 0.38), false, true)
	motto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	motto.custom_minimum_size = Vector2(0, 10)
	motto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(motto)

	var disc := TextureRect.new()
	disc.texture = load(RITE_SEAL) as Texture2D
	disc.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	disc.stretch_mode = TextureRect.STRETCH_KEEP
	disc.position = Vector2(seal_rect.position.x + 7.0,
		seal_rect.position.y + seal_rect.size.y * 0.30)
	disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(disc)



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

	(view["packed_label"] as Label).text = "EXPEDITION PACK — %d / %d" % [packed.size(), Catalog.BAG_SLOTS]
	(view["shape_label"] as Label).text = _shape(packed)
	var issuable: bool = view["can_issue"]
	var seal_btn: Button = view["seal"]
	seal_btn.disabled = view["sealed"] or not issuable or packed.is_empty()
	_seal_state(seal_btn, not seal_btn.disabled)
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
		Counter.carry_out(items[prev], reduced, Callable(), view["counter"])

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
	b.add_theme_stylebox_override("disabled", _plate(Color(0.30, 0.24, 0.14, 0.40), 1))
	b.add_theme_color_override("font_disabled_color", Color(0.52, 0.46, 0.36, 0.45))
	b.add_theme_font_size_override("font_size", 11)
	var f := Fonts.heading()
	if f != null:
		b.add_theme_font_override("font", f)
	_seal_state(b, false)


## Departure is the one action that earns Collegium gold (R376). While the pack cannot
## be issued the plate stays subdued and low-contrast; when it can, the border thickens
## and takes gold. Restrained — a stronger edge and a warmer letter, never a flash.
static func _seal_state(b: Button, ready: bool) -> void:
	# READY wears the crimson-and-gold plate; not-ready is the same plate held back to a
	# dim modulate. One object in two states, rather than two different-looking controls.
	var sb := StyleBoxTexture.new()
	sb.texture = load(RITE) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(RITE_M))
	sb.set_content_margin_all(6.0)
	sb.modulate_color = Color(1, 1, 1, 1) if ready else Color(0.46, 0.44, 0.42, 0.75)
	for st in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, Color(0.94, 0.82, 0.54) if ready else Color(0.52, 0.46, 0.36))
	b.add_theme_color_override("font_disabled_color", Color(0.52, 0.46, 0.36))


static func _plate(edge: Color, width: int = 1) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.07, 0.05, 0.80)
	sb.border_color = edge
	sb.set_border_width_all(width)
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
