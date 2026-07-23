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
## Layer 1  plate        architecture — static, never moves (P128)
## Layer 2  cloth        banners: slow sway
##          props        censers/chains: pendulum, randomized phase
##          vessels      candle racks, braziers (art carries NO flame — fire is Layer 3)
##          overlays     dust / smoke / light shafts, additive
## Layer 3  light        warm glow per fire, flicker out of step
## Layer 4  camera       2px idle drift + a breathing zoom, almost imperceptible
extends RefCounted

const DIR := "res://assets/ui/title/"

# Blockout palette — deliberately flat and unmistakably provisional. Nobody should mistake this
# for finished art, which is the whole point of a blockout.
# Architecture is tinted BY DEPTH, near-dark to far-light. That makes the blockout readable, and
# it previews the real scene's most important property: depth reads as luminance, so the near
# piers fall to silhouette against a distance that opens into light.
const C_NEAR := Color(0.115, 0.105, 0.098)     # the framing piers
const C_MID := Color(0.175, 0.163, 0.150)      # the arcade behind them
const C_FAR := Color(0.255, 0.238, 0.215)      # vault, apse, floor
const C_CLOTH := Color(0.34, 0.13, 0.12)
const C_PROP := Color(0.30, 0.25, 0.15)
const C_VESSEL := Color(0.24, 0.22, 0.19)
const C_OVERLAY := Color(0.55, 0.52, 0.45)
const C_EDGE := Color(0.52, 0.48, 0.40, 0.65)

# ── The composition, in viewport fractions: [cx, cy, w] plus an aspect for the blockout box. ──
# Read off the reference: two great piers framing, an arcade receding, banners high on the near
# piers, censers hanging inboard of them, candle racks and braziers along the floor.
const ARCH := [
	# The near piers are the frame. In the reference they are colossal — each owning roughly a
	# quarter of the width and running PAST the top and bottom edges, so the eye is boxed in and
	# forced down the nave. Sized so h = w x aspect exceeds the viewport height on purpose: a pier
	# that fits inside the frame reads as a column, not as architecture you are standing under.
	["pier_left.png",    Vector3(0.105, 0.500, 0.310), 2.45, "Pier L"],
	["pier_right.png",   Vector3(0.895, 0.500, 0.310), 2.45, "Pier R"],
	["arcade_left.png",  Vector3(0.320, 0.490, 0.185), 2.60, "Arcade L"],
	["arcade_right.png", Vector3(0.680, 0.490, 0.185), 2.60, "Arcade R"],
	["vault.png",        Vector3(0.500, 0.120, 0.360), 0.66, "Vault"],
	["apse.png",         Vector3(0.500, 0.575, 0.150), 1.35, "Apse / altar"],
	["floor.png",        Vector3(0.500, 0.890, 1.000), 0.26, "Floor"],
]
const CLOTH := [
	# Banners hang ON the near piers, so they ride outward with them.
	["banner_left.png",   Vector3(0.178, 0.345, 0.098), 2.25, "Banner L"],
	["banner_right.png",  Vector3(0.822, 0.345, 0.098), 2.25, "Banner R"],
	["banner_center.png", Vector3(0.500, 0.300, 0.052), 2.20, "Banner C"],
]
const PROPS := [
	# Censers hang inboard of the arcade, over the aisle.
	["censer.png", Vector3(0.383, 0.400, 0.032), 2.60, "Censer"],
	["censer.png", Vector3(0.617, 0.400, 0.032), 2.60, "Censer"],
	["chandelier.png", Vector3(0.500, 0.235, 0.092), 0.72, "Chandelier"],
]
const VESSELS := [
	["candle_rack.png", Vector3(0.128, 0.770, 0.150), 0.60, "Candle rack"],
	["candle_rack.png", Vector3(0.872, 0.770, 0.150), 0.60, "Candle rack"],
	["brazier.png",     Vector3(0.318, 0.840, 0.070), 0.85, "Brazier"],
	["brazier.png",     Vector3(0.682, 0.840, 0.070), 0.85, "Brazier"],
]
const OVERLAYS := [
	["light_shaft.png",   Vector3(0.395, 0.400, 0.280), 2.10, "Light shaft"],
	["smoke_overlay.png", Vector3(0.500, 0.560, 1.000), 0.56, "Smoke"],
	["dust_overlay.png",  Vector3(0.500, 0.500, 1.000), 0.56, "Dust"],
]

# Where fire burns. Layer 3 — these exist whether or not the vessel art has arrived.
const FIRES := [
	Vector2(0.128, 0.745), Vector2(0.872, 0.745),
	Vector2(0.318, 0.815), Vector2(0.682, 0.815),
	Vector2(0.383, 0.418), Vector2(0.617, 0.418),
	Vector2(0.500, 0.625),
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
	return Rect2(Vector2(vp.x * r.x - w * 0.5, vp.y * r.y - h * 0.5), Vector2(w, h))


## One layer: real art if it exists, else a labelled blockout of identical geometry. Returns the
## node either way, so the animation code never needs to know which it got.
static func _layer(host: Control, e: Array, z: int, tint: Color) -> Control:
	var tex := _tex(e[0])
	var rect := _rect_of(host.size, e[1], e[2], tex)
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
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root)
	root.size = host.size

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x7E57          # seeded: the same hall every launch, no two props ever in phase

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.055, 0.048, 0.042)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = -70
	root.add_child(bg)

	# ── Layer 1: architecture. Static, always — this is the plate. ──
	for e in ARCH:
		var tint := C_FAR
		if e[0].begins_with("pier"):
			tint = C_NEAR
		elif e[0].begins_with("arcade"):
			tint = C_MID
		_layer(root, e, -60 if e[0].begins_with("pier") else -62, tint)

	# ── Layer 2: cloth / props / vessels / overlays, each animated by kind. ──
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
	for e in OVERLAYS:
		var n3 := _layer(root, e, -30, C_OVERLAY)
		# Full-frame overlays as SOLID blockout panels fog the whole screen and hide the layers
		# underneath, which defeats the point of a blockout. Real art is mostly transparent, so
		# the stand-in is barely there; it exists to prove position and motion, not coverage.
		n3.modulate.a = 0.05 if _tex(e[0]) == null else 0.20
		if _tex(e[0]) != null:
			n3.material = _additive()
		if not reduced:
			if e[0].begins_with("light_shaft"):
				_breathe(n3, rng.randf_range(9.0, 13.0))
			else:
				_drift(n3, rng.randf_range(40.0, 70.0))

	# ── Layer 3: light. Warm pools at every fire, flickering out of step. ──
	for i in FIRES.size():
		var g := _glow(root, FIRES[i], host.size)
		if not reduced:
			_flicker(g, rng.randf_range(2.6, 4.2), rng.randf_range(0.0, TAU))

	# ── Layer 4: atmosphere. Real particles, not placeholders — they need no art, so they are
	#    finished work regardless of what the blockout is standing in for.
	if not reduced:
		_dust(root, host.size)
		for i in FIRES.size():
			_embers(root, FIRES[i], host.size, i)
		_incense(root, Vector2(0.383, 0.418), host.size)
		_incense(root, Vector2(0.617, 0.418), host.size)

	# ── Layer 5: camera life. ──
	if not reduced:
		_camera_life(root)
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
	var p := _particles(root, 7, 4.2, -26)
	p.position = Vector2(vp.x * at.x, vp.y * at.y)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(vp.x * 0.028, vp.y * 0.006)
	p.direction = Vector2(0.1 * (1 if salt % 2 == 0 else -1), -1)
	p.spread = 18.0
	p.gravity = Vector2(0, -9.0)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 11.0
	p.scale_amount_min = 0.014        # ~2px
	p.scale_amount_max = 0.036        # ~5px
	p.color = Color(1.0, 0.66, 0.28, 0.45)

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

static func _camera_life(root: Control) -> void:
	# The environment drifts ~2px and breathes 0.4%. Below the threshold of notice frame to
	# frame; felt over half a minute. The UI layer is separate and never moves with it.
	var p := root.position
	var t := root.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(root, "position", p + Vector2(2.0, -1.5), 18.0)
	t.tween_property(root, "position", p, 18.0)
	root.pivot_offset = root.size * 0.5
	var z := root.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	z.tween_property(root, "scale", Vector2(1.004, 1.004), 24.0)
	z.tween_property(root, "scale", Vector2.ONE, 24.0)


# ── Light ────────────────────────────────────────────────────────────────────

static func _additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

static func _glow(root: Control, at: Vector2, vp: Vector2) -> Control:
	# Light2D cannot reach Control nodes (TD-047), so a fire's pool is an additive radial sprite
	# — the same call the board's torches make.
	var g := TextureRect.new()
	g.texture = _radial()
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.material = _additive()
	g.modulate = Color(1.0, 0.70, 0.34, 0.34)
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
