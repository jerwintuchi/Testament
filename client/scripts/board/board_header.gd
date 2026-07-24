## The Contract Board's hanging sign: the carved walnut plaque with its forged iron straps,
## bronze bolts and engraved two-line title, plus its placement at the top of the wall.
## Extracted verbatim from main.gd under TD-067 T231.
##
## A preloaded RefCounted namespace (S3.2/S3.4) — pure render, inert to input, no state.
## `ContractBoard` hangs it; it knows nothing of the wall it hangs on.
extends RefCounted

const BoardGeo = preload("res://scripts/board/board_geometry.gd")
const BoardDecor = preload("res://scripts/board/board_decor.gd")
const Widgets = preload("res://scripts/ui/widgets.gd")


# Hang the sign at the header's rect, in inner-canvas space. Fractional (TD-042), so it
# survives a resize.
static func place(canvas: Control, inner: Vector2, vp: Vector2) -> void:
	var pr := BoardGeo.placard_rect(inner)
	var placard := _sign(vp)
	placard.custom_minimum_size = pr.size
	placard.size = pr.size
	placard.position = pr.position.floor()
	# z_index wins over tree order absolutely, so a hovered paper (which raises to the
	# front of its own layer) can never draw over the hanging sign.
	placard.z_index = 5
	canvas.add_child(placard)

# The Contract Board's header (TD-053; TD-058): a carved walnut sign, reinforced with forged
# iron straps + bronze bolts, hung at the very top of the board and carrying an engraved two-line
# title. The institution ("THE COLLEGIUM") outranks the thing ("Contract Board"). TD-058 dropped
# the crowning bronze medallion (a repeated pain point at its 17x22 device slot — see TD-054/056/
# 057) and reclaimed its height for the contracts: the sign is now the whole header, hung flush at
# the top, with nothing floating above it. Pure render; inert to input.
static func _sign(vp: Vector2) -> Control:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# No medallion (TD-058): the sign hangs flush at the top of the header rect, so the full rect
	# is the sign itself. (Header height is zero-sum against the writs: live_bounds.h = 184.24 -
	# placard_h, split across two rows — dropping the seat gave the contracts ~27px back.)
	var sign_top := 0.0
	var ptex := load("res://assets/ui/board/board_header.png") as Texture2D
	if ptex != null:
		# Authored at its exact on-screen size (204x38 — the internal resolution is a fixed
		# 640x360, so placard_rect is deterministic), hence NEAREST + 1:1, no downscale mush
		# (TD-050). The 9-slice only matters off-base: it keeps the end straps un-smeared and
		# the grain runs horizontally, so the centre stretches cleanly.
		# The contact shadow is drawn here, not baked, so it holds at any stretched width.
		var shadow := NinePatchRect.new()
		shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
		shadow.offset_top = sign_top + 3.0
		shadow.offset_left = 2.0
		shadow.offset_right = 3.0
		shadow.offset_bottom = 4.0
		shadow.texture = ptex
		shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.55)
		_patch(shadow)
		root.add_child(shadow)
		var sign := NinePatchRect.new()
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sign.set_anchors_preset(Control.PRESET_FULL_RECT)
		sign.offset_top = sign_top
		sign.texture = ptex
		sign.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		# TD-059d: light the sign through the SAME board_surface.gdshader as the wall/frame/banner so
		# it belongs to the scene instead of reading as a flat, self-lit plaque on a torch-lit wall.
		# The header sits at the top centre, far from the corner sconces, so it takes the scene's cool
		# ambient (its carved relief in board_header_n) with only a whisper of torch reach — which is
		# exactly the cool-dark the top of the frame beside it already sits in. The gilt title is a
		# separate Godot Label drawn over this, so legibility is unaffected by how dim the wood goes.
		sign.material = BoardDecor.surface_material(vp, "res://assets/ui/board/board_header_n.png", 0.86, 1.0, Vector2.ONE, 1.6)
		_patch(sign)
		root.add_child(sign)
	else:
		var plaque := Panel.new()
		plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		plaque.set_anchors_preset(Control.PRESET_FULL_RECT)
		plaque.offset_top = sign_top
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color(0.20, 0.15, 0.11)
		psb.set_border_width_all(2)
		psb.border_color = Color(0.09, 0.06, 0.04)
		plaque.add_theme_stylebox_override("panel", psb)
		root.add_child(plaque)
	# The engraved title, centred in the sign's plank field between the top and bottom rails.
	var stack := VBoxContainer.new()
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.offset_top = sign_top + 4.0
	stack.offset_bottom = -5.0
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 0)
	root.add_child(stack)
	stack.add_child(Widgets.engraved_line("THE COLLEGIUM", 13, Color(0.86, 0.72, 0.42), 700))
	stack.add_child(_gap(1))
	stack.add_child(Widgets.engraved_line("Contract Board", 8, Color(0.62, 0.50, 0.31), 400))
	return root

# The sign's 9-slice margins (source 204x38, end straps inside 36/11).
static func _patch(np: NinePatchRect) -> void:
	np.patch_margin_left = 36
	np.patch_margin_top = 11
	np.patch_margin_right = 36
	np.patch_margin_bottom = 11

static func _gap(h: int) -> Control:
	var g := Control.new()
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.custom_minimum_size = Vector2(0, h)
	return g