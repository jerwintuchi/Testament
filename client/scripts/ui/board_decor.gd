extends RefCounted
## Contract Board — ambient decor (extracted from main.gd for organization).
##
## The flanking wall torches (banner + additive glow + animated flame + iron sconce) and
## the Collegium crest medallion. All render-only node factories: pass the stone-wall layer
## + viewport size + reduced-motion flag; no other scene state is touched. Consumed via
## preload as `BoardDecor` (TD-029/30 convention). Grayscale-additive VFX tinted at runtime.

const BoardGeo = preload("res://scripts/ui/board_geometry.gd")

# Flanking wall torches, drawn on the stone-wall layer (behind the centred board) in
# VIEWPORT space so the banners hang on the masonry beside the inset board (Prototype v1).
# Clears and rebuilds `stone_bg`'s children each call. Reduced motion pins the glow to peak.
static func add_torches(stone_bg: Node, vp: Vector2, reduced_motion: bool) -> void:
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
		var banner_cx: float = vp.x * (0.94 if at_right else 0.06)   # on the gutter "pillar", off the screen edge
		var btex_h := 474.0
		var btex_w := 74.0
		var target_h := vp.y * 0.72           # a full-height tapestry hang (v1), narrow strip
		var bs := target_h / btex_h
		var banner_w := btex_w * bs
		var banner_top := vp.y * 0.010
		var banner_pos := Vector2(banner_cx, banner_top + target_h * 0.5)
		# Contact shadow: the banner cast onto the masonry, offset down-right (the board's ONE
		# light convention), so the cloth reads as hung proud of the wall, not painted on it.
		var bshadow := Sprite2D.new()
		bshadow.texture = load("res://assets/ui/banner_v1.png") as Texture2D
		bshadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		bshadow.scale = Vector2(bs, bs)
		bshadow.centered = true
		bshadow.position = banner_pos + Vector2(3.0, 4.0)
		bshadow.modulate = Color(0.0, 0.0, 0.0, 0.32)
		bshadow.z_index = -1
		stone_bg.add_child(bshadow)
		# Red tattered banner sliced from the Prototype-v1 raster (TD-044), LINEAR-filtered,
		# modulated dark so it reads as a dim crimson tapestry, not a bright streak.
		var banner := Sprite2D.new()
		banner.texture = load("res://assets/ui/banner_v1.png") as Texture2D
		banner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		banner.scale = Vector2(bs, bs)
		banner.centered = true
		banner.position = banner_pos
		banner.modulate = Color(0.46, 0.15, 0.15)   # dim blood-crimson, low green/blue (not orange)
		banner.z_index = 0
		stone_bg.add_child(banner)
		# Iron mount rod the banner hangs from — a dark bar with two nail heads at the top edge,
		# so the tapestry is physically fixed to the wall instead of floating.
		var rod := Panel.new()
		var rod_sb := StyleBoxFlat.new()
		rod_sb.bg_color = Color(0.08, 0.07, 0.055)
		rod_sb.set_corner_radius_all(2)
		rod_sb.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
		rod_sb.shadow_size = 2
		rod_sb.shadow_offset = Vector2(2, 3)
		rod.add_theme_stylebox_override("panel", rod_sb)
		rod.size = Vector2(banner_w * 1.16, 5.0)
		rod.position = Vector2(banner_cx - rod.size.x * 0.5, banner_top - 2.0)
		rod.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rod.z_index = 1
		stone_bg.add_child(rod)
		for nx in [-0.42, 0.42]:
			var nail := Panel.new()
			var nsb := StyleBoxFlat.new()
			nsb.bg_color = Color(0.20, 0.17, 0.12)         # lit iron nailhead (top-left key)
			nsb.set_corner_radius_all(3)
			nail.add_theme_stylebox_override("panel", nsb)
			nail.size = Vector2(6, 6)
			nail.position = Vector2(banner_cx + banner_w * nx - 3.0, banner_top - 1.0)
			nail.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nail.z_index = 2
			stone_bg.add_child(nail)
		# The torch is mounted at the FOOT of the banner, directly beneath it (Prototype-v1
		# read): an iron sconce whose top cup holds the flame. `cup_y` is where the flame base
		# meets the sconce's top bar; the sconce stem hangs below, the flame rises above.
		var banner_bottom := banner_top + target_h
		var torch_x := banner_cx                       # under the banner, not beside it
		var cup_y := banner_bottom - vp.y * 0.02       # sconce cup at the banner's foot
		# Warm GUTTER WASH: a broad additive pool of firelight thrown across the stone pillar
		# and toward the frame, so the fire visibly lights its surroundings (not a pasted sprite).
		var wash := Sprite2D.new()
		wash.texture = load("res://assets/ui/torch_glow.png") as Texture2D
		wash.scale = Vector2(3.4, 3.9)
		wash.position = Vector2(torch_x, cup_y - vp.y * 0.08)
		wash.material = BoardGeo.additive_material()
		wash.modulate = Color(glowc.r, glowc.g, glowc.b, 0.20 if reduced_motion else 0.17)
		wash.z_index = -1
		stone_bg.add_child(wash)
		if not reduced_motion:
			var wt := wash.create_tween().set_loops()
			wt.tween_property(wash, "modulate:a", 0.22, 2.2).set_trans(Tween.TRANS_SINE)
			wt.tween_property(wash, "modulate:a", 0.13, 2.2).set_trans(Tween.TRANS_SINE)
		# Iron sconce (T-bracket): its top bar is the cup. Centered sprite (12x20 @1.4 -> 28h),
		# so top ≈ position.y-14; place position.y = cup_y+12 to seat the cup bar around cup_y.
		var sconce := Sprite2D.new()
		sconce.texture = load("res://assets/ui/torch_sconce.png") as Texture2D
		sconce.scale = Vector2(1.4, 1.4)
		sconce.position = Vector2(torch_x, cup_y + 12.0)
		sconce.z_index = 3
		stone_bg.add_child(sconce)
		# Glow: additive candle-pool, centred just above the cup on the flame.
		var glow := Sprite2D.new()
		glow.texture = load("res://assets/ui/torch_glow.png") as Texture2D
		glow.scale = Vector2(1.35, 1.5)
		glow.position = Vector2(torch_x, cup_y - 8.0)
		glow.material = BoardGeo.additive_material()
		glow.modulate = Color(glowc.r, glowc.g, glowc.b, 0.58 if reduced_motion else 0.52)
		glow.z_index = 3
		stone_bg.add_child(glow)
		if not reduced_motion:
			var t := glow.create_tween().set_loops()
			t.tween_property(glow, "modulate:a", 0.62, 1.8).set_trans(Tween.TRANS_SINE)
			t.tween_property(glow, "modulate:a", 0.44, 1.8).set_trans(Tween.TRANS_SINE)
		# Flame ON TOP of the sconce: its base (bottom of the 16x24 frame @1.2 -> 28.8h) seats
		# on the cup, so centre = cup_y - 14.4 puts the flame base at cup_y and the tip above.
		stone_bg.add_child(torch_flame(Vector2(torch_x, cup_y - 14.4), ember, reduced_motion))
		# A real 2D light at the flame (TD-043): it relights the stone wall AND the board's frame
		# edge from where the fire actually is, so the surfaces dynamically catch the firelight
		# (not a flat sprite). Same CanvasLayer as the frame, so the carved edge picks it up.
		# texture_scale 3.2 gives a ~205px reach — well past the gutter onto the frame's outer rail.
		var light := PointLight2D.new()
		light.texture = light_falloff()
		light.color = Color(1.0, 0.72, 0.42)                    # warm ember cast
		light.energy = 1.20 if reduced_motion else 1.35
		light.texture_scale = 3.2                               # reach the frame's outer rail
		light.position = Vector2(torch_x, cup_y - 12.0)
		stone_bg.add_child(light)
		if not reduced_motion:
			var lt := light.create_tween().set_loops()
			lt.tween_property(light, "energy", 1.55, 1.8).set_trans(Tween.TRANS_SINE)
			lt.tween_property(light, "energy", 1.15, 1.8).set_trans(Tween.TRANS_SINE)

# A small contained flame in the sconce (v1 candle) — a 4-frame grayscale-additive sheet
# tinted to the ember ramp. Reduced motion freezes it on frame 0.
static func torch_flame(center: Vector2, ember: Color, reduced_motion: bool) -> AnimatedSprite2D:
	var frames := SpriteFrames.new()      # ships with a "default" animation
	frames.set_animation_speed("default", 11.0)
	frames.set_animation_loop("default", true)
	var sheet := load("res://assets/ui/torch_flame.png") as Texture2D
	if sheet != null:
		for i in 4:
			var at := AtlasTexture.new()
			at.atlas = sheet
			at.region = Rect2(i * 16, 0, 16, 24)
			frames.add_frame("default", at)
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.scale = Vector2(1.2, 1.2)
	spr.position = center
	spr.material = BoardGeo.additive_material()
	spr.modulate = ember
	spr.z_index = 4              # a wall fixture, lit; the paper hangs in front of the glow
	if reduced_motion:
		spr.frame = 0
	else:
		spr.play("default")
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

# The Collegium crest medallion — the oval sliced from the Prototype-v1 raster (TD-044),
# hung at the top-centre of the frame. LINEAR-filtered so the painted gilt stays soft.
# Wrapped with a soft, offset cast shadow (the same oval silhouette in black) so the
# medallion reads as MOUNTED PROUD of the board wood, not a dark cutout in it.
static func board_crest() -> Control:
	var tex := load("res://assets/ui/crest_v1.png") as Texture2D
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.custom_minimum_size = Vector2(76, 35)
	root.size = Vector2(76, 35)
	# Drop shadow: the crest silhouette in translucent black, nudged down-right and
	# slightly enlarged. LINEAR + oversize gives it a soft edge (no blur pass needed).
	var shadow := TextureRect.new()
	shadow.texture = tex
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.modulate = Color(0.0, 0.0, 0.0, 0.42)
	shadow.position = Vector2(-2.0, 3.0)
	shadow.size = Vector2(80, 37)
	root.add_child(shadow)
	var face := TextureRect.new()
	face.texture = tex
	face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.stretch_mode = TextureRect.STRETCH_SCALE
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.size = Vector2(76, 35)
	root.add_child(face)
	return root
