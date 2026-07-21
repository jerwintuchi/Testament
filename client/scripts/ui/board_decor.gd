extends RefCounted
## Contract Board — ambient decor (extracted from main.gd for organization).
##
## The flanking wall torches (banner + additive glow + animated flame + iron sconce) and
## the Collegium crest medallion. All render-only node factories: pass the stone-wall layer
## + viewport size + reduced-motion flag; no other scene state is touched. Consumed via
## preload as `BoardDecor` (TD-029/30 convention). Grayscale-additive VFX tinted at runtime.

const BoardGeo = preload("res://scripts/ui/board_geometry.gd")

# Banner-centre x (screen fraction) per flank — BANNER PLACEMENT ONLY.
# TD-059b/c: pushed OUTWARD toward the outer edge of the masonry gutter so the larger banner clears
# the board frame — the gutter (screen edge → carved frame ≈ 0.09·vp) is NARROWER than the banner, so
# a centred banner's inner edge overlapped the board. Pinning the INNER edge clear of the frame while
# growing the banner walks the centre further out (to 0.028): larger banner, outer edge spilling
# off-screen (author OK'd), inner edge keeping its gap to the board.
const GUTTER_CX := [0.028, 0.972]

# Torch/light-rig centre x (screen fraction) per flank — the SCONCE, FLAME, and the ONE
# `board_surface.gdshader` light rig read THIS, kept INBOARD of the banner (between banner and frame)
# so the flame sits beside the board and actually lights the carved frame edge. TD-059e DECOUPLED this
# from GUTTER_CX: when the banner moved to the outer gutter for placement, a shared position dragged
# the flame out with it (~74px off the frame), so the frame read as lit from a disconnected mid-side
# glow instead of from the flame. Restoring the torch inboard (the standing "torch inboard of the
# banner" intent) puts the light back beside the frame. The sconce + flame + rig never desync — they
# all read TORCH_CX (P95, re-homed from GUTTER_CX to this).
const TORCH_CX := [0.072, 0.928]

# The ONE torch light rig (R133/P72): two flames on the gutter pillars. Every consumer —
# the visual torch placement here AND the surround's `board_surface.gdshader` uniforms in
# main — reads this, so the light never desyncs. Positions are in SCREEN_UV space (0..1).
static func torch_rig(vp: Vector2) -> Array:
	var col := Color(1.0, 0.72, 0.42)          # warm ember cast
	var out: Array = []
	for at_right in [false, true]:
		var cx: float = vp.x * TORCH_CX[1 if at_right else 0]
		var cup_y := vp.y * 0.71               # sconce cup (banner foot), matches add_torches
		var ly := cup_y - 12.0                 # flame centre
		# Tight cup halo (TD-048 dungeon re-grade): the flame lifts only its immediate surround,
		# casting near-zero across the board (was 0.74, a board-climbing pool — the show-stealer).
		out.append({"uv": Vector2(cx / vp.x, ly / vp.y), "color": col, "radius": 0.24})
	return out

# Flanking wall torches, drawn on the stone-wall layer (behind the centred board) in
# VIEWPORT space so the banners hang on the masonry beside the inset board (Prototype v1).
# Clears and rebuilds `stone_bg`'s children each call. Reduced motion pins the glow to peak.
static func add_torches(stone_bg: Node, vp: Vector2, reduced_motion: bool, banner_mat: ShaderMaterial = null) -> void:
	if stone_bg == null:
		return
	for c in stone_bg.get_children():
		c.queue_free()
	var ember := Color(0.909, 0.592, 0.235)   # flame ember  #E8973C
	var glowc := Color(0.941, 0.698, 0.372)   # flame glow   #F0B25F
	# Prototype-v1 read: the crimson banner hangs at the OUTER edge of the masonry gutter,
	# and the lit torch sits INBOARD of it (between banner and frame) — two separate fixtures,
	# never stacked (that stacking lit the cloth orange + smeared the frame edge).
	for at_right in [false, true]:
		var banner_cx: float = vp.x * GUTTER_CX[1 if at_right else 0]   # gutter centre (midpoint of the stone flank)
		var btex_w := 64.0
		var btex_h := 176.0
		var banner_top := vp.y * 0.06         # TD-059c: lowered so the banner top no longer lines up with the board's top edge
		# TD-059c: LARGER banner (0.095·vp.x) hung at the outer gutter (GUTTER_CX=0.028). Its INNER
		# edge (center 0.028 + half 0.0475 ≈ 0.075·vp) still clears the carved board frame (~0.09·vp)
		# with a gap while the emblem (centred, 0.60·W) stays on-screen; the outer edge spills further
		# off-screen (viewport clips — author OK'd). Height budget lifted to 0.60·vp.y so the taller,
		# lowered banner still ends its foot above the sconce cup (vp.y*0.71) with a clear gap.
		var bs := minf(vp.x * 0.095 / btex_w, (vp.y * 0.60 - banner_top) / btex_h)
		var target_h := btex_h * bs
		var banner_pos := Vector2(banner_cx, banner_top + target_h * 0.5)
		# Contact shadow: the banner cast onto the masonry, offset down-right (the board's ONE
		# light convention), so the cloth reads as hung proud of the wall, not painted on it.
		var bshadow := Sprite2D.new()
		bshadow.texture = load("res://assets/ui/banner_v1.png") as Texture2D
		bshadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bshadow.scale = Vector2(bs, bs)
		bshadow.centered = true
		bshadow.position = banner_pos + Vector2(3.0, 4.0)
		bshadow.modulate = Color(0.0, 0.0, 0.0, 0.32)
		bshadow.z_index = -1
		stone_bg.add_child(bshadow)
		# Dim, heavily-tattered crimson standard (TD-059/gen_banner.py). It is now a NORMAL-MAPPED
		# surface LIT BY THE TORCH RIG via board_surface.gdshader (banner_mat) — warm where the foot
		# sconce reaches, dark up top — not a flat baked sprite. Brightness comes from the shader, so
		# modulate is white; NEAREST for crisp pixels. Falls back to a dim baked read if unlit.
		var banner := Sprite2D.new()
		banner.texture = load("res://assets/ui/banner_v1.png") as Texture2D
		banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		banner.scale = Vector2(bs, bs)
		banner.centered = true
		banner.position = banner_pos
		if banner_mat != null:
			banner.material = banner_mat
			banner.modulate = Color(1.0, 1.0, 1.0)   # brightness from the shader (as _stone_bg)
		else:
			banner.modulate = Color(0.82, 0.80, 0.80)   # unlit fallback: a touch dimmed
		banner.z_index = 0
		stone_bg.add_child(banner)
		# (TD-052 R166) The separate iron rod + nail-head Panels are RETIRED — the banner's top hem
		# (pole sleeve) is baked into gen_banner.py's cloth, so it hangs as a fixed standard with no
		# floating hardware.
		# The torch is mounted at the FOOT of the banner, directly beneath it (Prototype-v1
		# read): an iron sconce whose top cup holds the flame. `cup_y` is where the flame base
		# meets the sconce's top bar; the sconce stem hangs below, the flame rises above.
		var banner_bottom := banner_top + target_h
		# TD-059e: the torch sits at TORCH_CX (inboard, beside the frame), NOT under the banner —
		# so its flame actually lights the carved frame edge (matching torch_rig, which now reads
		# TORCH_CX). The banner hangs outboard at GUTTER_CX; the flame is in the gap between them.
		var torch_x: float = vp.x * TORCH_CX[1 if at_right else 0]
		# The sconce stays at its own height (vp.y*0.71, matching torch_rig's light), a clear gap
		# below the banner hem (banner_bottom) so cloth + fixture read as two things.
		var cup_y := vp.y * 0.71
		# The broad GUTTER WASH (a board-wide additive pool @ ~3.4x) is DROPPED in the dungeon
		# re-grade (TD-048): it was the orange bloom that washed out the mood and stole the show.
		# The fire now casts near-zero across the board — only the tight cup glow below remains.
		# Iron sconce (T-bracket): its top bar is the cup. Centered sprite (12x20 @1.4 -> 28h),
		# so top ≈ position.y-14; place position.y = cup_y+12 to seat the cup bar around cup_y.
		var sconce := Sprite2D.new()
		sconce.texture = load("res://assets/ui/torch_sconce.png") as Texture2D
		sconce.scale = Vector2(1.4, 1.4)
		sconce.position = Vector2(torch_x, cup_y + 12.0)
		sconce.z_index = 3
		stone_bg.add_child(sconce)
		# Glow: a SMALL, DIM additive halo hugging the flame (TD-048 dungeon re-grade — was a
		# 1.35x candle-pool at a=0.52; now a tight cup halo with near-zero throw onto the board).
		var glow := Sprite2D.new()
		glow.texture = load("res://assets/ui/torch_glow.png") as Texture2D
		glow.scale = Vector2(0.7, 0.78)
		glow.position = Vector2(torch_x, cup_y - 8.0)
		glow.material = BoardGeo.additive_material()
		glow.modulate = Color(glowc.r, glowc.g, glowc.b, 0.32 if reduced_motion else 0.28)
		glow.z_index = 3
		stone_bg.add_child(glow)
		if not reduced_motion:
			var t := glow.create_tween().set_loops()
			t.tween_property(glow, "modulate:a", 0.34, 1.8).set_trans(Tween.TRANS_SINE)
			t.tween_property(glow, "modulate:a", 0.22, 1.8).set_trans(Tween.TRANS_SINE)
		# Flame seated at the sconce cup: `torch_flame` emits from this BASE point and rises.
		# The bowl rim sits ~2px below the sprite top, so seat the base just inside the cup.
		stone_bg.add_child(torch_flame(Vector2(torch_x, cup_y - 2.0), ember, reduced_motion))
		# NOTE (TD-047): the surfaces are lit by `board_surface.gdshader` reading `torch_rig`,
		# NOT by a Light2D — verified that a PointLight2D does not reach these Control nodes
		# (cranked to energy 8 = zero change). The small additive glow sprite above is the flame's
		# own dim bloom; the wall/backing/frame relief comes from the shader (dungeon-dark, TD-048).

# The sconce flame (T153) — a CPUParticles2D that rises + tapers from the cup, running an
# ember→smoke ramp with additive blend and per-particle velocity/scale/lifetime variance +
# a randomised tangential accel, so it FLICKERS organically with no visible loop period.
# `base` is the cup lip (emission origin); particles rise above it. Kept small so its cast
# stays near-zero (TD-048 dungeon re-grade) — the fire is alive, not the show. Reduced
# motion returns a STATIC frame-0 flame instead (deterministic, capture-stable); the
# sympathetic glow is pinned to peak by the caller (add_torches).
static func torch_flame(base: Vector2, ember: Color, reduced_motion: bool) -> Node2D:
	if reduced_motion:
		return _static_flame(base, ember)
	var fire := CPUParticles2D.new()
	fire.position = base
	fire.z_index = 4                       # a wall fixture; the paper hangs in front
	fire.texture = load("res://assets/ui/spark.png") as Texture2D
	fire.material = BoardGeo.additive_material()
	fire.local_coords = false              # particles trail in world space as the flame licks
	fire.amount = 20
	fire.lifetime = 0.52
	fire.lifetime_randomness = 0.4
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fire.emission_rect_extents = Vector2(2.4, 1.2)   # bowl-width base
	fire.direction = Vector2(0, -1)
	fire.spread = 12.0
	fire.gravity = Vector2(0, -60.0)       # buoyant rise
	fire.initial_velocity_min = 16.0
	fire.initial_velocity_max = 34.0
	fire.damping_min = 8.0
	fire.damping_max = 22.0
	fire.tangential_accel_min = -18.0      # side-to-side lick → flicker
	fire.tangential_accel_max = 18.0
	fire.scale_amount_min = 0.55
	fire.scale_amount_max = 1.15
	fire.scale_amount_curve = _flame_scale_curve()
	fire.color_ramp = _flame_ramp()
	return fire

# Grow-then-shrink over particle life: a small spark at birth, fattening as it leaves the
# cup, pinching out as it cools near the top.
static func _flame_scale_curve() -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, 0.35))
	c.add_point(Vector2(0.28, 1.0))
	c.add_point(Vector2(1.0, 0.1))
	return c

# Ember→smoke: pale-warm core at the base, ember mid, dark ember, fading transparent (with
# additive blend the fade contributes nothing, so the flame tip dissolves cleanly).
static func _flame_ramp() -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.35, 0.7, 1.0])
	g.colors = PackedColorArray([
		Color(1.0, 0.85, 0.52, 0.85),
		Color(0.95, 0.58, 0.22, 0.75),
		Color(0.5, 0.16, 0.06, 0.30),
		Color(0.05, 0.05, 0.05, 0.0),
	])
	return g

# Reduced-motion fallback: the retired 4-frame sheet, frozen on frame 0, seated so its base
# sits at the cup lip (`base`). Additive, ember-tinted, matching the live flame's footprint.
static func _static_flame(base: Vector2, ember: Color) -> Sprite2D:
	var spr := Sprite2D.new()
	var sheet := load("res://assets/ui/torch_flame.png") as Texture2D
	if sheet != null:
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(0, 0, 16, 24)
		spr.texture = at
	spr.scale = Vector2(1.2, 1.2)
	spr.position = base + Vector2(0, -14.4)   # centre up so the 28.8px-tall flame's base = cup
	spr.material = BoardGeo.additive_material()
	spr.modulate = ember
	spr.z_index = 4
	return spr

# A soft radial light-falloff (white centre -> transparent edge) for the torch PointLight2D.
# Runtime GradientTexture2D, no PNG import.
static func light_falloff() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0.0)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 128
	gt.height = 128
	return gt
