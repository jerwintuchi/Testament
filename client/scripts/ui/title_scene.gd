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
##          overlays     dust / smoke / light shafts, additive
## Layer 3  light        warm glow per fire, flicker out of step
## The architecture never moves at all (TD-075): only cloth, props, fire and air do.
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
# The censer's position is read in FOUR places — the prop itself, its glow pool, its incense
# emitter, and (in Python) the plume baked into `smoke_overlay.png`. Three of those are here, so
# they are one constant: moving a censer and leaving its own smoke rising from where it used to
# hang is exactly the kind of drift that survives a playtest unnoticed.
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
const OVERLAYS := [
	["smoke_overlay.png", Vector3(0.500, 0.500, 1.000), 0.5625, "Smoke"],
	["dust_overlay.png",  Vector3(0.500, 0.500, 1.000), 0.5625, "Dust"],
]

# ── God rays: ONE sheet, three placements (R266) ─────────────────────────────
# Light falls through the clerestory on both sides of the nave, not from a single window. That is
# three rays, and it is deliberately not three assets: `light_shaft.png` is mirrored and rescaled
# per placement. The dominant ray keeps its original position and strength; the other two are
# narrower and dimmer, because a hall lit evenly from three directions has no direction at all.
# Each breathes on its OWN period — rays pulsing together are the same tell as synchronised flicker.
const RAY_TEX := "light_shaft.png"
#                 cx, cy, w                     flip_h, opacity, breathe s
const RAYS := [
	[Vector3(0.400, 0.500, 0.4688), false, 0.20, 11.0],
	[Vector3(0.700, 0.470, 0.3600), true,  0.13, 14.5],
	[Vector3(0.235, 0.520, 0.3100), false, 0.10, 8.5],
]

# ── Fog: the scene's only parallax (R263, P132) ──────────────────────────────
# The hall is a flat painted plate, so it has no depth to parallax. Moving the plate would expose
# that at once — but moving fog against OTHER fog does not, because the only thing the eye can
# compare is one bank to another. Three banks at three speeds is therefore the entire depth cue,
# and not one of them touches the architecture.
#
# Each sheet is 1440x720 for a 1280-wide frame: the extra 160px is exactly the drift headroom, so a
# leading edge can never walk into view and announce itself as a sheet.
#
#           file,           z,   opacity, tint,                        drift px, period s, breath s
const FOG := [
	["fog_far.png",  -60, 0.46, Color(1.00, 0.88, 0.70), 22.0, 90.0, 41.0],
	["fog_mid.png",  -52, 0.36, Color(0.96, 0.92, 0.86), 30.0, 55.0, 29.0],
	["fog_near.png", -33, 0.32, Color(0.90, 0.90, 0.92), 38.0, 32.0, 19.0],
]
const FOG_OVERHANG := 0.125            # 1440/1280 - 1: how much wider the sheets are than the frame

# Where fire burns. Layer 3 — these exist whether or not the vessel art has arrived.
const FIRES := [
	# These track VESSELS: a fire burns on a vessel, so moving one and not the other leaves a
	# warm pool hanging over empty floor.
	Vector2(0.500, 0.845),
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


## One fog bank: a sheet wider than the frame, drifting horizontally at its own speed with a slower
## vertical breath. Missing art is simply skipped — a blockout panel would fog the whole screen and
## hide everything a blockout exists to let you check.
static func _fog(root: Control, e: Array, vp: Vector2, reduced: bool, phase: float) -> Control:
	var tex := _tex(e[0])
	if tex == null:
		return null
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	# NEAREST, like everything else on this screen: the sheets are authored at 1440x720 so that at a
	# 720p window they land one art pixel per device pixel, and their bands stay hard edges.
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.material = _additive()
	t.modulate = Color(e[3].r, e[3].g, e[3].b, e[2])
	var w := roundf(vp.x * (1.0 + FOG_OVERHANG))
	t.size = Vector2(w, vp.y)
	var home := Vector2(roundf((vp.x - w) * 0.5), 0.0)
	t.position = home
	t.z_index = int(e[1])
	root.add_child(t)
	if reduced:
		return t                      # still, and fully present: reduced motion loses nothing (P134)

	var drift: float = e[4]
	var per: float = e[5]
	# Horizontal: the parallax itself. Amplitude stays inside the overhang, so no edge ever enters
	# the frame however long the screen is left running.
	var hx := t.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hx.tween_interval(per * (phase / TAU) * 0.5)     # seeded apart: banks in step read as one sheet
	hx.tween_property(t, "position:x", home.x + drift, per * 0.5)
	hx.tween_property(t, "position:x", home.x - drift, per * 0.5)
	hx.tween_property(t, "position:x", home.x, 0.0)
	# Vertical: a slow breath, a fraction of the horizontal, so the bank lifts and settles.
	var vy := t.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var lift: float = maxf(2.0, drift * 0.16)
	vy.tween_property(t, "position:y", home.y - lift, float(e[6]) * 0.5)
	vy.tween_property(t, "position:y", home.y, float(e[6]) * 0.5)
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
	# ── Layer 2b: fog. The only thing in this scene that parallaxes (R263). ──
	for i in FOG.size():
		_fog(root, FOG[i], host.size, reduced, rng.randf_range(0.0, TAU))

	for e in OVERLAYS:
		var n3 := _layer(root, e, -30, C_OVERLAY)
		# Full-frame overlays as SOLID blockout panels fog the whole screen and hide the layers
		# underneath, which defeats the point of a blockout. Real art is mostly transparent, so
		# the stand-in is barely there; it exists to prove position and motion, not coverage.
		n3.modulate.a = 0.05 if _tex(e[0]) == null else 0.20
		if _tex(e[0]) != null:
			n3.material = _additive()
		if not reduced:
			_drift(n3, rng.randf_range(40.0, 70.0))

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

	# ── Layer 3: light. Warm pools at every fire, flickering out of step. ──
	for i in FIRES.size():
		# The centre fire stood in for a lit altar while the architecture was a blockout. The
		# plate paints its own apse now, so that pool is redundant — and it landed exactly where
		# the menu's last option is read (R245). Dimmed to a suggestion rather than deleted: the
		# embers and the warmth down the nave still want a source there.
		var g := _glow(root, FIRES[i], host.size, 0.42 if i == 6 else 1.0)
		if not reduced:
			_flicker(g, rng.randf_range(2.6, 4.2), rng.randf_range(0.0, TAU))

	# ── Layer 4: atmosphere. Real particles, not placeholders — they need no art, so they are
	#    finished work regardless of what the blockout is standing in for.
	if not reduced:
		_dust(root, host.size)
		for i in FIRES.size():
			_embers(root, FIRES[i], host.size, i)
		if not PROPS_IN_PLATE:                # incense rises off censers; with none, none rises
			_incense(root, Vector2(CENSER_LX, CENSER_FIRE_Y), host.size)
			_incense(root, Vector2(CENSER_RX, CENSER_FIRE_Y), host.size)

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

static func _dust(root: Control, vp: Vector2) -> void:
	# Motes hanging in the whole volume, barely moving. Large and very dim: this is the air of
	# the room, not weather.
	var p := _particles(root, 46, 26.0, -28)
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

static func _embers(root: Control, at: Vector2, vp: Vector2, salt: int) -> void:
	# Rising off each fire. Few, small, warm — the only particles allowed to be noticed.
	# Tuned UP for the sanctuary (R266): with the six vessel fires gone this is the one fire left in
	# the frame, and at the old count it threw two or three sparks a second into the brightest part
	# of the picture, where they simply vanished. More of them, living longer and climbing further,
	# so the altar reads as burning rather than merely lit.
	var p := _particles(root, 16, 5.6, -26)
	p.position = Vector2(vp.x * at.x, vp.y * at.y)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.040, vp.y * 0.008)
	p.direction = Vector2(0.1 * (1 if salt % 2 == 0 else -1), -1)
	p.spread = 30.0
	p.gravity = Vector2(0, -11.0)
	p.initial_velocity_min = 5.0
	p.initial_velocity_max = 14.0
	# The altar sits directly below the menu column, so an undamped ember climbs straight through
	# the last option (R245). Damping caps the climb where a widened spread has already thinned the
	# stream, and it is what a cooling ember does anyway — it does not coast.
	p.damping_min = 2.4
	p.damping_max = 5.0
	p.scale_amount_min = 0.014        # ~2px
	p.scale_amount_max = 0.040        # ~5px
	p.color = Color(1.0, 0.64, 0.26, 0.62)

static func _incense(root: Control, at: Vector2, vp: Vector2) -> void:
	# Smoke off a censer: slower and larger than embers, and colder, so the two never read as
	# the same effect.
	var p := _particles(root, 9, 13.0, -27)
	p.position = Vector2(vp.x * at.x, vp.y * at.y)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.010, vp.y * 0.004)
	p.direction = Vector2(0.35, -1)
	p.spread = 30.0
	p.gravity = Vector2(1.6, -5.0)
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 5.0
	p.scale_amount_min = 0.16         # smoke IS large — but 20px, not 400
	p.scale_amount_max = 0.34
	p.color = Color(0.86, 0.82, 0.74, 0.035)


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

static func _drift(n: Control, period: float) -> void:
	var y := n.position.y
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(n, "position:y", y - 14.0, period * 0.5)
	t.tween_property(n, "position:y", y, period * 0.5)

static func _flicker(n: Control, period: float, phase: float) -> void:
	var a := n.modulate.a
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(phase * 0.08)
	t.tween_property(n, "modulate:a", a * 0.70, period * 0.37)
	t.tween_property(n, "modulate:a", a * 1.05, period * 0.29)
	t.tween_property(n, "modulate:a", a, period * 0.34)


# ── Light ────────────────────────────────────────────────────────────────────

static func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

static func _glow(root: Control, at: Vector2, vp: Vector2, energy: float = 1.0) -> Control:
	# Light2D cannot reach Control nodes (TD-047), so a fire's pool is an additive radial sprite
	# — the same call the board's torches make.
	var g := TextureRect.new()
	g.texture = _radial()
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.material = _additive()
	# 0.26, not the 0.34 the blockout wanted: these pools were tuned against a BLACK backdrop,
	# and over a real plate that already carries its own warm distance they stacked into a wash
	# the menu had to be read through (R245).
	g.modulate = Color(1.0, 0.70, 0.34, 0.26 * energy)
	var r := vp.x * 0.095
	g.size = Vector2(r * 2.0, r * 1.5)
	g.position = Vector2(vp.x * at.x - r, vp.y * at.y - r * 0.75)
	g.z_index = -35
	root.add_child(g)
	return g

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
