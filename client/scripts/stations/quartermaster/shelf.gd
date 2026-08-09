extends RefCounted
## Instruments as objects standing on the stores' shelves (TD-101).
##
## Owns placement, hover, and the item state machine. It does NOT own the catalog:
## every position is derived from `Catalog.GEAR` order, so a new instrument appears on
## a shelf without a line changing here (R362).
##
## Two rules shape the whole file:
##
## 1. **Objects are absolutely positioned, never laid out by a container.** A
##    VBox/HBox recomputes its children's positions whenever one changes size — which
##    is exactly what must not happen when an instrument lifts under the cursor or
##    leaves for the counter. Absolute placement means AVAILABLE → ON_COUNTER →
##    AVAILABLE returns an object to the same pixel (R365).
##
## 2. **State drives presentation; nothing is baked into a texture** (brief §18).
##    `next_state()` is a pure function so the machine can be reasoned about — and
##    checked — without a running scene.

const Widgets := preload("res://scripts/ui/widgets.gd")
const Catalog := preload("res://scripts/core/catalog.gd")
const Room    := preload("res://scripts/stations/quartermaster/room.gd")

const STOCK  := "res://assets/ui/stations/qm_stock.png"
const STOCK_PX := 16
const STOCK_N  := 8
const ICON_PX  := 24

# ── the item state machine (P164) ────────────────────────────────────────────
enum { AVAILABLE, HOVERED, SELECTED, ON_COUNTER, PACKING, PACKED, REMOVING }

## Pure: the next state for an event, or -1 when the event does not apply. Kept free
## of nodes so the machine is checkable on its own — the presentation reads the state,
## never the other way round.
static func next_state(state: int, event: String) -> int:
	match event:
		"hover":    return HOVERED if state == AVAILABLE else -1
		"unhover":  return AVAILABLE if state == HOVERED else -1
		"select":   return SELECTED if state in [AVAILABLE, HOVERED] else -1
		"arrived":  return ON_COUNTER if state == SELECTED else -1
		"pack":     return PACKING if state == ON_COUNTER else -1
		"landed":   return PACKED if state == PACKING else -1
		"remove":   return REMOVING if state == PACKED else -1
		"returned": return AVAILABLE if state in [REMOVING, ON_COUNTER, SELECTED] else -1
	return -1


# Hover is restrained on purpose (R364): a small lift, a slight brightening, a shadow
# that tightens. No outline, no glow, no particles — the brief forbids all three.
const LIFT_PX   := 3.0
const T_HOVER   := 0.09
const HOVER_TINT := Color(1.18, 1.13, 1.02)


static func build(host: Control, view: Dictionary, units: Array,
		on_select: Callable, dress: Array = [], frames: Array = []) -> Dictionary:
	var items := {}
	var kinds := [
		{"kind": "PERCEPTION", "label": "INSTRUMENTS OF SIGHT"},
		{"kind": "PROBE",      "label": "INSTRUMENTS OF TRIAL"},
	]

	for u in range(min(kinds.size(), units.size())):
		var unit: Rect2 = units[u]
		var kind: String = kinds[u]["kind"]
		var ids: Array = []
		for item in Catalog.GEAR:
			if String(item["kind"]) == kind:
				ids.append(String(item["id"]))

		# The label rides the unit's TOP RAIL, where a store actually nails one. Hung
		# just above the instruments it sat on top of the upper shelf's stock instead.
		var lp: Vector2 = (Vector2(frames[u].position.x + 7.0, frames[u].position.y + 3.0)
			if u < frames.size() else Vector2(unit.position.x, unit.position.y - 15.0))
		Room.label_plate(host, String(kinds[u]["label"]), lp, 108.0)

		var n := ids.size()
		var pitch := unit.size.x / float(n)
		var base_y := unit.end.y - ICON_PX

		# Dressing FIRST, so child order alone puts it behind every real instrument.
		# The first pass used `move_child(t, 0)` instead and sent the stock behind the
		# WALL — index 0 is the backdrop, not the back of the shelf. Build order is the
		# predictable tool; z-shuffling after the fact is not.
		_stock(host, unit, n, pitch, u)
		# The upper board carries stock only — never an instrument, so a player never
		# has to hunt two rows for something they can actually take.
		if u < dress.size():
			_fill(host, dress[u], u + 40)

		# Even pitch across the unit, computed from the count — so six instruments and
		# four instruments both sit centred on their own board.
		for i in range(n):
			var cx := unit.position.x + pitch * (i + 0.5)
			var home := Vector2(cx - ICON_PX * 0.5, base_y)
			items[ids[i]] = _object(host, view, ids[i], home, on_select)

	return items


# ── one instrument ──────────────────────────────────────────────────────────

static func _object(host: Control, view: Dictionary, id: String, home: Vector2,
		on_select: Callable) -> Dictionary:
	# A Button, so the shelf is reachable by keyboard exactly as the pack is. Its
	# stylebox is empty: the affordance is the object lifting, not a frame around it.
	var b := Button.new()
	b.position = home
	b.size = Vector2(ICON_PX, ICON_PX)
	b.focus_mode = Control.FOCUS_ALL
	b.flat = true
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus", Widgets.focus_ring())
	host.add_child(b)

	# The contact shadow sits BEHIND the object and belongs to the shelf, not to the
	# object — so when the instrument lifts, the shadow stays on the board and only
	# tightens. That separation is what makes the lift read as physical.
	var shadow := ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.45)
	shadow.position = Vector2(home.x + 3.0, home.y + ICON_PX - 2.0)
	shadow.size = Vector2(ICON_PX - 6.0, 2.0)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(shadow)
	host.move_child(shadow, max(b.get_index() - 1, 0))

	var ic := TextureRect.new()
	ic.texture = _icon(id)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)

	var rec := {"node": b, "icon": ic, "shadow": shadow, "home": home, "state": AVAILABLE}

	b.mouse_entered.connect(func(): _set_hover(view, rec, true))
	b.mouse_exited.connect(func(): _set_hover(view, rec, false))
	b.focus_entered.connect(func(): _set_hover(view, rec, true))
	b.focus_exited.connect(func(): _set_hover(view, rec, false))
	b.pressed.connect(func(): on_select.call(id))
	return rec


static func _set_hover(view: Dictionary, rec: Dictionary, on: bool) -> void:
	var want := next_state(int(rec["state"]), "hover" if on else "unhover")
	if want < 0:
		return                      # only AVAILABLE objects respond; nothing else moves
	rec["state"] = want
	var b: Control = rec["node"]
	var shadow: Control = rec["shadow"]
	var home: Vector2 = rec["home"]

	if bool(view.get("reduced", false)):
		b.position = home + (Vector2(0, -LIFT_PX) if on else Vector2.ZERO)
		b.modulate = HOVER_TINT if on else Color.WHITE
		return

	var tw := b.create_tween().set_parallel(true)
	tw.tween_property(b, "position", home + (Vector2(0, -LIFT_PX) if on else Vector2.ZERO), T_HOVER)
	tw.tween_property(b, "modulate", HOVER_TINT if on else Color.WHITE, T_HOVER)
	# The shadow tightens as the object rises — the cheapest possible cue that it left
	# the board, and the one a player reads without being told.
	tw.tween_property(shadow, "size", Vector2(ICON_PX - (10.0 if on else 6.0), 2.0), T_HOVER)
	tw.tween_property(shadow, "position",
		Vector2(home.x + (5.0 if on else 3.0), shadow.position.y), T_HOVER)


# ── dressing: scenery, never an item (R363 / P167) ──────────────────────────

static func _stock(host: Control, unit: Rect2, n: int, pitch: float, seed: int) -> void:
	var sheet := load(STOCK) as Texture2D
	if sheet == null:
		return
	# One or two pieces in each gap, chosen by a seeded hash so the room is the same
	# every time it is opened (P166) — a store that reshuffles is not a place.
	for i in range(n + 1):
		var gx := unit.position.x + pitch * i
		var span := pitch - ICON_PX
		if span < STOCK_PX + 2.0:
			continue
		var count := 1 + int(_hash(seed, i, 3) * 2.0)
		for k in range(count):
			var idx := int(_hash(seed, i * 7 + k, 11) * STOCK_N) % STOCK_N
			var ox := gx + (ICON_PX * 0.5) + 2.0 + k * (STOCK_PX + 1.0)
			if ox + STOCK_PX > unit.end.x:
				break
			var t := TextureRect.new()
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(idx * STOCK_PX, 0, STOCK_PX, STOCK_PX)
			t.texture = at
			t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			t.stretch_mode = TextureRect.STRETCH_KEEP
			t.position = Vector2(ox, unit.end.y - STOCK_PX)
			t.size = Vector2(STOCK_PX, STOCK_PX)
			# NEVER interactive, and visibly subordinate. Both halves matter: a player
			# who hovers scenery and gets nothing learns the room is lying to them.
			t.mouse_filter = Control.MOUSE_FILTER_IGNORE
			t.modulate = Color(0.74, 0.72, 0.70, 0.92)
			host.add_child(t)


## Fills a whole board edge to edge with stock, for the shelves that hold no
## instruments. Seeded, so the store is the same room every time it is opened (P166).
static func _fill(host: Control, band: Rect2, seed: int) -> void:
	var sheet := load(STOCK) as Texture2D
	if sheet == null:
		return
	var x := band.position.x
	var i := 0
	while x + STOCK_PX <= band.end.x:
		var r := _hash(seed, i, 5)
		# A gap now and then, so the row reads as stock that has been drawn from
		# rather than as a tile pattern.
		if r > 0.82:
			x += STOCK_PX * 0.6
			i += 1
			continue
		var idx := int(_hash(seed, i, 13) * STOCK_N) % STOCK_N
		var t := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(idx * STOCK_PX, 0, STOCK_PX, STOCK_PX)
		t.texture = at
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.stretch_mode = TextureRect.STRETCH_KEEP
		t.position = Vector2(x, band.end.y - STOCK_PX)
		t.size = Vector2(STOCK_PX, STOCK_PX)
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Dimmer than the lower shelf's stock: it is further from the lamp, and it
		# must never pull the eye off the row that can actually be taken from.
		t.modulate = Color(0.60, 0.58, 0.56, 0.88)
		host.add_child(t)
		x += STOCK_PX + 1.0 + (2.0 if r > 0.55 else 0.0)
		i += 1


static func _hash(a: int, b: int, salt: int) -> float:
	var n := (a * 73856093) ^ (b * 19349663) ^ (salt * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


# ── the instrument icons ────────────────────────────────────────────────────
#
# The sheet is REUSED, not re-authored: brief §5 says not to duplicate item artwork
# that already exists. The lookup lives here rather than in `register.gd` so the
# dependency runs ONE WAY (register → shelf) — the other direction would make the
# preloads cyclic, which is the trap TD-067 recorded.
const ICONS := "res://assets/ui/stations/gear_icons.png"

const ICON_INDEX := {
	"ashen-lens": 0, "chirurgeons-glass": 1, "witness-prism": 2, "trackers-fetish": 3,
	"cantors-ear": 4, "augurs-bead": 5,
	"censer-of-embers": 6, "phial-of-hoarfrost": 7, "consecrated-salt": 8,
	"lantern-of-the-creed": 9,
}


static func icon_for(item_id: String) -> AtlasTexture:
	var sheet := load(ICONS) as Texture2D
	if sheet == null or not ICON_INDEX.has(item_id):
		return null
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(int(ICON_INDEX[item_id]) * ICON_PX, 0, ICON_PX, ICON_PX)
	return at


static func _icon(id: String) -> AtlasTexture:
	return icon_for(id)
