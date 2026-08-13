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

# The record's board — the author's framed parchment (TD-113). It replaces the Contract
# Board's bare `parch_v1_0` sheet, which was the one object on this screen that came from
# another feature. Its own title plate is now where the instrument's NAME is written, so
# the name leaves the scrolling body and the short column gains a whole heading back.
const SHEET := "res://assets/ui/stations/qm_record_frame.png"
# Per side. The top holds the title plate AND the parchment's ragged top edge; the rest
# hold the corner brackets. Measured off the art, not guessed.
# 9-slice margins, MEASURED off the emitted 234x166 (TD-119). Each must contain the
# fixed furniture it protects: the top holds the title plate AND the iron corner plates,
# the sides hold those corners and the hanging banner tatters, the foot holds the lower
# rail. Only the parchment field between them is allowed to stretch.
const SHEET_ML := 30
const SHEET_MT := 34
const SHEET_MR := 30
const SHEET_MB := 26
# The plate's own band inside the frame, for the name written on it. Measured at source
# y 8..22, and horizontally at x 63..173 of 234 — which after the 9-slice's centre squeeze
# lands at roughly 0.275 to 0.734 of the frame's width. Fractions rather than pixels, so
# the name stays on its plate if the column is ever re-proportioned.
const PLATE_Y  := 9.0
const PLATE_H  := 13.0
const PLATE_X_FRAC := 0.275
const PLATE_W_FRAC := 0.459
const RITE      := "res://assets/ui/stations/qm_rite.png"
const RITE_SEAL := "res://assets/ui/stations/qm_rite_seal.png"
const RITE_M    := 10
# The not-ready letter. Subdued is the design (R376: gold is earned by departure), but
# subdued is not the same as illegible — the old value measured 3.81:1 against its own
# plate, under the 4.5 floor. This is still visibly held back from the ready gold.
const NOT_READY_INK := Color(0.74, 0.67, 0.53)

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
		func(id): _select(view, String(id)), geo["frames"], geo["stock"])

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

## The left column's width, for the gate line that sits under the bench. Derived from
## the rite's own rect so it cannot drift from the composition around it.
static func vp_left_w(seal_rect: Rect2) -> float:
	return seal_rect.size.x * 0.60


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
	sb.texture_margin_left = float(SHEET_ML)
	sb.texture_margin_top = float(SHEET_MT)
	sb.texture_margin_right = float(SHEET_MR)
	sb.texture_margin_bottom = float(SHEET_MB)
	# Content clears the frame AND the title plate above it — the plate is drawn inside
	# the top margin, so a content margin equal to the texture margin would put the
	# record's first line straight over the name written on it.
	# Trimmed to the paper's real edge rather than to the frame's: the record column is
	# short, and every pixel of margin here is a line of the field note that scrolls out
	# of sight. The paper starts two rows under the plate and runs to the lower brackets.
	# Content is inset to the PARCHMENT, not to the frame, and the numbers are measured
	# THROUGH the 9-slice rather than off the source — the centre stretches, so the source
	# edge is not where the paper lands. In target space the ragged edge sits at a median
	# of 28 with bites as deep as 45; at 24 the opening quote of the record's question was
	# being clipped by a tear. These clear the median with room to spare and accept that a
	# letter may occasionally touch a deep bite, which reads as paper rather than as damage.
	sb.content_margin_left = 32.0
	sb.content_margin_top = 35.0
	sb.content_margin_right = 32.0
	sb.content_margin_bottom = 21.0
	sheet.add_theme_stylebox_override("panel", sb)
	sheet.position = rec_rect.position
	sheet.size = rec_rect.size
	root.add_child(sheet)

	# The name, engraved on the frame's own plate. A child of `root`, NOT of the frame:
	# the frame is a PanelContainer, and a container LAYS OUT its children — parenting it
	# there threw the plate down into the content rect and printed the name across the
	# record's first sentence. The same trap the record's own column carries a comment
	# about, met one level further out.
	var plate := Widgets.card_label("", 13, Color(0.30, 0.22, 0.12), false, true)
	plate.add_theme_font_override("font", Fonts.heading())
	plate.clip_text = true
	plate.position = rec_rect.position + Vector2(rec_rect.size.x * PLATE_X_FRAC, PLATE_Y)
	plate.size = Vector2(rec_rect.size.x * PLATE_W_FRAC, PLATE_H)
	plate.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(plate)

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
	view["record"] = Record.build(body_scroll, col, plate)

	# Row 2 right — the open satchel, level with the counter. It sits BESIDE the bench
	# rather than under the record because that is where a bag being loaded actually is:
	# on the same surface as the hands loading it.
	var pack_host := Control.new()
	pack_host.position = satchel_rect.position
	pack_host.size = satchel_rect.size
	root.add_child(pack_host)
	# The tally is RESERVED FOR, not appended after. As a third child of a VBox it was
	# simply pushed out of the host when the pack's own minimum height grew with the
	# type — and what it was pushed onto was the rite plate (TD-117). Its band is taken
	# off the bottom first and the pack gets what is left, so it cannot be displaced.
	var tally_h := 15.0
	var pack_col := VBoxContainer.new()
	pack_col.position = Vector2.ZERO
	pack_col.size = Vector2(pack_host.size.x, pack_host.size.y - tally_h)
	pack_col.add_theme_constant_override("separation", 2)
	pack_col.clip_contents = true
	pack_host.add_child(pack_col)
	view["pack"] = Pack.build(pack_col, Catalog.BAG_SLOTS)

	var tally := HBoxContainer.new()
	tally.alignment = BoxContainer.ALIGNMENT_CENTER
	tally.add_theme_constant_override("separation", 14)
	tally.position = Vector2(0.0, pack_host.size.y - tally_h)
	tally.size = Vector2(pack_host.size.x, tally_h)
	pack_host.add_child(tally)
	var packed_l := Widgets.card_label("", 11, Room.INK_WARM, false, false)
	var shape_l := Widgets.card_label("", 11, Room.INK_FAINT, false, false)
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
	# ONE line, under the bench and over the LEFT column only. Two lines spanning the full
	# width no longer fit: the type went up (TD-117) and the pack row moved down to meet
	# it, so the old two-line block ran through both the pack and the rite plate.
	var gate := Widgets.card_label("", 10, Color(0.78, 0.50, 0.42), false, true)
	gate.position = Vector2(seal_rect.position.x, seal_rect.position.y - 14.0)
	gate.size = Vector2(vp_left_w(seal_rect), 13.0)
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
		10, Color(0.66, 0.56, 0.38), false, true)
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
		"Take a contract from the board first.")

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
	b.add_theme_font_size_override("font_size", 13)
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
		b.add_theme_color_override(st, Color(0.94, 0.82, 0.54) if ready else NOT_READY_INK)
	b.add_theme_color_override("font_disabled_color", NOT_READY_INK)


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
