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


## `units[u]` is one cabinet's instrument ROWS (its lower two alcoves); `frames[u]` is
## the cabinet itself, for its label.
##
## The generated stock scatter is GONE. The author's cabinet has crates drawn into its
## alcoves, so the room's non-interactive dressing (R363) is now baked art: it costs no
## nodes, it cannot be hovered by construction rather than by remembering to set
## `MOUSE_FILTER_IGNORE` on every piece (P167), and it reads as the same object as the
## shelving it sits in. The instruments stand IN FRONT of it, which is also the right
## depth cue — reachable things near, stores behind.
static func build(host: Control, view: Dictionary, units: Array,
		on_select: Callable, frames: Array = []) -> Dictionary:
	var items := {}
	var kinds := [
		{"kind": "PERCEPTION", "label": "INSTRUMENTS OF SIGHT"},
		{"kind": "PROBE",      "label": "INSTRUMENTS OF TRIAL"},
	]

	for u in range(min(kinds.size(), units.size())):
		var rows: Array = units[u]
		var kind: String = kinds[u]["kind"]
		var ids: Array = []
		for item in Catalog.GEAR:
			if String(item["kind"]) == kind:
				ids.append(String(item["id"]))

		# The label rides the cabinet's TOP RAIL, where a store actually nails one, and
		# spans its full width so it reads as belonging to that cabinet.
		if u < frames.size():
			var f: Rect2 = frames[u]
			Room.label_plate(host, String(kinds[u]["label"]),
				Vector2(f.position.x + 3.0, f.position.y - 1.0), f.size.x - 6.0)

		# Split across the cabinet's rows, fuller row first, so six instruments fill two
		# alcoves 3-and-3 and four fill them 2-and-2 — both derived from the count, so a
		# new instrument lands on a shelf without a line changing here (R362).
		var n := ids.size()
		var nrows: int = max(rows.size(), 1)
		var at := 0
		for r in range(nrows):
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
	# The whole of it. No tween, no movement, no tint — the instrument stays exactly
	# where it was placed and simply takes an edge of light.
	(rec["edge"] as Control).visible = on


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
