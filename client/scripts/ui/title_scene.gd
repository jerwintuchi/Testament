## The title screen's environment: a layered Collegium hall (TD-073).
##
## Built on a passed-in host, the `BoardDecor.add_torches` idiom. Every layer is an INDEPENDENT
## node with its own animation, and every layer's art is OPTIONAL: until its texture exists, the
## layer renders as a labelled BLOCKOUT in the right place, at the right size, with the right
## motion. So composition, lighting, animation and menu flow are all reviewable now, and real art
## drops in later with no code change — the only thing that changes is a file appearing on disk.
##
## The reference concept art is NOT used as the background. It lives at
## `art/src/collegium_hall_src.png` as a composition reference only.
##
## Layer 1  plate        the hall — one bespoke pixel-art plate, drawn 1:1, never moves (P128)
## Layer 2  cloth        banners: slow sway
##          props        censers/chains: pendulum, randomized phase
##          vessels      candle racks, braziers (art carries NO flame — fire is Layer 3)
##          rays         three god-ray placements off one sheet, additive
## Layer 3  air          three particle banks emitted AT the vanishing point (TD-078) — the
##                       scene's whole depth cue. The altar is cold: no glow, no embers, no haze.
## The architecture never moves at all (TD-075): only cloth, rays and air do.
extends RefCounted

const DIR := "res://assets/ui/title/"

# The hall itself: one bespoke plate, authored at the internal resolution and drawn 1:1.
const PLATE := "hall_plate.png"

# The plate is a painting that already contains the hall's furniture, so our prop layers would
# double it. They stay in the tables (and in the asset contract) but are not drawn.
# TRUE again, on the author's call: the title screen is the hall and the UI, and nothing else. The
# banners, censers, chandelier, racks and braziers are all switched off — the only mark above the
# lettering is the Collegium device, drawn by the UI itself. Their art, their tables and the asset
# contract are untouched, so this is one flag to reverse.
const PROPS_IN_PLATE := true

# Blockout palette — deliberately flat and unmistakably provisional. Nobody should mistake this
# for finished art, which is the whole point of a blockout.
# Architecture is tinted BY DEPTH, near-dark to far-light. That makes the blockout readable, and
# it previews the real scene's most important property: depth reads as luminance, so the near
# piers fall to silhouette against a distance that opens into light.
const C_CLOTH := Color(0.34, 0.13, 0.12)
const C_PROP := Color(0.30, 0.25, 0.15)
const C_VESSEL := Color(0.24, 0.22, 0.19)
const C_OVERLAY := Color(0.55, 0.52, 0.45)
const C_EDGE := Color(0.52, 0.48, 0.40, 0.65)

# ── The composition, in viewport fractions: [cx, cy, w] plus an aspect for the blockout box. ──
# The cathedral is ONE bespoke plate (TD-075, the author's brief): "Do not attempt to convert the
# cathedral into reusable gameplay architecture." The seven per-surface slices that used to layer
# over it are retired — only decorative foreground elements stay separate, and they stay separate
# because they ANIMATE, not because they might be reused.
# The censer's position was once read in four places (prop, glow pool, incense emitter, and the
# plume baked into `smoke_overlay.png`). Three of those are now retired with the cold altar, so the
# constant survives only for the prop itself — kept because `PROPS_IN_PLATE` is one flag away from
# drawing the censers again.
const CENSER_LX := 0.300
const CENSER_RX := 0.700
const CENSER_Y := 0.285
const CENSER_FIRE_Y := 0.337      # the vessel hangs below the sprite's centre; the fire is on it

const CLOTH := [
	# Banners hang ON the near piers, so they ride outward with them.
	["banner_left.png",   Vector3(0.158, 0.330, 0.1469), 1.787, "Banner L"],
	["banner_right.png",  Vector3(0.842, 0.322, 0.1453), 1.742, "Banner R"],
	# The third hangs HIGH, small and deep. It used to sit at 0.360, squarely behind the title;
	# the centre of this frame belongs to the UI (R245), and cloth reads better as depth than as a
	# backdrop for lettering. Sized so its head meets the frame's top edge — it hangs from
	# off-screen, the way the censer's chain does — and its foot stops just above the corona
	# rather than disappearing behind it.
	["banner_center.png", Vector3(0.500, 0.090, 0.0406), 2.38, "Banner C"],
]
const PROPS := [
	# Censers hang inboard of the arcade, over the aisle — moved OUTBOARD from 0.383/0.617, where
	# they flanked the title so closely they read as part of it.
	["censer.png", Vector3(CENSER_LX, CENSER_Y, 0.0422), 2.296, "Censer"],
	["censer.png", Vector3(CENSER_RX, CENSER_Y, 0.0422), 2.296, "Censer"],
	["chandelier.png", Vector3(0.500, 0.140, 0.0688), 0.68, "Chandelier"],
]
# The floor props are NOT mirrored, in two senses. Each is its own seeded variant — different
# taper counts and heights, a different bowl, differently spun legs — and each is drawn LEANING
# toward the zenith its own position implies, because this camera is pitched up and every vertical
# in the hall converges above the frame. A plumb prop reads as pasted onto the picture.
# The right-hand pair also stands slightly further down the nave: smaller, and higher in frame.
# These lines are printed by `gen_title_props.py`, which owns the geometry — the width includes
# the padding its shear needs, so the object still renders at the size the generator was asked for.
const VESSELS := [
	["candle_rack.png",   Vector3(0.1700, 0.8800, 0.1641), 0.524, "Candle rack"],
	["candle_rack_b.png", Vector3(0.8350, 0.8720, 0.1500), 0.531, "Candle rack"],
	["brazier.png",       Vector3(0.3400, 0.9150, 0.0766), 0.857, "Brazier"],
	["brazier_b.png",     Vector3(0.6620, 0.9080, 0.0703), 0.867, "Brazier"],
]
# RETIRED (TD-078): `dust_overlay.png` and `smoke_overlay.png`. Dust was being drawn TWICE — as a
# static sheet AND as `_dust()`'s particles — since T260c, and the smoke was a plume rising off an
# altar that is now cold, which is the same failure TD-076 removed the censers' incense for. Both
# were full-frame additive layers, and the budget (R272) allows three; the screen was running five.

# The nave's vanishing point, in viewport fractions — DERIVED, not eyeballed (P137).
# `tools/measure_reference.py` solves the hall's camera and reports the nave VP at fy 0.8651, but
# that is measured on the UNCROPPED source. `gen_title_matte.py` crops the plate at (0, 110, 1536,
# 974) before scaling, so:
#
#     fy 0.8651  ->  (0.8651 * 1024 - 110) / 864  =  0.8980
#     fx 0.500   ->  unchanged (the crop is full width)
#
# The raw 0.8651 would put the VP ~24 logical px above where the architecture actually converges:
# plausible in a still, and visibly wrong the moment anything is placed against it. `title_assets
# --selftest` re-derives this from the generator's crop box, so a future re-crop cannot leave the
# air hanging off the wrong point. The shader reads it too — depth has no buffer here, so distance
# from the VP IS the depth proxy.
const NAVE_VP := Vector2(0.500, 0.898)

# RETIRED (TD-079): the three `CPUParticles2D` fog banks and the `light_shaft.png` overlay. The
# author's brief — "replace obvious fog particles with cathedral air", "no looping clouds", "no
# smoke-like motion" — and all of it now lives in `title_air.gdshader` on the plate, at no fill cost.
# Dust survives, because dust is not fog: it is the one thing in the room that should still be
# individually visible.


static func _tex(file: String) -> Texture2D:
	var p := DIR + file
	return load(p) as Texture2D if ResourceLoader.exists(p) else null


static func _rect_of(vp: Vector2, r: Vector3, aspect: float, tex: Texture2D) -> Rect2:
	var w := vp.x * r.z
	var ratio := aspect
	if tex != null:
		ratio = float(tex.get_height()) / maxf(1.0, float(tex.get_width()))
	var h := w * ratio
	# Snap to whole pixels: the point of authoring at the internal resolution is that a sprite
	# occupies exact pixels, and a fractional position quietly undoes it.
	return Rect2(Vector2(roundf(vp.x * r.x - w * 0.5), roundf(vp.y * r.y - h * 0.5)),
		Vector2(roundf(w), roundf(h)))


## One layer: real art if it exists, else a labelled blockout of identical geometry. Returns the
## node either way, so the animation code never needs to know which it got.
static func _layer(host: Control, e: Array, z: int, tint: Color, overscan: float = 1.0) -> Control:
	var tex := _tex(e[0])
	var rect := _rect_of(host.size, e[1], e[2], tex)
	if overscan != 1.0:
		# Scale about the frame's centre, exactly as `_plate` does, so a layer cut from the
		# plate's camera stays coincident with it.
		var c := host.size * 0.5
		rect = Rect2((rect.position - c) * overscan + c, rect.size * overscan)
	var node: Control
	if tex != null:
		var t := TextureRect.new()
		t.texture = tex
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
		t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		node = t
	else:
		node = _blockout(tint, str(e[3]), rect.size)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.position = rect.position
	node.size = rect.size
	node.z_index = z
	host.add_child(node)
	return node


## The full-frame architecture plate: inert, behind everything, never animated (P128).
static func _plate(host: Control, tex: Texture2D, vp: Vector2) -> Control:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# COVERED, not STRETCH: a 16:9 plate in a non-16:9 viewport overflows rather than distorting
	# the composition, which R241 forbids.
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# EXACTLY the viewport, no overscan: the plate is authored at the internal resolution, so 1:1
	# is the only scale at which its pixels stay square. An overscan of 1.2% would resample every
	# one of them, which is the difference between pixel art and a photograph of pixel art.
	t.size = vp
	t.position = Vector2.ZERO
	t.z_index = -64
	# THE AIR RIDES THE PLATE (TD-079). Ground haze, atmospheric perspective, god rays, the altar's
	# emphasis and the slow breath of the light are all one shader pass on a quad that is rasterised
	# every frame anyway — so they cost ALU and no additional fill, where the particle banks and the
	# ray sheet they replace cost ~1.4 screens of blending between them (P138). It samples 1:1 under
	# this node's own NEAREST filter and only modulates colour, so the plate is never resampled.
	var sh := load(DIR + "title_air.gdshader") as Shader
	if sh != null:
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("vp_uv", NAVE_VP)
		m.set_shader_parameter("aspect", vp.x / maxf(1.0, vp.y))
		t.material = m
	host.add_child(t)
	return t


static func _blockout(tint: Color, label: String, size: Vector2) -> Control:
	# A flat panel with a hairline edge and its name on it. Obvious at a glance that it is a
	# stand-in, while still occupying exactly the footprint the real asset will.
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = tint
	sb.border_color = C_EDGE
	sb.set_border_width_all(1)
	p.add_theme_stylebox_override("panel", sb)
	p.custom_minimum_size = size
	if size.y > 22.0 and size.x > 34.0:
		var l := Label.new()
		l.text = label
		l.add_theme_font_size_override("font_size", 7)
		l.add_theme_color_override("font_color", Color(0.85, 0.82, 0.72, 0.80))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(l)
	return p


## Build the environment onto `host` (a full-rect Control). Returns the root it created.
## `reduced` freezes every animation to a lit, still frame (R244).
static func build(host: Control, reduced: bool) -> Control:
	var root := Control.new()
	root.name = "TitleScene"
	# anchors AND offsets. FULL_RECT sets non-equal opposite anchors, so a manual `size` write
	# is both overridden after _ready() and warned about on every launch — the same trap that
	# left the room scroll at 0x0 in TD-071 T240. Every layer below measures `host.size`
	# anyway, so nothing here depended on the write.
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root)

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x7E57          # seeded: the same hall every launch, no two props ever in phase

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.055, 0.048, 0.042)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -70
	root.add_child(bg)

	# ── Layer 1: architecture. Static, always — this is the plate. ──
	var plate := _tex(PLATE)
	if plate != null:
		_plate(root, plate, host.size)

	# ── Layer 2: cloth / props / vessels / overlays, each animated by kind. ──
	if not PROPS_IN_PLATE:
		for e in CLOTH:
			var n := _layer(root, e, -50, C_CLOTH)
			if not reduced:
				_sway(n, rng.randf_range(5.5, 7.5), rng.randf_range(0.0, TAU))
		for e in PROPS:
			var n2 := _layer(root, e, -45, C_PROP)
			if not reduced:
				_pendulum(n2, rng.randf_range(3.4, 4.6), rng.randf_range(0.0, TAU))
		for e in VESSELS:
			_layer(root, e, -40, C_VESSEL)
	# ── Layer 2b: the air. It is in the PLATE'S SHADER now (TD-079), not in this tree. ──
	# What remains here is dust, at two depths — the only atmosphere that should still resolve as
	# individual specks rather than as air.
	_dust(root, host.size, reduced)

	# No camera life. The brief is explicit: "The architecture itself remains static. Only
	# atmospheric elements should move." A 2px drift also resampled a plate that must stay on
	# whole pixels, so this is a register requirement as much as an art direction one.
	return root


# ── Atmosphere ───────────────────────────────────────────────────────────────
# The brief: "very slow movement, large particles, low opacity, never distract from the menu."
# So these are deliberately sparse and dim — you should notice them only if you look for them.

static func _particles(root: Control, amount: int, life: float, z: int) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = _radial()
	p.amount = amount
	p.lifetime = life
	p.lifetime_randomness = 0.55
	p.preprocess = life                    # start mid-flight, so nothing "switches on" at boot
	p.randomness = 0.6
	p.material = _additive()
	p.z_index = z
	root.add_child(p)
	return p

## Dust hanging in centuries-old air (R279).
##
## It DRIFTS; it does not rise. The old field pushed everything upward on a negative gravity, which
## reads as heat or smoke — the two things this hall is not. Now gravity is essentially nil, the
## spread is full, and the drift is a whisper of horizontal draught, so motes wander instead of
## streaming. Two emitters at different depths give the parallax: the near one is larger, faster and
## fainter; the far one is small, slower and slightly brighter because it sits in the lit distance.
static func _dust(root: Control, vp: Vector2, reduced: bool) -> void:
	#          count, life, scale_min, scale_max, alpha,  drift,  z
	# The third row is FOG, not dust: big, very slow, and almost too faint to see. The author's
	# note was "much more, but not too much — just to hint that it exists", and that is the whole
	# spec for it. The shader owns the actual atmosphere (TD-079); these only give the air something
	# to catch, so the volume is hinted rather than drawn.
	#          count, life, scale_min, scale_max, alpha, drift,  z
	var depths := [
		[18, 54.0, 0.030, 0.055, 0.055, 1.5, -26],   # near dust: bigger, faster, fainter
		[22, 78.0, 0.014, 0.026, 0.075, 0.7, -58],   # far dust: small, slower, in the lit distance
		[20, 96.0, 0.220, 0.400, 0.042, 0.5, -40],   # fog motes: large, near-invisible, barely move
	]
	for d in depths:
		var p := _particles(root, int(d[0]), float(d[1]), int(d[6]))
		p.position = Vector2(vp.x * 0.5, vp.y * 0.52)
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(vp.x * 0.54, vp.y * 0.48)
		# No preferred direction and no gravity: this is still air, not a draught with an agenda.
		p.direction = Vector2(1, 0)
		p.spread = 180.0
		p.gravity = Vector2(float(d[5]) * 0.35, -float(d[5]) * 0.12)
		p.initial_velocity_min = 0.2
		p.initial_velocity_max = float(d[5])
		p.scale_amount_min = float(d[2])
		p.scale_amount_max = float(d[3])
		# Opacity varies per mote, and each fades up and away rather than blinking in.
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1, 1, 1, 0.0))
		ramp.set_color(1, Color(1, 1, 1, 0.0))
		ramp.add_point(0.22, Color(1, 1, 1, 1.0))
		ramp.add_point(0.74, Color(1, 1, 1, 1.0))
		p.color_ramp = ramp
		p.color = Color(0.98, 0.92, 0.78, float(d[4]))
		if reduced:
			p.speed_scale = 0.0

# ── Animations ───────────────────────────────────────────────────────────────
# All LOW amplitude on purpose: the brief is Elden Ring, not an animated wallpaper. Every one is
# a looping tween, so nothing needs _process and the whole rig frees cleanly with its node.

static func _sway(n: Control, period: float, phase: float) -> void:
	n.pivot_offset = Vector2(n.size.x * 0.5, 0.0)      # cloth hangs from its rod
	n.rotation = deg_to_rad(-0.5)
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(phase * 0.12)
	t.tween_property(n, "rotation", deg_to_rad(0.5), period * 0.5)
	t.tween_property(n, "rotation", deg_to_rad(-0.5), period * 0.5)

static func _pendulum(n: Control, period: float, phase: float) -> void:
	n.pivot_offset = Vector2(n.size.x * 0.5, 0.0)      # swings from where the chain meets the roof
	n.rotation = deg_to_rad(-0.9)
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(phase * 0.1)
	t.tween_property(n, "rotation", deg_to_rad(0.9), period * 0.5)
	t.tween_property(n, "rotation", deg_to_rad(-0.9), period * 0.5)

static func _breathe(n: Control, period: float) -> void:
	var a := n.modulate.a
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(n, "modulate:a", a * 0.65, period * 0.5)
	t.tween_property(n, "modulate:a", a, period * 0.5)



# ── Light ────────────────────────────────────────────────────────────────────

static func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

static var _radial_cache: GradientTexture2D = null

static func _radial() -> GradientTexture2D:
	if _radial_cache != null:
		return _radial_cache
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = grad
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	_radial_cache = t
	return t
