extends RefCounted
## The Collegium's stores — the ROOM the Quartermaster stands in (TD-101).
##
## Builds the environment only: the ashlar wall, the two shelving frames, the
## inspection counter and its lamp. It owns no items and no interaction; `shelf.gd`
## puts objects on the boards and `counter.gd` receives the one being inspected.
##
## Why a room and not a panel: the brief's §14 — the player must read a location, not
## a menu with a background. Everything here is scenery, so nothing in it is focusable
## and nothing responds to the mouse.
##
## LIGHT IS BAKED. `Light2D` cannot reach `Control` nodes (TD-047, re-confirmed for the
## world layer by TD-083), and this screen is entirely Control-based. The single moving
## thing is the lamp's flicker, a looping tween on `modulate` — no `_process`, no
## particle emitter, so it costs nothing per frame.

const Widgets := preload("res://scripts/ui/widgets.gd")
const Fonts   := preload("res://scripts/ui/fonts.gd")
const BoardDecor := preload("res://scripts/board/board_decor.gd")

# The Contract Board's own masonry, shared rather than copied (TD-116). See `_wall`.
const WALL    := "res://assets/ui/board/stone_tile.png"
const WALL_N  := "res://assets/ui/board/stone_tile_n.png"
# The board's own tiling, so the courses are the same size on both screens.
const WALL_TILE := Vector2(5.0, 4.2)
const LABEL   := "res://assets/ui/stations/qm_label.png"
const PROPS   := "res://assets/ui/stations/qm_props.png"

# ── the author's furniture (TD-113) ──────────────────────────────────────────
# Six hand-drawn pieces replace the generated shelving, bench and bench props. They
# are derived into runtime PNGs by `gen_qm_furniture.py`, which records why each is
# cropped or reduced the way it is; the geometry below is measured off those outputs.
#
# They carry their OWN baked light, drawn from the upper left — so they are NOT given
# `board_surface.gdshader` materials. Lighting art that is already lit darkens it twice,
# which is the first of TD-081's three lessons about authoring for a lit scene. The room
# still lights the wall it stands against, so the furniture reads as being IN the light
# rather than as emitting it.
## The furniture DOES take the room's light after all (TD-115), through a FLAT normal
## map: the shader's lit term is `ndl * atten`, and with the normal pointing straight out
## `ndl` varies with distance alone — so the art receives the candle's falloff and none of
## its direction, which is what keeps it from being relief-shaded twice (TD-081).
##
## This was measured, not assumed. Leaving the furniture unlit darkened the wall by 15%
## while the bench moved 0.2%, so the furniture ended up BRIGHTER than the wall behind
## it — the opposite of the mood being asked for.
const FLAT_N := "res://assets/ui/stations/qm_flat_n.png"
const FURN_AMBIENT := 0.60

const CABINET := "res://assets/ui/stations/qm_cabinet.png"
const TABLE   := "res://assets/ui/stations/qm_table.png"
const PR_SCALE := "res://assets/ui/stations/qm_prop_scale.png"
const PR_QUILL := "res://assets/ui/stations/qm_prop_quill.png"
const PR_STAMP := "res://assets/ui/stations/qm_prop_stamp.png"
const CLOTH   := "res://assets/ui/stations/qm_cloth.png"
const LANTERN := "res://assets/ui/stations/qm_lantern.png"
const BANNER  := "res://assets/ui/stations/qm_banner.png"
const NOTES   := "res://assets/ui/stations/qm_notes.png"
const FLOOR   := "res://assets/ui/stations/qm_floor.png"

const LABEL_M   := 7

# ── the cabinet, measured off `qm_cabinet.png` ───────────────────────────────
# ONE cabinet, not two (TD-114). The author's closed cabinet is 166 wide and the column
# is 339: a pair would leave 2px of air between them and against both edges, which reads
# as crammed rather than as fitted joinery. It is also unnecessary — the piece is drawn
# with a central stile and TWO BAYS, which is exactly the division the screen needs, so
# the asset's own structure carries the two kinds of instrument.
#
# Drawn 1:1 and never stretched, so these are absolutes. Every row is measured off the
# art: uprights at x 6-10 / 81-85 / 155-159, and a shelf is found by its lit top edge.
## REBUILT BIGGER AT 1:1 (R397, TD-115). 166x166 -> 240x199, by repeating bands of the
## author's own drawing rather than scaling it — see `gen_qm_furniture._emit_cabinet`.
## Four shelves per bay now, and a bay wide enough for three instruments instead of two.
const CAB_PX := Vector2(240, 199)

# Per bay: the clear span between its uprights, and the lit top row of every shelf,
# ordered top to bottom. MEASURED off the emitted PNG, never typed from the design
# (P182) — `gen_qm_furniture` prints what it emitted and `qm_budget.py` asserts these
# agree, so art and placement cannot drift apart.
const CAB_BAYS := [
	{"x": 13.0, "w": 104.0, "feet": [36.0, 69.0, 102.0, 135.0]},
	{"x": 125.0, "w": 103.0, "feet": [41.0, 67.0, 97.0, 130.0]},
]
# The deck above the drawers, spanning both bays. Always stock: it is below every shelf
# and in front of the drawers, so an instrument there would read as left out rather than
# stored. Whichever SHELVES end up unused are added to this by `shelf.gd`, which is the
# only place that knows how many instruments there are.
const CAB_STOCK := [
	{"x": 13.0, "w": 214.0, "y": 160.0},
]

# ── the bench, measured off `qm_table.png` ───────────────────────────────────
# An object set down on the bench stands on its TOP PLANE, so its feet come from here
# rather than from a hand-picked offset — the coupling P176 already forced between the
# cloth and the rest point, now extended to the plane the cloth is draped over.
const COUNTER_TOP_Y1 := 31.0            # the last row of the receding top surface
const COUNTER_ARRIS  := 32.0            # the lit front edge

# The bench is the ONE piece that is stretched, because it must span the column while
# the cabinets above it must not. Its middle is TILED rather than scaled: the front is
# vertical planking with iron bolts in it, and stretching would have widened every plank
# and ovalised every bolt. Tiling repeats them instead, which is what a longer bench
# would actually look like. The margins hold the corner brackets, the whole top plane
# and the plinth, so none of those repeat.
const COUNTER_ML := 26
const COUNTER_MT := 45
const COUNTER_MR := 26
const COUNTER_MB := 22
const CLOTH_PX  := Vector2(104, 46)   # matches gen_qm_room.CLOTH_W/H
const PROP_PX   := 24

# Dust motes in the candle's reach. Declared here so `tools/qm_budget.py` can read it.
const DUST_COUNT := 14

# Where the candle stands, as a fraction of the frame. ONE constant read by both the
# prop and the light rig, so the flame and the light it casts can never drift apart —
# the same coupling the board keeps between its sconce and `torch_rig` (P95).
# Where the candle stands across the counter. Its VERTICAL position is derived, not
# declared: a candle stands ON the surface, so its feet come from `COUNTER_Y` and only
# the flame's height above them is a constant. Declaring both independently is how the
# first pass ended up with a candle hovering seven pixels off the bench.
# The FILL, and it is now sourced at the HANGING LANTERN in the gutter rather than at a
# second lamp on the bench. The author's furniture needs the bench's whole length for the
# writing set, the scale and the seal, and a fill light does not need to stand on the
# surface it fills — but it does need a visible fixture (P95), which the lantern already
# is. One fewer object on the bench, and the light now comes from the thing you can see
# glowing.
## Moodier (R403, author ruling). The room was evenly browsable and read as flat; it is
## now dark at the edges with the bench as the lit working spot. Four numbers, not a
## lighting rewrite: this ambient, the candle's radius/energy below, this fill, and the
## vignette in `_wall`. Text is exempt — the header, the record and the rite plate are
## drawn above the surfaces and keep their own colours, because drama is spent on
## surfaces and never on legibility (TD-098's spirit).
const LAMP_ENERGY := 0.22
# The Contract Board's own wall ambient, not a number of this room's own: the two
# screens share the texture, so sharing the fill is what actually makes them match
# (TD-116). At 0.13 the same stone read near-black here and grey there.
const WALL_AMBIENT := 0.24
const VIGNETTE := 0.38

const CANDLE_FEET := 5.0     # how far the base sinks into the surface it stands on
const FLAME_UP    := 4.0     # the flame, measured down from the prop's top edge

# ── the bench's three zones, as offsets ALONG the counter (R371) ─────────────
# Local x, so the staging survives any change to the column's width or position. The
# centre is deliberately empty between the writing end and the sealing end: that gap is
# where the chosen instrument is set down, and the cloth marks it.
const Z_QUILL := 4.0
const Z_STAMP := 64.0
const Z_SCALE := -99.2      # from the RIGHT edge (negative = measured back from `end.x`)
const Z_CANDLE := -39.2

# Prop indices in qm_props.png. Only the CANDLE is still drawn: the author's quill-and-
# ink, scale and seal-stamp replace the generated ledger/papers/ink/scale/wax, and the
# bench lamp is retired in favour of the hanging lantern. The atlas is kept whole rather
# than re-cut — a sheet that loses a frame renumbers every frame after it.
const P_CANDLE := 1

# ── the room's geometry, in fractions of the viewport ────────────────────────
# Fractions, never fixed pixels: the canon is that anything on screen is sized from
# the viewport so it cannot run off it (TD-098).
# TWO ROWS, both columns aligned (author's composition, TD-107):
#   row 1   storage wall  |  inspection record
#   row 2   counter       |  open satchel
#   foot    SEAL & DEPART, spanning the full width
#
# The seal takes the whole width because it is the commitment — tucked into the right
# column it read as one more control in a stack, which is what a menu does.
const HEADER_H  := 0.115
const LEFT_X    := 0.030
const LEFT_W    := 0.530   # narrowed for the gutter (TD-110 T414)
const RIGHT_X   := 0.625
const RIGHT_W   := 0.347
# Row 1 is exactly one cabinet tall (166px at 640x360). The fraction is DERIVED from the
# art rather than chosen, because the cabinet is drawn 1:1 and a row that disagreed with
# it would either clip the piece or leave a band of wall under it. It runs to the bench,
# which then overlaps the cabinet's plinth by a few pixels — furniture standing against
# a wall with a counter in front of it, which is the depth the room wants anyway.
const SHELVES_Y := 0.12778
const SHELVES_H := 0.46111
const COUNTER_Y  := 0.590
const COUNTER_H2 := 0.255      # row 2's height, shared by the counter and the satchel
const SEAL_Y     := 0.852      # the rite, spanning the full width beneath both columns
const SEAL_H     := 0.085
# The right column runs nearly to the foot of the frame: at 0.72 it left a band of
# dead black under the rite while the RECORD — the thing with the most to say — was
# squeezed to 119px and hid its WARNING behind a scroll (R374/§19).
# The record runs from the cabinets' line down to the bench's. It takes the gutter row 1
# leaves as well, because the framed board spends 56px of its height on frame and title
# plate and the field note is the thing that pays for it.
const RIGHT_H   := 0.44722

# The ink of this room. Warmer and darker than the writ's parchment, because you are
# in a cellar store rather than reading a document.
const INK_WARM  := Color(0.82, 0.72, 0.52)
const INK_FAINT := Color(0.62, 0.54, 0.40)


## The room's light: one candle on the counter, packed for `board_surface.gdshader`.
##
## Light2D cannot reach Control nodes (TD-047, re-confirmed TD-083), which is precisely
## why that shader exists — it samples a normal map and its own uniform lights. The
## stores borrow it rather than inventing a second lighting path, so this room and the
## Contract Board are lit by the same code.
##
## A generous radius, unlike the board's tight 0.24 sconce halo: the board wants its
## wall to stay dungeon-dark around a framed object, while a WORKROOM should read as
## occupied — the light has to reach the shelves the player is being asked to browse.
## The bench's rect, derived from the same constants `build` uses. Public because both
## the light rig and the prop staging need it before `build` has run — declaring it in
## two places is how the candle and its light drifted apart in TD-105.
static func counter_rect_of(vp: Vector2) -> Rect2:
	return Rect2(vp.x * LEFT_X, vp.y * COUNTER_Y, vp.x * LEFT_W, vp.y * COUNTER_H2)


## Where the hanging lantern's fixture is, so its glow and its body are one point.
static func lantern_pos(vp: Vector2) -> Vector2:
	return Vector2(vp.x * LEFT_X + vp.x * LEFT_W + 8.0, vp.y * 0.100)


## An object's feet on the bench's top plane, `dx` along it. Negative `dx` measures back
## from the right edge, so the sealing end stays put when the column is re-proportioned.
static func bench_stand(vp: Vector2, dx: float, size: Vector2) -> Vector2:
	var r := counter_rect_of(vp)
	var x := (r.position.x + dx) if dx >= 0.0 else (r.end.x + dx)
	return Vector2(x, counter_stand_y(r) - size.y)


## The candle prop's top-left corner. ONE source for the object and its light.
static func candle_pos(vp: Vector2) -> Vector2:
	return bench_stand(vp, Z_CANDLE, Vector2(PROP_PX, PROP_PX)) + Vector2(0, CANDLE_FEET)


static func candle_rig(vp: Vector2) -> Array:
	var flame := candle_pos(vp) + Vector2(PROP_PX * 0.5, FLAME_UP)
	var lamp := lantern_pos(vp) + Vector2(10.0, 26.0)
	return [
		{
			"uv": Vector2(flame.x / vp.x, flame.y / vp.y),
			"color": Color(1.0, 0.74, 0.44),
			# Calmer (TD-116, author review: "the candle light looks so bright"). At
			# 0.34/1.05 the bench measured 81.4 against 26.4 a metre away — a hotspot
			# rather than a pool. Wider and weaker reaches the same distance without
			# blowing out the wood it stands on.
			"radius": 0.42,
			"energy": 0.72,
		},
		{
			# The fill. Weak and wide: it lifts the far shelves off black without
			# competing with the bench, and it is warm-neutral rather than a second
			# candle, because two equal flames would flatten the room again.
			"uv": Vector2(lamp.x / vp.x, lamp.y / vp.y),
			"color": Color(0.92, 0.80, 0.62),
			"radius": 0.52,
			"energy": LAMP_ENERGY,
		},
	]


## A surface material lit by this room's candle. Thin wrapper so no call site has to
## remember to pass the rig — forgetting it would silently light the stores from the
## Contract Board's torches, which are not in this room.
static func lit(vp: Vector2, normal_path: String, ambient: float = 0.34,
		diffuse_gain: float = 1.0, tile: Vector2 = Vector2.ONE) -> ShaderMaterial:
	return BoardDecor.surface_material(vp, normal_path, ambient, diffuse_gain, tile,
		1.0, candle_rig(vp))


## Builds the room into `host` and returns the rects the other modules need.
## Nothing returned is a node the caller may reparent — they are geometry.
static func build(host: Control, vp: Vector2) -> Dictionary:
	_wall(host, vp)

	var shelf_rect := Rect2(vp.x * LEFT_X, vp.y * SHELVES_Y, vp.x * LEFT_W, vp.y * SHELVES_H)
	var counter_rect := Rect2(vp.x * LEFT_X, vp.y * COUNTER_Y, vp.x * LEFT_W, vp.y * COUNTER_H2)
	# Row 1 right: the record. Row 2 right: the satchel, level with the counter.
	var right_rect := Rect2(vp.x * RIGHT_X, vp.y * SHELVES_Y, vp.x * RIGHT_W, vp.y * RIGHT_H)
	var satchel_rect := Rect2(vp.x * RIGHT_X, vp.y * COUNTER_Y, vp.x * RIGHT_W, vp.y * COUNTER_H2)
	var seal_rect := Rect2(vp.x * LEFT_X, vp.y * SEAL_Y,
		vp.x * (RIGHT_X + RIGHT_W) - vp.x * LEFT_X, vp.y * SEAL_H)

	_header(host, vp)
	_furniture(host, vp, shelf_rect)
	var shelving := _shelving(host, shelf_rect)
	_counter(host, counter_rect)

	return {
		"shelf_rect": shelf_rect,
		"counter_rect": counter_rect,
		"right_rect": right_rect,
		"satchel_rect": satchel_rect,
		"seal_rect": seal_rect,
		"units": shelving[0],    # per bay, the shelf rows instruments may stand on
		"frames": shelving[1],   # per bay, where its label plate is nailed
		"stock": shelving[2],    # the shelves left to the author's crates
	}


## The room's furniture: banner, hung lantern, pinned notes, floor. Everything here
## is BAKED or static and costs one node apiece (P175) — only the lantern animates,
## and it earns its own node by doing so.
static func _furniture(host: Control, vp: Vector2, shelves: Rect2) -> void:
	# The banner takes the corner the header used to sit in.
	_sprite(host, BANNER, Vector2(vp.x * 0.008, vp.y * 0.020), furn_lit(vp))

	# The gutter between the shelves and the record column: the lantern hangs at its
	# head and the pinned notes sit beneath, exactly as the reference stages them.
	# Its position comes from `lantern_pos`, which the light rig also reads — the lantern
	# is the fill's fixture now, so the two may not be declared separately (P95).
	var at := lantern_pos(vp)
	_flicker(_sprite(host, LANTERN, at))
	_sprite(host, NOTES, Vector2(at.x - 6.0, vp.y * 0.400), furn_lit(vp))

	# Flagstones along the foot, tiling across. The room has a floor now, so the frame
	# stops in a place rather than fading into black.
	var fl := TextureRect.new()
	fl.texture = load(FLOOR) as Texture2D
	fl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fl.stretch_mode = TextureRect.STRETCH_TILE
	fl.position = Vector2(0, vp.y * 0.966)
	fl.size = Vector2(vp.x, vp.y * 0.034)
	fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl.material = furn_lit(vp)
	host.add_child(fl)


## One static sprite drawn 1:1 NEAREST. Never scaled: everything here is authored at
## the size it is shown, which is what keeps the pixels square (TD-050/TD-055).
static func _sprite(host: Control, path: String, at: Vector2,
		mat: Material = null) -> TextureRect:
	var t := TextureRect.new()
	t.texture = load(path) as Texture2D
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.position = at
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.material = mat
	host.add_child(t)
	return t


## A material that puts an already-lit piece of art into the room's pools — falloff
## only, never relief. See the FLAT_N block for why that distinction matters.
static func furn_lit(vp: Vector2) -> ShaderMaterial:
	return lit(vp, FLAT_N, FURN_AMBIENT)


# ── the environment ─────────────────────────────────────────────────────────

## THE BOARD'S OWN MASONRY (TD-116, author review: "the wall doesn't look consistent
## with the contract board").
##
## The Quartermaster used to draw its own `qm_wall.png` in `navestone`, on the TD-081
## reasoning that the stores and the Great Hall should be the same building. Put beside
## the board it was plainly a different one: measured off the two textures, the board's
## stone is cool grey with speckled, pitted block interiors and small courses, while the
## Quartermaster's was warm brown with block interiors that are UNIFORM FIELDS carrying
## nothing but a dotted joint. That emptiness is also why the shader read as a render —
## a smooth gradient painted across nothing.
##
## So the room now hangs on the Contract Board's wall, with the board's own tiling and
## its own treatment: `STRETCH_SCALE` plus `texture_repeat`, the shader doing the tiling
## at the board's scale, ambient low so the masonry is REVEALED by the candle rather
## than lit evenly. One texture for both screens is also the only way the two can never
## drift apart again.
static func _wall(host: Control, vp: Vector2) -> void:
	var w := TextureRect.new()
	w.texture = load(WALL) as Texture2D
	w.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	w.stretch_mode = TextureRect.STRETCH_SCALE       # UV 0..1; the shader does the tiling
	w.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	w.set_anchors_preset(Control.PRESET_FULL_RECT)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.material = lit(vp, WALL_N, WALL_AMBIENT, 1.0, WALL_TILE)
	host.add_child(w)

	# The room falls off into darkness at the edges, so the lamp-lit middle is where
	# the eye settles. One baked gradient, not a full-frame additive layer.
	var vig := ColorRect.new()
	vig.color = Color(0, 0, 0, VIGNETTE)
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(vig)


static func _header(host: Control, vp: Vector2) -> void:
	var box := VBoxContainer.new()
	# Shifted right of the banner, which now holds the corner.
	box.position = Vector2(vp.x * 0.082, vp.y * 0.028)
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(box)

	var t := Widgets.card_label("QUARTERMASTER", 15, INK_WARM, false, false)
	t.add_theme_font_override("font", Fonts.heading())
	box.add_child(t)
	var s := Widgets.card_label("COLLEGIUM STORES · EXPEDITION ISSUE", 8, INK_FAINT, false, false)
	box.add_child(s)


## One cabinet, centred, its two bays carrying the two kinds of instrument. The
## reference's PROVISIONS / RELICS / TOOLS do not exist in the catalog and are not
## invented here — the brief's own §4 forbids that.
##
## Returns, per bay, the shelf rows an instrument may stand on; plus the label anchors
## and the shelves left to stock. Nothing here knows what an instrument IS.
static func _shelving(host: Control, rect: Rect2) -> Array:
	var at := Vector2(rect.position.x + (rect.size.x - CAB_PX.x) * 0.5, rect.position.y)
	_sprite(host, CABINET, at, furn_lit(vp_of(host)))

	var rows: Array = []
	var frames: Array = []
	for bay in CAB_BAYS:
		var unit: Array = []
		for feet in bay["feet"]:
			unit.append(Rect2(at.x + float(bay["x"]), at.y + float(feet) - 24.0,
				float(bay["w"]), 24.0))
		rows.append(unit)
		# The label rides the cabinet's crown, over the bay it names, and sits two pixels
		# PROUD of it — nailed on rather than inlaid. Proud also keeps it clear of the
		# top shelf: the left bay uses all three of its shelves, so an instrument stands
		# directly under the crown and a plate flush with it would clip that row.
		frames.append(Rect2(at.x + float(bay["x"]), at.y - 2.0, float(bay["w"]), 13.0))

	var stock: Array = []
	for band in CAB_STOCK:
		stock.append(Rect2(at.x + float(band["x"]), at.y + float(band["y"]) - 18.0,
			float(band["w"]), 18.0))
	return [rows, frames, stock]


## Where the cloth is draped, and therefore where an instrument is set down. ONE
## definition, read by the room that draws it and by the counter that rests on it.
## Where an object's FEET land on the counter — on the top plane, three pixels behind
## the arris, so some surface reads behind the object and the lit edge reads in front.
## Landing it past the arris would stand it on the counter's FRONT FACE, i.e. in mid-air.
static func counter_stand_y(counter_rect: Rect2) -> float:
	return counter_rect.position.y + COUNTER_TOP_Y1 - 3.0


static func cloth_rect(counter_rect: Rect2) -> Rect2:
	# The cloth's OWN authored size, drawn 1:1 — never scaled to fit the counter,
	# because scaling is what destroyed its crosses the first time.
	# Its top edge sits ON the bench's back edge, not above it. At -7 the cloth's first
	# rows hung against the wall behind and read as a floating rectangle; the author's
	# bench has a real back edge to lay it against, which the generated one did not.
	return Rect2(
		counter_rect.position.x + counter_rect.size.x * 0.5 - CLOTH_PX.x * 0.5,
		counter_rect.position.y, CLOTH_PX.x, CLOTH_PX.y)


## A shelf's label plate. Public so `shelf.gd` can name each unit from the catalog's
## own kinds rather than from a string this file invented.
static func label_plate(host: Control, text: String, at: Vector2, width: float) -> Control:
	var plate := _nine(LABEL, LABEL_M)
	plate.position = at
	plate.size = Vector2(width, 14)
	host.add_child(plate)
	# Aged gold on crimson. Gold is scarce in this room by rule (P168) and a category
	# plaque is a HEADING — the one place besides the seal and the ready state where the
	# order puts gold on something.
	# Measured at 3.38:1 against its own crimson plate, under the 4.5 floor (TD-116).
	# Lifted rather than the plate darkened: the plaque is the order's cloth colour and
	# the gold is the lettering, so the lettering is the half that may move.
	var l := Widgets.card_label(text, 8, Color(0.96, 0.86, 0.60), false, true)
	l.set_anchors_preset(Control.PRESET_FULL_RECT)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(l)
	return plate


static func _counter(host: Control, rect: Rect2) -> void:
	var c := _nine4(TABLE, COUNTER_ML, COUNTER_MT, COUNTER_MR, COUNTER_MB, true)
	c.position = rect.position
	c.size = rect.size
	c.material = furn_lit(vp_of(host))
	host.add_child(c)

	# The altar cloth. NOT decoration (author ruling, TD-110): this is the inspection
	# surface, and `Counter.rest_point` derives from this SAME rect — so the chosen
	# instrument cannot land beside the thing it is meant to be set down on (P176).
	# The same coupling the candle and its light needed in TD-105.
	# A TextureRect at 1:1, NOT a 9-slice: the crosses live in the middle, which is
	# exactly the region a 9-slice stretches — it smeared them into gold streaks.
	var cl := TextureRect.new()
	cl.texture = load(CLOTH) as Texture2D
	cl.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cl.stretch_mode = TextureRect.STRETCH_KEEP
	var cr := cloth_rect(rect)
	cl.position = cr.position
	cl.size = cr.size
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.material = furn_lit(vp_of(host))
	host.add_child(cl)

	# THREE ZONES (R371), so the bench reads as a place someone works rather than a
	# plank with ornaments on it: the Quartermaster WRITES at the left end, the
	# instrument is inspected in the middle, and the SEALING tools live at the right,
	# next to the candle. The centre is deliberately clear — that gap is where the chosen
	# object is set down, and the cloth marks it.
	#
	# Every prop is scenery: ignore-filtered, unfocusable, no tooltip (P169). A room
	# must not offer an affordance it will not honour.
	#
	# All four stand on the bench's TOP PLANE, from the same `bench_stand` the instrument
	# uses. They are tall — the scale rises well above the bench and in front of the
	# cabinets behind it, which is what a scale on a bench in front of a cabinet does.
	var vp := vp_of(host)
	_bench_prop(host, PR_QUILL, vp, Z_QUILL)
	_bench_prop(host, PR_STAMP, vp, Z_STAMP)
	_bench_prop(host, PR_SCALE, vp, Z_SCALE)
	# Placed FROM the rig's constants, so flame and light are the same point by
	# construction (the coupling the board keeps between its sconce and `torch_rig`, P95).
	var candle := _prop(host, P_CANDLE, candle_pos(vp))
	_flicker(candle)
	_dust(host, rect)


## One of the author's bench props, standing on the top plane at `dx` along it. Drawn
## 1:1 NEAREST and unlit for the reason in the const block: the art is already lit.
static func _bench_prop(host: Control, path: String, vp: Vector2, dx: float) -> TextureRect:
	var tex := load(path) as Texture2D
	if tex == null:
		return null
	return _sprite(host, path, bench_stand(vp, dx, tex.get_size()), furn_lit(vp))


static func _prop(host: Control, index: int, at: Vector2) -> TextureRect:
	var t := TextureRect.new()
	var at_tex := AtlasTexture.new()
	at_tex.atlas = load(PROPS) as Texture2D
	at_tex.region = Rect2(index * PROP_PX, 0, PROP_PX, PROP_PX)
	t.texture = at_tex
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.position = at
	t.size = Vector2(PROP_PX, PROP_PX)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(t)
	return t


## A little dust in the candle's reach — the room is old and worked in (R377). Kept
## to a handful and confined to the counter's warm end: this is a dusty storeroom, not
## weather, and the brief is explicit that fog is wrong for it.
static func _dust(host: Control, rect: Rect2) -> void:
	var p := CPUParticles2D.new()
	p.amount = DUST_COUNT
	p.lifetime = 9.0
	p.preprocess = 6.0
	p.position = Vector2(rect.end.x - 70.0, rect.position.y - 6.0)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(58.0, 26.0)
	p.direction = Vector2(-1, -0.35)
	p.spread = 26.0
	p.gravity = Vector2(0, -1.5)
	p.initial_velocity_min = 1.5
	p.initial_velocity_max = 4.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 1.0
	p.color = Color(0.86, 0.76, 0.56, 0.30)
	host.add_child(p)


## The room's one moving thing. A looping tween, NOT a particle emitter and NOT
## `_process`: the budget allows twenty particles for dust and nothing for a flame
## that a modulate can carry just as well.
static func _flicker(node: CanvasItem) -> void:
	var tw := node.create_tween().set_loops()
	tw.tween_property(node, "modulate", Color(1.06, 1.02, 0.94), 1.7).set_trans(Tween.TRANS_SINE)
	tw.tween_property(node, "modulate", Color(0.94, 0.92, 0.90), 2.3).set_trans(Tween.TRANS_SINE)


# ── builders ────────────────────────────────────────────────────────────────

## The frame this room is drawn into. The shader needs it for the aspect ratio and for
## placing lights in screen space, and the sub-builders only receive rects.
static func vp_of(host: Control) -> Vector2:
	return host.get_viewport().get_visible_rect().size


## A 9-slice with PER-SIDE margins. The counter needs them: its top margin holds a
## whole receding plane (26px) while its foot holds only the plinth (16px), and a
## single margin would have to compromise one of them.
static func _nine4(path: String, l: int, t: int, r: int, b: int,
		tile_h: bool = false) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	sb.texture_margin_left = float(l)
	sb.texture_margin_top = float(t)
	sb.texture_margin_right = float(r)
	sb.texture_margin_bottom = float(b)
	if tile_h:
		# TILE_FIT, not TILE: it rounds to a whole number of repeats, so the bench never
		# ends on half a plank. See the counter's const block for why the middle repeats
		# instead of stretching.
		sb.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func _nine(path: String, margin: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(margin))
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p
