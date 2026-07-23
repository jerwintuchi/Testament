## The title screen's environment: a static matte-painted Collegium with independently animated
## layers over it (TD-073). Built on a passed-in host, the `BoardDecor.add_torches` idiom.
##
## Every asset is OPTIONAL. A missing texture skips its layer silently, so the authored pieces
## (see specs/title-scene/asset-manifest.md) can land one at a time and the screen keeps running
## the whole way. That is deliberate: it decouples the engineering from the art delivery.
##
## Layer 1  plate        static, never moves or animates (P128)
## Layer 2  cloth        banners, slow sway
##          props        censers/chains, pendulum with randomized phase
##          vessels      candle racks, braziers (drawn WITHOUT flame)
##          overlays     dust / smoke / light shafts, additive
## Layer 3  light        flicker + breathing, in-engine
## Layer 4  camera       2-3px idle drift + a breathing zoom, almost imperceptible
extends RefCounted

const DIR := "res://assets/ui/title/"

# name -> (rect in viewport fractions [cx, cy, w], z, kind)
# `kind` drives the animation the layer gets. Positions are authored, not derived — the plate is a
# painting, so its props sit where the painter put them.
const CLOTH := [
	["banner_left.png",   Vector3(0.128, 0.300, 0.150), "sway"],
	["banner_right.png",  Vector3(0.872, 0.300, 0.150), "sway"],
	["banner_center.png", Vector3(0.500, 0.235, 0.090), "sway"],
]
const PROPS := [
	["censer.png",  Vector3(0.318, 0.360, 0.052), "pendulum"],
	["censer.png",  Vector3(0.682, 0.360, 0.052), "pendulum"],
	["chandelier.png", Vector3(0.500, 0.150, 0.150), "pendulum"],
]
const VESSELS := [
	["candle_rack.png", Vector3(0.085, 0.760, 0.190), "still"],
	["candle_rack.png", Vector3(0.915, 0.760, 0.190), "still"],
	["brazier.png",     Vector3(0.235, 0.815, 0.100), "still"],
	["brazier.png",     Vector3(0.765, 0.815, 0.100), "still"],
]
const OVERLAYS := [
	["light_shaft.png",  Vector3(0.360, 0.420, 0.470), "shaft"],
	["smoke_overlay.png", Vector3(0.500, 0.560, 1.000), "drift"],
	["dust_overlay.png",  Vector3(0.500, 0.500, 1.000), "drift"],
]

# Fires the rig lights and animates, as viewport fractions. These sit ON the vessels above; when
# `brazier.png`/`candle_rack.png` are absent they still light the plate's painted flames.
const FIRES := [
	Vector2(0.085, 0.735), Vector2(0.915, 0.735),
	Vector2(0.235, 0.795), Vector2(0.765, 0.795),
	Vector2(0.318, 0.372), Vector2(0.682, 0.372),
	Vector2(0.500, 0.700),
]


static func _tex(file: String) -> Texture2D:
	# ResourceLoader.exists keeps a missing asset from spamming the log every frame it is asked for.
	var p := DIR + file
	if not ResourceLoader.exists(p):
		return null
	return load(p) as Texture2D


static func _place(host: Control, tex: Texture2D, r: Vector3, z: int) -> TextureRect:
	var vp := host.size
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # painted art, not pixel art (R242)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := vp.x * r.z
	var h := w * (float(tex.get_height()) / maxf(1.0, float(tex.get_width())))
	t.size = Vector2(w, h)
	t.position = Vector2(vp.x * r.x - w * 0.5, vp.y * r.y - h * 0.5)
	t.z_index = z
	host.add_child(t)
	return t


## Build the whole environment onto `host` (a full-rect Control). Returns the root it created so
## the caller can free it. `reduced` freezes every animation to a lit, still frame (R244).
static func build(host: Control, reduced: bool) -> Control:
	var root := Control.new()
	root.name = "TitleScene"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(root)
	root.size = host.size

	var rng := RandomNumberGenerator.new()
	rng.seed = 0x7E57                       # seeded: the same hall every launch, but no two
	                                        # props in phase with each other

	# ── Layer 1: the plate. Static, always. ──
	var plate := _tex("hall_plate.png")
	if plate == null:
		plate = _tex("collegium_hall.png")   # today's stand-in, until the clean plate lands
	if plate != null:
		var p := TextureRect.new()
		p.texture = plate
		p.set_anchors_preset(Control.PRESET_FULL_RECT)
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		p.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.z_index = -60
		var fire_mat := ShaderMaterial.new()
		var sh := load(DIR + "title_fire.gdshader") as Shader
		if sh != null:
			fire_mat.shader = sh
			fire_mat.set_shader_parameter("anim", 0.0 if reduced else 1.0)
			p.material = fire_mat
		root.add_child(p)

	# ── Layer 2: authored sprites, each animated by kind. ──
	for group in [[CLOTH, -50], [PROPS, -45], [VESSELS, -40], [OVERLAYS, -30]]:
		var entries: Array = group[0]
		var z: int = group[1]
		for e in entries:
			var tex := _tex(e[0])
			if tex == null:
				continue                     # asset not delivered yet — skip, do not error
			var node := _place(root, tex, e[1], z)
			if reduced:
				continue
			match e[2]:
				"sway":
					_sway(node, rng.randf_range(5.5, 7.5), rng.randf_range(0.0, TAU))
				"pendulum":
					_pendulum(node, rng.randf_range(3.4, 4.6), rng.randf_range(0.0, TAU))
				"shaft":
					node.material = _additive()
					_breathe(node, rng.randf_range(9.0, 13.0))
				"drift":
					node.material = _additive()
					node.modulate.a = 0.22
					_drift(node, rng.randf_range(40.0, 70.0))

	# ── Layer 3: light. Warm glow at every fire, flickering out of step. ──
	for i in FIRES.size():
		var g := _glow(root, FIRES[i], host.size)
		if not reduced:
			_flicker(g, rng.randf_range(2.6, 4.2), rng.randf_range(0.0, TAU))

	# ── Layer 4: camera. 2-3px of idle drift and a breathing zoom — almost imperceptible. ──
	if not reduced:
		_camera_life(root)
	return root


# ── Animations ───────────────────────────────────────────────────────────────
# All of them are LOW amplitude on purpose: the brief is Elden Ring, not an animated wallpaper.
# Every one is a looping tween, so nothing needs _process and the whole rig frees cleanly.

static func _sway(n: Control, period: float, phase: float) -> void:
	n.pivot_offset = Vector2(n.size.x * 0.5, 0.0)      # cloth hangs from its rod
	n.rotation = deg_to_rad(-0.5)
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(phase * 0.12)
	t.tween_property(n, "rotation", deg_to_rad(0.5), period * 0.5)
	t.tween_property(n, "rotation", deg_to_rad(-0.5), period * 0.5)

static func _pendulum(n: Control, period: float, phase: float) -> void:
	n.pivot_offset = Vector2(n.size.x * 0.5, 0.0)      # swings from where the chain meets the roof
	n.rotation = deg_to_rad(-0.8)
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_interval(phase * 0.1)
	t.tween_property(n, "rotation", deg_to_rad(0.8), period * 0.5)
	t.tween_property(n, "rotation", deg_to_rad(-0.8), period * 0.5)

static func _breathe(n: Control, period: float) -> void:
	var a := n.modulate.a
	var t := n.create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(n, "modulate:a", a * 0.72, period * 0.5)
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
	t.tween_property(n, "modulate:a", a * 1.04, period * 0.29)
	t.tween_property(n, "modulate:a", a, period * 0.34)

static func _camera_life(root: Control) -> void:
	# The whole environment drifts a couple of pixels and breathes a fraction of a percent. Below
	# the threshold of notice frame to frame; felt over half a minute.
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
	# A soft warm pool. Light2D cannot reach Control nodes (TD-047), so the glow is an additive
	# radial sprite — the same call the board's torches make.
	var g := TextureRect.new()
	g.texture = _radial()
	g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	g.stretch_mode = TextureRect.STRETCH_SCALE
	g.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.material = _additive()
	g.modulate = Color(1.0, 0.72, 0.36, 0.30)
	var r := vp.x * 0.10
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
