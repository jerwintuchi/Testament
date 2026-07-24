## The Contract Board itself: the wall the writs hang on. Builds the canvas, lays the live
## petitions out under the keep-out solver, hangs the flavor scraps, the decay, the vignette,
## the bottom bar, the sign and the keybind strip — extracted verbatim from main.gd under
## TD-067 T231, the last tranche.
##
## A preloaded RefCounted namespace (S3.2/S3.4) rather than a scene, for the same reason as
## `NoticeReader`: the board is TRANSIENT — `build()` makes a fresh canvas into the station
## popup's body on every open and rebuild, and the old one is freed. Nothing here persists
## between builds except the art, which is immutable.
##
## The shell keeps the socket (S3.5): everything this needs arrives on a `Ctx`, and the two
## things it must ask the shell to do — take a writ down (`on_select`) and lay it on the
## reader (`show_reader`) — are Callables. This module never touches `_net`, never reads
## authoritative state except through the snapshot it was handed, and mutates no game state
## (I1). It renders what the server last said, and nothing else.
extends RefCounted

const BoardGeo = preload("res://scripts/board/board_geometry.gd")
const BoardDecor = preload("res://scripts/board/board_decor.gd")
const BoardBar = preload("res://scripts/board/board_bar.gd")
const BoardHeader = preload("res://scripts/board/board_header.gd")
const NoticeCard = preload("res://scripts/board/notice_card.gd")
const Widgets = preload("res://scripts/ui/widgets.gd")

# Board art that belongs to the wall rather than to a card. Static + loaded once from the
# shell's `_ready`, so the load timing is exactly what it was before the extraction.
static var _backing_tex: Texture2D   # plank backing 9-slice, behind the notices
static var _cobweb_tex: Texture2D    # grayscale-additive corner decay strand (tinted at runtime)
static var _votive_tex: Texture2D    # dead votive candle, ambient sacred-decay prop


## Everything the wall needs from the shell, passed explicitly so this module reads nothing
## global (I1). `on_select`/`show_reader` are how it asks the shell to act — it never acts itself.
class Ctx extends RefCounted:
	var host: Node                 # for get_tree() (focus traversal, deferred dumps)
	var body: VBoxContainer        # the station popup's body — where the canvas lands
	var title: Label               # the popup's plain title, hidden in favour of the carved sign
	var stone: Control             # the masonry layer behind the popup — the torches' host
	var snapshot: Dictionary       # authoritative; the board and the sealed contract come from here
	var selection: Dictionary      # the writ currently taken down, or {} for the grid view
	var reduced_motion := false
	var viewport := Vector2(640, 360)
	var on_select: Callable        # (intel) -> void            — take this writ down / put it back
	var show_reader: Callable      # (canvas, intel) -> Control — lay the open writ on the wall
	var logger: Callable           # (String) -> void


## Load the wall art. Idempotent; a missing texture is simply skipped.
static func load_art() -> void:
	NoticeCard.load_art()
	if _backing_tex == null:
		_backing_tex = load("res://assets/ui/board/backing_v1.png") as Texture2D
	if _cobweb_tex == null:
		_cobweb_tex = load("res://assets/ui/board/cobweb.png") as Texture2D
	if _votive_tex == null:
		_votive_tex = load("res://assets/ui/board/votive.png") as Texture2D


# ── The Notice Board (specs/notice-board) ────────────────────────────────────
# A wooden installation, not a menu: portrait parchment notices tacked at seeded
# angles across the board (no scroll). The 4 live contracts are clickable; a few
# decorative flavor notices are inert ambiance. Clicking a live notice "takes it
# down" — it enlarges to centre over the dimmed board (a writ), where the party
# signs the charge. Every notice string comes from ContractIntel + contractId via
# `Notice`; nothing here is trait-derived or authoritative (I1/I3).

# Inert ambient notices — pure flavor (P65). No contractId, never selectable.
const FLAVOR_NOTICES := [
	{ "head": "ATTENTION", "body": "All bearers of unsanctioned relics must present them at the Reliquary before the next bell." },
	{ "head": "A PLEA", "body": "My brother went to the fens with the last party and has not returned. Leave any word with the Almoner." },
	{ "head": "NOTICE OF DECAY", "body": "The east chancel is closed by order of the Wardens. The ground is no longer trustworthy." },
	{ "head": "OBSERVANCE", "body": "Vespers are moved to the crypt until the upper nave is reconsecrated." },
]

# The live-notice stack (backlight, shadow, card) draws at this z — above the wall vignette
# (z 2), below the bar (4) / placard (5) / reader (10). Keeps the writs off the shadowed wall.
const LIVE_Z := 3

static func _dump_notes(ctx: Ctx, notes: Control) -> void:
	await ctx.host.get_tree().process_frame
	ctx.logger.call("notes children=%d canvas_global=%s" % [notes.get_child_count(), notes.get_global_rect()])
	for c in notes.get_children():
		var ct: Control = c
		ctx.logger.call("  %s pos=%v size=%v scale=%v min=%v" % [ct.get_class(), ct.position, ct.size, ct.scale, ct.custom_minimum_size])

static func build(ctx: Ctx) -> Control:
	var board: Array = ctx.snapshot.get("board", [])
	# The carved placard is the board's title now — hide the plain text header.
	ctx.title.visible = false
	# One canvas the wood frame wraps; notices are placed on it absolutely.
	var inner := inner_size(ctx.viewport)
	var canvas := Control.new()
	canvas.custom_minimum_size = inner
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Text renders crisp: the popup panel is LINEAR (soft painted frame), but the notice
	# layer resets to NEAREST so labels stay sharp. Raster nodes (paper/backing/crest)
	# re-assert LINEAR on themselves, so only the fonts change.
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ctx.body.add_child(canvas)
	# Plank backing fills behind the notices (Batch 1). Backmost layer; the carved
	# frame is the popup panel skin, the stone surround shows around it.
	if _backing_tex != null:
		var backing := NinePatchRect.new()
		backing.texture = _backing_tex
		backing.set_anchors_preset(Control.PRESET_FULL_RECT)
		backing.patch_margin_left = 12
		backing.patch_margin_top = 12
		backing.patch_margin_right = 12
		backing.patch_margin_bottom = 12
		backing.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # painterly raster, keep it soft
		backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Torch-lit via the surface shader (TD-047): the dark backing_v1 is pre-lifted in-shader
		# (diffuse_gain) then lit by the torch rig — tests that a fragment shader preserves the
		# NinePatch 9-slice AND takes the dynamic light (the frame conversion depends on this).
		backing.material = BoardDecor.surface_material(ctx.viewport, "res://assets/ui/board/backing_v1_n.png", 0.56, 1.25)  # TD-050: plank grain reads at rest, still below the parchment/frame key
		backing.modulate = Color(1.0, 1.0, 1.0)
		# z_index MUST stay >= 0: at -2 the plank drew BEHIND the popup's opaque panel
		# background and vanished, so the dark stone wall showed through ("see-through board").
		# Tree order (added before the notices) already keeps it behind the cards.
		backing.z_index = 0
		canvas.add_child(backing)
		# Age + use: a tiling grain/speckle overlay so the planks read weathered, not a flat
		# stretched slab (dark specks + faint lengthwise streaks, low alpha). Above the backing,
		# below the notices. Runtime texture, no import.
		var grain := TextureRect.new()
		grain.texture = BoardGeo.wood_grain_texture()
		grain.set_anchors_preset(Control.PRESET_FULL_RECT)
		grain.stretch_mode = TextureRect.STRETCH_TILE
		grain.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		grain.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		grain.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grain.z_index = 0
		canvas.add_child(grain)
	# Flanking torches now hang on the STONE WALL beside the inset board (Prototype v1),
	# not inside the frame — banner + sconce + additive glow at each flank of the masonry
	# margin. Rendered on the stone layer in viewport space. Reduced-motion (F9) freezes it.
	# TD-059: the banner is now a normal-mapped surface lit by the SAME torch rig as the wall —
	# built here so the rig-uniform packing stays in `BoardDecor.surface_material` (P72/P102), passed in.
	var banner_mat := BoardDecor.surface_material(ctx.viewport, "res://assets/ui/board/banner_v1_n.png", 0.36, 1.05, Vector2.ONE, 2.4)
	BoardDecor.add_torches(ctx.stone, ctx.viewport, ctx.reduced_motion, banner_mat)
	# The papers live in their own layer beneath the placard and the reader. A hovered
	# notice raises to front WITHIN this layer only, so dense overlap never lets a
	# paper float above the hanging sign (or over an open reading).
	var notes := Control.new()
	notes.set_anchors_preset(Control.PRESET_FULL_RECT)
	notes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(notes)
	# Flavor scraps now read as a few small notes pinned in the side margins (as in the
	# reference), not a scatter across the wall — the grid of live writs owns the centre.
	# A light tilt keeps them from looking machine-placed; they draw behind the grid.
	# Prototype v1 is a clean framed grid — no side scraps intruding over the writs.
	# Flavor notices are opt-in (`--flavor`) until they get their own uncluttered band.
	var flavor_n := mini(BoardGeo.FLAVOR_SIDE_SLOTS.size(), FLAVOR_NOTICES.size()) if OS.get_cmdline_user_args().has("--flavor") else 0
	for i in flavor_n:
		var fslot: Vector2 = BoardGeo.FLAVOR_SIDE_SLOTS[i] + BoardGeo.seed_jitter("flavor-%d" % i) * 0.4
		var fsz := BoardGeo.notice_size(BoardGeo.FLAVOR_SIZE_FRACS, i, inner)
		var fnode := NoticeCard.flavor(FLAVOR_NOTICES[i], i)
		_place(notes, inner, fnode, fslot, fsz, BoardGeo.seed_tilt("flavor-%d" % i) * 0.6)
		if OS.is_debug_build():
			ctx.logger.call("  flavor[%d] want=%v got=%v pos=%v" % [i, fsz, fnode.size, fnode.position])
	# Live notices are laid out by the keep-out solver first (T145), so no petition can
	# ever bury another, then placed at the resolved rects. Flavor stays behind them.
	var placed := BoardGeo.layout_live(board, inner)
	var footprints: Array = []
	var min_hit := Vector2(INF, INF)   # smallest live hit-target, self-checked ≥ HIT_MIN (T145)
	for idx in placed.size():
		var intel: Dictionary = board[idx]
		var cid := str(intel.get("contractId", ""))
		# TD-061 (R192): the grid cell is the disjoint CEILING, not the writ. Each writ takes
		# its own content-fitted, seeded size inside the cell — non-uniform on purpose ("the
		# variability and uniqueness of each contract"), and long site names always fit.
		var fit := NoticeCard.fit(intel, placed[idx]["size"])
		var size: Vector2 = fit["size"]
		var centre: Vector2 = placed[idx]["centre"]
		# A subtle hand-pinned lean (±~2.7°) so the writs read as tacked paper, not a printed
		# grid — small enough that the keep-out solver's cell gaps stay disjoint (self-checked).
		var tilt := BoardGeo.seed_tilt(cid) * 0.42
		# The whole live stack rides ABOVE the wall vignette (z 2): the vignette shapes the
		# corners of the WALL, never the writs (its own stated intent), so a live paper never
		# sinks below the legibility floor no matter where on the board it lands (T145 / L1, L3).
		var hit_size := Vector2(maxf(size.x, NoticeCard.HIT_MIN.x), maxf(size.y, NoticeCard.HIT_MIN.y))
		min_hit = Vector2(minf(min_hit.x, hit_size.x), minf(min_hit.y, hit_size.y))
		var pos := (centre - size * 0.5).floor()
		# Per-notice backlight: a warm amber pool behind the writ (additive), so the paper owns
		# its own light and reads even with the torches frozen or in a dim gutter (L3). Larger
		# than the paper so it haloes the wood around the sheet.
		var glow := TextureRect.new()
		glow.texture = BoardGeo.backlight_gradient()
		glow.material = BoardGeo.additive_material()
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.stretch_mode = TextureRect.STRETCH_SCALE
		glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var gsz := size * 1.55
		glow.size = gsz
		glow.position = (centre - gsz * 0.5).floor()
		glow.z_index = LIVE_Z
		notes.add_child(glow)
		# Cast shadow: the paper's own silhouette in translucent black, offset down-right (the
		# board's ONE light), so each notice sits proud of the wood instead of printed on it.
		var shadow := TextureRect.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.stretch_mode = TextureRect.STRETCH_SCALE
		shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var parch := NoticeCard.parch_live()
		if not parch.is_empty():
			shadow.texture = parch[idx % parch.size()]
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.33)
		shadow.size = size
		shadow.pivot_offset = size * 0.5
		shadow.rotation_degrees = tilt
		shadow.position = pos + Vector2(3.0, 5.0)
		shadow.z_index = LIVE_Z
		notes.add_child(shadow)
		var node := NoticeCard.live(intel, idx, ctx.selection, ctx.on_select, fit["tfs"], fit["sfs"])
		node.custom_minimum_size = hit_size
		node.size = size
		node.pivot_offset = size * 0.5
		node.rotation_degrees = tilt
		node.set_meta("tilt", tilt)        # so open/close can restore the lean without a rebuild (P123)
		node.position = pos
		node.z_index = LIVE_Z
		node.add_to_group("live_notice")   # keyboard entry point (T146 / L6): first-in-order gets focus
		notes.add_child(node)
		footprints.append(Rect2(centre - BoardGeo.rotated_extent(size, tilt) * 0.5, BoardGeo.rotated_extent(size, tilt)))
	var live := placed.size()
	# Self-check for the playtest (T145): no live petition may bury another (rotation included),
	# and every live hit-target clears the 44x44 minimum.
	var hit_ok := live == 0 or (min_hit.x >= NoticeCard.HIT_MIN.x and min_hit.y >= NoticeCard.HIT_MIN.y)
	ctx.logger.call("keepout live=%d ok=%s minhit=%dx%d hit_ok=%s" % [live, live > 0 and BoardGeo.all_disjoint(footprints, 0.0), int(min_hit.x) if live > 0 else 0, int(min_hit.y) if live > 0 else 0, hit_ok])
	if OS.is_debug_build():
		ctx.logger.call("keepout inner=%v bounds=%s" % [inner, BoardGeo.live_bounds(inner)])
		for i in footprints.size():
			ctx.logger.call("  live[%d] fp=%s" % [i, footprints[i]])
	# Empty board (L8): no live petitions → a solemn scrap over the bare wall, never a
	# blank popup. (T146 refines the styling; this is the honest empty state.)
	if live == 0:
		# A solemn empty state (T146 / L8), never a blank popup. Two-line: a title read + a
		# quieter subtitle, above the vignette (z LIVE_Z) so the wall's shadow never swallows it.
		var ebox := VBoxContainer.new()
		ebox.alignment = BoxContainer.ALIGNMENT_CENTER
		ebox.add_theme_constant_override("separation", 4)
		ebox.custom_minimum_size = Vector2(360, 60)
		ebox.size = Vector2(360, 60)
		ebox.position = Vector2((inner.x - 360.0) * 0.5, inner.y * 0.5 - 30.0).floor()
		ebox.z_index = LIVE_Z
		ebox.add_child(Widgets.card_label("The wall stands empty.", 17, Color(0.86, 0.78, 0.58), true, true))
		ebox.add_child(Widgets.card_label("No petitions stand before the Collegium.", 12, Color(0.66, 0.58, 0.44), true, true))
		canvas.add_child(ebox)
	if OS.is_debug_build():
		_dump_notes.bind(ctx, notes).call_deferred()
	if OS.get_cmdline_user_args().has("--board-debug"):
		for fp in footprints:
			var mark := Panel.new()
			var sb2 := StyleBoxFlat.new()
			sb2.bg_color = Color(0, 0, 0, 0)
			sb2.border_color = Color(1, 0, 0)
			sb2.set_border_width_all(1)
			mark.add_theme_stylebox_override("panel", sb2)
			mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
			mark.position = (fp as Rect2).position
			mark.size = (fp as Rect2).size
			mark.z_index = 20
			canvas.add_child(mark)
	# Sacred-decay ambiance (cobweb + votive), tucked into corners proven empty of any
	# live petition so it never occludes a headline (DESIGN — decay is clutter, not cover).
	_add_decay(canvas, inner, footprints)
	# Warm-dark vignette over the whole wall: a lit pool at the centre falling to
	# near-black at the corners (Prototype-v1 ambience). A runtime radial gradient (no
	# PNG import); above the papers so their edges sink into shadow, below placard/reader.
	var vig := TextureRect.new()
	vig.texture = BoardGeo.vignette_gradient()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vig.z_index = 2
	canvas.add_child(vig)
	# The legend / active-assignment bar along the bottom (Prototype v1).
	_add_board_bar(ctx, canvas, inner)
	# The carved sign hangs over the top of the board, above the papers (own layer).
	BoardHeader.place(canvas, inner, ctx.viewport)
	# The heraldic crest is drawn as a popup-tracking OVERLAY (created in _init, synced in
	# _process) so it can crown over the top edge — not clipped by the ScrollContainer.
	ctx.logger.call("board live=%d flavor=%d" % [live, flavor_n])
	# If a notice has been taken down, lay it on the reader over the dimmed board.
	if not ctx.selection.is_empty():
		ctx.show_reader.call(canvas, ctx.selection)
	elif live > 0:
		# Grid view: seed keyboard focus so Tab walks the writs and the corner reticle shows
		# from the first frame (T146 / L6). Restores the prior writ across a rebuild.
		focus_first.bind(ctx.host).call_deferred()
	return canvas

# The board's inner area (inside the wood frame): the popup scroll region, minus a
# little breathing room. Absolute notice placement is normalised to this.
#
# The floor must never exceed the viewport, or the canvas grows past the frame and the
# notices hang off the wall. At the 640x360 base (TD-042) the old 640x320 floor was
# larger than the popup's own scroll region (568x232) — the board spilled its edges.
static func inner_size(vp: Vector2) -> Vector2:
	# Thin wrapper over BoardGeo (many call sites need it against the live viewport).
	return BoardGeo.inner_size(vp)

# Place a notice on the canvas: top-left from a normalised centre, rotated about
# its own centre so it hangs at a human angle.
static func _place(canvas: Control, inner: Vector2, node: Control, center_norm: Vector2, size: Vector2, tilt: float) -> void:
	node.custom_minimum_size = size
	node.size = size
	node.pivot_offset = size * 0.5
	node.rotation_degrees = tilt
	# Keep the paper (plus a little rotation slack) inside the wooden frame even when
	# a big size lands under a jittered edge slot.
	# Reserve the top band for the hanging placard so papers sit below the sign
	# (matching the reference) rather than jamming up behind it. Fractions, not pixels:
	# 72px was a fifth of the whole board once the base became 640x360 (TD-042).
	var top_reserve := inner.y * BoardGeo.TOP_RESERVE_FRAC
	var pos := inner * center_norm - size * 0.5
	pos.x = clampf(pos.x, 8.0, maxf(8.0, inner.x - size.x - 8.0))
	pos.y = clampf(pos.y, top_reserve, maxf(top_reserve, inner.y - size.y - 8.0))
	node.position = pos.floor()
	canvas.add_child(node)

# ── Keep-out (T145) ──────────────────────────────────────────────────────────
# A live petition must always be readable: no live notice may bury another. Flavor
# scraps are drawn behind and may tuck under freely — clutter, never occlusion.
#
# Deterministic: same seed -> same board. Pure geometry over Rect2s, resolved before
# any node is added, then self-checked and logged for the playtest (`keepout ... ok=`).

# The requester's signature line for a notice foot (trait-free intel): "— <name>,
# <role>" or "— an unnamed <role>" for an anonymous petitioner. Diegetic fill only.
static func _notice_sig(req: Variant) -> String:
	if typeof(req) != TYPE_DICTIONARY:
		return ""
	var nm := str((req as Dictionary).get("name", ""))
	var role := str((req as Dictionary).get("role", "petitioner"))
	# Kept short so it stays one line on the card foot; the full "name, role of place"
	# is shown in the reader. Anonymous petitioners read as "— an unnamed <role>".
	if nm == "":
		return "— an unnamed %s" % role
	return "— %s" % nm

# A rect is "clear" when no live footprint intersects it — decay may only sit in space
# no petition claims (keep-out heritage; DESIGN binds cobweb/votive to empty corners).
# Sacred-decay props: one cobweb in a clear top corner (grayscale-additive, tinted cold
# and dim like the glow) + a dead votive at a clear base corner. Both inert, behind the
# papers, and skipped entirely if their corner is occupied — clutter, never occlusion.
static func _add_decay(canvas: Control, inner: Vector2, footprints: Array) -> void:
	if _cobweb_tex != null:
		var wsz := 40.0
		# prefer the top-left corner; if a petition claims it, mirror into the top-right.
		for spec in [[Vector2(3, 3), 1.0], [Vector2(inner.x - wsz - 3, 3), -1.0]]:
			var pos: Vector2 = spec[0]
			var flip: float = spec[1]
			if BoardGeo.decay_clear(Rect2(pos, Vector2(wsz, wsz)), footprints):
				var web := TextureRect.new()
				web.texture = _cobweb_tex
				web.mouse_filter = Control.MOUSE_FILTER_IGNORE
				web.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				web.material = BoardGeo.additive_material()
				web.modulate = Color(0.62, 0.66, 0.72, 0.34)  # cold, dim (tinted VFX) — TD-050: a whisper, not a focal detail
				web.position = pos
				if flip < 0.0:                                  # mirror for the right corner
					web.scale.x = -1.0
					web.position.x = pos.x + wsz
				web.z_index = -1
				canvas.add_child(web)
				break
	if _votive_tex != null:
		var vsz := Vector2(14, 22)
		for pos in [Vector2(6, inner.y - vsz.y - 4), Vector2(inner.x - vsz.x - 6, inner.y - vsz.y - 4)]:
			if BoardGeo.decay_clear(Rect2(pos, vsz), footprints):
				var vot := TextureRect.new()
				vot.texture = _votive_tex
				vot.mouse_filter = Control.MOUSE_FILTER_IGNORE
				vot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				vot.position = pos
				vot.z_index = -1
				canvas.add_child(vot)
				break

# The bottom-of-screen keybind strip (Prototype v1): one row of key-chips + captions,
# centred just above the bottom edge. Built once; shown for the Contract Board only.
static func keyhint() -> Control:
	var bar := PanelContainer.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.visible = false
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	# Grow UPWARD from the bottom edge — the Control default (GROW_BOTH) would put half the
	# strip below y=vp.y (off-screen), leaving only a sliver visible. z above the frame.
	bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	bar.z_index = 6
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.05, 0.03, 0.96)
	sb.border_color = Color(0.46, 0.33, 0.15)
	sb.border_width_top = 2
	sb.content_margin_top = 7; sb.content_margin_bottom = 7
	sb.content_margin_left = 14; sb.content_margin_right = 14
	bar.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	bar.add_child(row)
	for pair in [["Tab", "Navigate"], ["Enter", "Take down"], ["Click", "View Contract"], ["Esc", "Back"]]:
		var cell := HBoxContainer.new()
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_constant_override("separation", 8)
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color(0.14, 0.11, 0.07)
		csb.border_color = Color(0.44, 0.32, 0.15)
		csb.set_border_width_all(1)
		csb.set_corner_radius_all(3)
		csb.content_margin_left = 7; csb.content_margin_right = 7
		csb.content_margin_top = 1; csb.content_margin_bottom = 1
		chip.add_theme_stylebox_override("panel", csb)
		chip.add_child(Widgets.card_label(pair[0], 8, Color(0.90, 0.80, 0.52), false, true))
		cell.add_child(chip)
		cell.add_child(Widgets.card_label(pair[1], 8, Color(0.74, 0.66, 0.50), false, false))
		row.add_child(cell)
	return bar

static func _add_board_bar(ctx: Ctx, canvas: Control, inner: Vector2) -> void:
	# Delegated to the BoardBar module (render-only). Main supplies the authoritative
	# contract + the pre-formatted requester signature; positioning stays here (needs inner/z).
	var contract: Variant = ctx.snapshot.get("contract", null)
	var sig := _notice_sig((contract as Dictionary).get("requester", {})) if contract != null else ""
	var row := BoardBar.build(inner, contract, sig)
	var barh := BoardGeo.bar_height(inner)
	row.position = Vector2(floorf(inner.x * 0.02), floorf(inner.y - barh - 6.0))
	row.z_index = 4
	canvas.add_child(row)

# Leave the surviving writs exactly as a rebuild would have: seeded lean, rest scale. A card is
# hover-scaled (1.05) at the moment it is clicked, and the old rebuild discarded that node — so
# without this the clicked writ would stay swollen behind the dim. Selection itself has no
# board-level look: `NoticeCard.live`'s "taken-down hangs straight" is overwritten by the
# placement `rotation_degrees = tilt` below it, and the 1.03 rest can't fire while the dim owns
# the mouse. Reproducing the rebuild's result is the contract here, not improving on it (P123).
static func reset_transforms(host: Node) -> void:
	for n in host.get_tree().get_nodes_in_group("live_notice"):
		var card := n as Control
		if card == null or not is_instance_valid(card):
			continue
		NoticeCard.kill_hover_tween(card)
		card.rotation_degrees = float(card.get_meta("tilt", 0.0))
		card.scale = Vector2.ONE

# Give keyboard nav a starting point on the board (T146 / L6): restore the writ that held
# focus before a rebuild (by contractId), else focus the reading-first (top-left) writ, so
# Tab immediately walks the grid and the corner reticle shows. (Groups aren't ordered, so
# reading order is derived geometrically: top row, then left-most.)
static func focus_first(host: Node) -> void:
	var cards := host.get_tree().get_nodes_in_group("live_notice")
	cards.sort_custom(func(a: Control, b: Control) -> bool:
		if absf(a.position.y - b.position.y) > 8.0:
			return a.position.y < b.position.y
		return a.position.x < b.position.x)
	if cards.is_empty():
		return
	var want := NoticeCard.focus_cid()
	if want != "":
		for c in cards:
			if c is Control and str((c as Control).get_meta("cid", "")) == want:
				(c as Control).grab_focus()
				return
	(cards[0] as Control).grab_focus()