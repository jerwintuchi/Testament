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

const SHADOWS := "res://assets/ui/stations/gear_shadows.png"
const SHADOW_H := 3
const ICON_PX  := 24

# The dressing atlas — the author's own crates, cut out of the retired open cabinet.
# Cells match `gen_qm_furniture._emit_stock`; the crates are bottom-aligned in them,
# because a centred cell would hang the short ones in mid-air.
const STOCK    := "res://assets/ui/stations/qm_stock.png"
const STOCK_W  := 28
const STOCK_H  := 18
const STOCK_N  := 7

# How many instruments a rebuilt bay holds comfortably: 3 x 24px in a ~103px span leaves
# 30px of air. The shelves this leaves over become stock (R397).
const PER_SHELF := 3

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


# Hover is a Collegium-gold OUTLINE AND NOTHING ELSE (author ruling, TD-103).
#
# The lift and the warm tint are gone. An object that rises under the cursor reads as a
# UI element responding to a mouse; an object that catches an edge of light reads as one
# the Quartermaster has noticed — which is the difference the room is built on. It also
# stops the shelf twitching as the cursor crosses it.
#
# The outline is four one-pixel offset copies of the icon behind it, tinted gold: that
# reads at low resolution where a shader outline would smear, and it is built once and
# toggled, so hovering allocates nothing and runs no tween at all.
const GOLD_EDGE := Color(0.86, 0.70, 0.38, 1.0)

# HOVER CARRIES THE LIGHT (R404, author ruling, TD-115). The room is deliberately dark
# now, so the instrument under the cursor is lifted out of shadow as well as edged: a
# warm multiplier a little above white, so it reads as catching the candle rather than
# as a UI highlight.
#
# It is a property SET, not a tween — hovering allocates nothing and runs nothing per
# frame, which is also why reduced motion needs no special case here: there is no motion
# to reduce, only an instant brighten. And it is presentation ONLY (P181): no state is
# recorded, nothing is sent, and the object does not move, because TD-103 retired the
# lift on purpose — an object that rises under the cursor reads as a UI element
# responding to a mouse rather than as one the Quartermaster has noticed.
const LIT := Color(1.34, 1.22, 1.02, 1.0)


## `units[u]` is one BAY's shelf rows; `frames[u]` is where that bay's label is nailed;
## `stock` is the shelves no instrument stands on.
##
## The stock is the AUTHOR'S OWN CRATES, lifted out of the retired open cabinet by
## `gen_qm_furniture.py` — so the dressing is the same hand and the same resolution as
## the shelving it sits in, rather than a second set of objects drawn to sit beside it.
## It is seeded, so the store is the same room every time it is opened (P166), and it is
## never interactive (P167): a player who hovers scenery and gets nothing learns the room
## is lying to them.
static func build(host: Control, view: Dictionary, units: Array,
		on_select: Callable, frames: Array = [], stock: Array = []) -> Dictionary:
	var items := {}
	# Terse on purpose. A bay is 66px wide and "INSTRUMENTS OF SIGHT" measures ~90 at
	# 8px, so the old label ran off both ends of its own plate. The full term is not
	# lost — the record names the class ("Instrument of Sight") for whatever is chosen,
	# and this is signage on a cabinet, which is exactly where a word is enough.
	var kinds := [
		{"kind": "PERCEPTION", "label": "SIGHT"},
		{"kind": "PROBE",      "label": "TRIAL"},
	]

	# Dressing FIRST, so child order alone puts it behind every real instrument. An
	# earlier pass reached for `move_child(t, 0)` instead and sent the stock behind the
	# WALL — index 0 is the backdrop, not the back of the shelf. Build order is the
	# predictable tool; z-shuffling after the fact is not.
	for i in range(stock.size()):
		_stock(host, stock[i], i)

	for u in range(min(kinds.size(), units.size())):
		var rows: Array = units[u]
		var kind: String = kinds[u]["kind"]
		var ids: Array = []
		for item in Catalog.GEAR:
			if String(item["kind"]) == kind:
				ids.append(String(item["id"]))

		# The label rides the cabinet's crown, over the bay it names.
		if u < frames.size():
			var f: Rect2 = frames[u]
			Room.label_plate(host, String(kinds[u]["label"]), f.position, f.size.x)

		# Instruments fill from the BOTTOM shelves up, at most PER_SHELF to a shelf; the
		# shelves left over go to stock. Bottom-up because the lower shelves are nearer
		# the bench and its candle, and the room is deliberately dark at the top now
		# (R403) — a player should not have to hunt the unlit rows for the things they
		# can actually take.
		#
		# Both the count per shelf and how many shelves are used are DERIVED, so a new
		# instrument lands on a shelf without a line changing here (R362).
		var n := ids.size()
		var nrows: int = max(rows.size(), 1)
		var used: int = min(nrows, int(ceil(float(n) / float(PER_SHELF))))
		var first: int = nrows - used            # rows above this carry stock
		for r in range(first):
			_stock(host, rows[r], u * 8 + r)

		var at := 0
		for r in range(first, nrows):
			var take := int(ceil(float(n - at) / float(nrows - r)))
			var row: Rect2 = rows[r]
			var pitch := row.size.x / float(max(take, 1))
			for i in range(take):
				var cx := row.position.x + pitch * (i + 0.5)
				var home := Vector2(cx - ICON_PX * 0.5, row.end.y - ICON_PX)
				items[ids[at + i]] = _object(host, view, ids[at + i], home, on_select)
			at += take

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

	# The contact shadow is DERIVED from this instrument's own silhouette (TD-108):
	# dense where the object actually meets the board, scattering to loose pixels
	# outward. Every instrument used to cast the same 2px rectangle, which was the
	# clearest remaining tell that these were UI sprites rather than objects.
	#
	# It sits BEHIND the object and belongs to the shelf, not to the object. It does not
	# animate: hover is an outline only (TD-103), so the instrument never leaves the
	# board and there is nothing for a shadow to react to.
	var shadow := TextureRect.new()
	shadow.texture = shadow_for(id)
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.stretch_mode = TextureRect.STRETCH_KEEP
	shadow.position = Vector2(home.x, home.y + ICON_PX - 1.0)
	shadow.size = Vector2(ICON_PX, SHADOW_H)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(shadow)
	host.move_child(shadow, max(b.get_index() - 1, 0))

	# The gold edge: four offset copies behind the icon, revealed on hover. Built once
	# and shown/hidden, so hovering allocates nothing.
	var edge := Control.new()
	edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	edge.modulate = GOLD_EDGE
	edge.visible = false
	b.add_child(edge)
	for off in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var e := TextureRect.new()
		e.texture = _icon(id)
		e.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		e.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		e.set_anchors_preset(Control.PRESET_FULL_RECT)
		e.position = off
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edge.add_child(e)

	var ic := TextureRect.new()
	ic.texture = _icon(id)
	ic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ic.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)

	var rec := {"node": b, "icon": ic, "edge": edge, "shadow": shadow,
		"home": home, "state": AVAILABLE}

	b.mouse_entered.connect(func(): _set_hover(view, rec, true))
	b.mouse_exited.connect(func(): _set_hover(view, rec, false))
	b.focus_entered.connect(func(): _set_hover(view, rec, true))
	b.focus_exited.connect(func(): _set_hover(view, rec, false))
	b.pressed.connect(func(): on_select.call(id))
	return rec


static func _set_hover(_view: Dictionary, rec: Dictionary, on: bool) -> void:
	var want := next_state(int(rec["state"]), "hover" if on else "unhover")
	if want < 0:
		return                      # only AVAILABLE objects respond; nothing else moves
	rec["state"] = want
	# The whole of it. No tween, no movement — the instrument stays exactly where it was
	# placed, takes an edge of light, and is lifted out of the dark.
	(rec["edge"] as Control).visible = on
	(rec["icon"] as CanvasItem).modulate = LIT if on else Color(1, 1, 1, 1)


# ── dressing: scenery, never an item (R363 / P167) ──────────────────────────

## Fills one shelf with the author's crates, left to right with the odd gap so the row
## reads as stores that have been drawn from rather than as a tile pattern.
##
## Seeded from the band index alone, so two openings of the room produce the same shelf
## (P166) — a store that reshuffles between visits is not a place.
static func _stock(host: Control, band: Rect2, seed: int) -> void:
	var sheet := load(STOCK) as Texture2D
	if sheet == null:
		return
	var x := band.position.x
	var i := 0
	while x + STOCK_W <= band.end.x:
		var r := _hash(seed, i, 5)
		if r > 0.80:                       # a gap where something has been taken
			x += STOCK_W * 0.5
			i += 1
			continue
		var t := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(int(_hash(seed, i, 13) * STOCK_N) % STOCK_N * STOCK_W, 0,
			STOCK_W, STOCK_H)
		t.texture = at
		t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		t.stretch_mode = TextureRect.STRETCH_KEEP
		t.position = Vector2(x, band.end.y - STOCK_H)
		t.size = Vector2(STOCK_W, STOCK_H)
		# NEVER interactive, and visibly subordinate. Both halves matter: the reachable
		# objects have to be the lit ones, or the room offers an affordance it will not
		# honour. It is dimmed rather than shrunk — these are the author's crates at the
		# author's scale, and scaling them would be the one thing the art forbids.
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		t.modulate = Color(0.72, 0.70, 0.68, 0.94)
		host.add_child(t)
		x += STOCK_W + 1.0
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


## The contact shadow for one instrument, from the derived sheet. Indexed by the SAME
## `ICON_INDEX` as the icon, so a shadow can never end up under the wrong object.
static func shadow_for(item_id: String) -> AtlasTexture:
	var sheet := load(SHADOWS) as Texture2D
	if sheet == null or not ICON_INDEX.has(item_id):
		return null
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2(int(ICON_INDEX[item_id]) * ICON_PX, 0, ICON_PX, SHADOW_H)
	return at
