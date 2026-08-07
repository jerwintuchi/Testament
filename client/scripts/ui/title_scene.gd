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

# ── God rays: ONE sheet, three placements (R266) ─────────────────────────────
# ONE ray, and it is actually visible — which the three before it were not (R275/TD-078).
#
# `light_shaft.png` peaks at alpha 34/255, and only ~9% of the sheet reaches even that. The rig was
# then multiplying by 0.20 / 0.13 / 0.10 and `_breathe` took another 35% off, so the brightest of the
# three added **6.8/255** — under 3%, over a hall whose own stone varies by more. They were invisible
# AND they were the most expensive thing in the frame: ~0.95 screens of fill, more than every
# particle combined.
#
# So: the two narrow flanking rays are deleted, and the dominant one is raised to a contribution
# computed from the sheet's own alpha rather than set by eye — 34 x 0.55 = an 18/255 peak. A hall
# lit evenly from three directions has no direction at all anyway; one shaft says where the light
# comes from, and costs half of what three invisible ones did.
const RAY_TEX := "light_shaft.png"
#                 cx, cy, w                     flip_h, opacity, breathe s
const RAYS := [
	[Vector3(0.400, 0.500, 0.4688), false, 0.55, 11.0],
]

# ── The air: three particle banks, and the scene's whole depth cue (R270/R271) ───────────────
#
# This REPLACES three drifting fog sheets (TD-077). A sheet sliding sideways is lateral parallax —
# planes moving past planes — and it read as exactly that: flat. Depth in a static frame comes from
# motion TOWARD the viewer, things growing and accelerating and leaving the frame, because that is
# the one cue a flat plane physically cannot fake.
#
# So the emitters sit AT the hall's vanishing point and `radial_accel` pushes particles outward from
# it. Near rushes past the camera and grows; far has a NEGATIVE accel and converges into the
# distance. The banks differ in the DIRECTION of travel, not only its speed — and it costs no
# per-frame script (P135), because an emitter placed at the VP with a radial accel IS the effect.

# The nave's vanishing point, in viewport fractions — DERIVED, not eyeballed (P137).
# `tools/measure_reference.py` solves the hall's camera and reports the nave VP at fy 0.8651, but
# that is measured on the UNCROPPED source. `gen_title_matte.py` crops the plate at (0, 110, 1536,
# 974) before scaling, so:
#
#     fy 0.8651  ->  (0.8651 * 1024 - 110) / 864  =  0.8980
#     fx 0.500   ->  unchanged (the crop is full width)
#
# The raw 0.8651 would put the VP ~24 logical px above where the architecture actually converges:
# plausible in a still, and visibly wrong the moment anything moves along it. `title_assets
# --selftest` re-derives this from the generator's crop box, so a future re-crop cannot leave the
# air converging on the wrong point.
const NAVE_VP := Vector2(0.500, 0.898)

# ONE ordered table, near to far (P136). Every channel that can carry depth carries it; a depth cue
# split across three functions drifts the moment one of them is tuned.
#         count, radius(logical), accel_min, accel_max, life, alpha, tint,                    z
const BANKS := [
	[18, 48.0,  16.0,  26.0,  7.0, 0.100, Color(0.86, 0.88, 0.94), -20],   # near — rushes past
	[26, 30.0,   3.0,   8.0, 13.0, 0.072, Color(0.92, 0.90, 0.86), -45],   # mid
	[30, 14.0,  -3.0,  -1.0, 26.0, 0.048, Color(0.96, 0.90, 0.78), -62],   # far — converges
]


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
	# ── Layer 2b: the air. Three particle banks, and the scene's whole depth cue (R270/R271). ──
	# The altar is COLD (R269): no glow pool, no embers, no haze. The only light at the sanctuary
	# is the light the plate paints, which is the point — it is a lit end to a dark nave, not a
	# bloom. `FIRES`, `_glow`, `_embers` and `_flicker` are deleted, not switched off.
	for i in BANKS.size():
		_bank(root, BANKS[i], host.size, reduced)
	_dust(root, host.size, reduced)

	# Three rays off one sheet, each with its own width, side and breath.
	for r in RAYS:
		var ray := _layer(root, [RAY_TEX, r[0], 1.20, "Light shaft"], -31, C_OVERLAY)
		var has_art := _tex(RAY_TEX) != null
		ray.modulate.a = 0.05 if not has_art else float(r[2])
		if has_art:
			ray.material = _additive()
			if ray is TextureRect:
				(ray as TextureRect).flip_h = bool(r[1])
		if not reduced:
			_breathe(ray, float(r[3]))

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

static func _dust(root: Control, vp: Vector2, reduced: bool) -> void:
	# Motes hanging in the whole volume, barely moving: the air of the room, not weather.
	# 46 -> 28 (R272): the three banks ARE the air now, and a static `dust_overlay.png` sheet was
	# drawing the same thing a second time until TD-078 retired it.
	var p := _particles(root, 28, 26.0, -28)
	p.position = Vector2(vp.x * 0.5, vp.y * 0.55)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.52, vp.y * 0.46)
	p.direction = Vector2(0.25, -1)
	p.spread = 26.0
	p.gravity = Vector2(1.2, -2.4)         # a whisper of a draught
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.5
	p.scale_amount_min = 0.022        # ~3px
	p.scale_amount_max = 0.070        # ~9px
	p.color = Color(0.98, 0.88, 0.68, 0.10)
	if reduced:
		p.speed_scale = 0.0            # frozen, not absent (R273/P134)


## One depth bank of air. The emitter sits AT the hall's vanishing point and `radial_accel` drives
## each particle away from it, so near-bank motes rush outward past the camera while far-bank ones
## (negative accel) fall back toward the distance. That single property is the whole 3D read, and it
## runs in the particle system's own simulation — no `_process`, no `_draw` (P135).
static func _bank(root: Control, e: Array, vp: Vector2, reduced: bool) -> CPUParticles2D:
	var count := int(e[0])
	var radius: float = e[1]
	var life: float = e[4]
	var p := _particles(root, count, life, int(e[7]))
	p.position = Vector2(vp.x * NAVE_VP.x, vp.y * NAVE_VP.y)
	# Born in a small pocket at the vanishing point, not across the frame: air that appears in the
	# distance and comes toward you is the effect; air that appears everywhere is a fog sheet again.
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = vp.x * 0.06
	# A ZERO direction gives the initial velocity no direction at all, so particles sat on the
	# emitter and crept out on `radial_accel` alone. `spread = 180` off any unit vector is a full
	# circle, which is what "outward from the VP" needs.
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.gravity = Vector2.ZERO               # this is air in a still room; nothing falls
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 4.0
	p.radial_accel_min = e[2]
	p.radial_accel_max = e[3]
	# `_radial()` is a 128px texture, so a scale of 1.0 is a 128px blob. The bank's radius is in
	# logical px, hence the divide — the first title pass blew the frame to white by forgetting it.
	p.scale_amount_min = (radius * 0.7) / 128.0
	p.scale_amount_max = (radius * 1.3) / 128.0
	# Grow over life: a mote approaching the camera gets bigger. This is the second half of the
	# depth cue, and like the first it is a built-in curve rather than per-frame code.
	var grow := Curve.new()
	grow.add_point(Vector2(0.0, 0.35))
	grow.add_point(Vector2(1.0, 1.0))
	p.scale_amount_curve = grow
	# Fade in and out so nothing pops at birth or death.
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.25, Color(1, 1, 1, 1.0))
	ramp.add_point(0.70, Color(1, 1, 1, 1.0))
	p.color_ramp = ramp
	var tint: Color = e[6]
	p.color = Color(tint.r, tint.g, tint.b, e[5])
	if reduced:
		p.speed_scale = 0.0            # frozen, fully present, fully lit (R273/P134)
	return p


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
