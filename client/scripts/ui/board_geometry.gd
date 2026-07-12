extends RefCounted
## Contract Board — pure geometry & layout math (extracted from main.gd for organization).
##
## Everything here is a PURE function of its inputs (no scene state, no side effects on
## nodes): the board's inner size, the keep-out grid solver, seeded jitter/tilt/tints, and
## the runtime vignette/additive resources. Consumed via preload as `BoardGeo` (TD-029/30
## convention, no global class_name). Determinism (same seed -> same board) lives here.

# ── Layout constants (fractions of the board's inner canvas) ─────────────────────
# Live-notice anchor centres — legacy scatter anchors (grid layout in layout_live()
# supersedes them; kept for reference/flavor tooling).
const LIVE_SLOTS := [Vector2(0.16, 0.30), Vector2(0.52, 0.19), Vector2(0.34, 0.76), Vector2(0.83, 0.58)]
const FLAVOR_SLOTS := [Vector2(0.63, 0.16), Vector2(0.88, 0.30), Vector2(0.11, 0.58), Vector2(0.52, 0.87), Vector2(0.82, 0.83), Vector2(0.94, 0.56)]
# Grid composition (Prototype-v1): flavor scraps pinned in the side margins, clear of
# the centred grid and the torches — a couple of aged notes, not a scatter.
const FLAVOR_SIDE_SLOTS := [Vector2(0.045, 0.24), Vector2(0.955, 0.78), Vector2(0.05, 0.80)]
# Live/flavor sizes as FRACTIONS of the inner canvas (must read at 640x360 and any
# logical viewport PixelScale hands us). Purely aesthetic — size never encodes tier.
const LIVE_SIZE_FRACS := [Vector2(0.185, 0.455), Vector2(0.160, 0.380), Vector2(0.196, 0.350),
	Vector2(0.150, 0.365), Vector2(0.176, 0.420), Vector2(0.146, 0.335)]
const FLAVOR_SIZE_FRACS := [Vector2(0.120, 0.300), Vector2(0.105, 0.270), Vector2(0.145, 0.230),
	Vector2(0.115, 0.310), Vector2(0.100, 0.250), Vector2(0.150, 0.260)]
# Reserved bands: the hanging placard along the top, the flanking torch margin down each side.
const TOP_RESERVE_FRAC := 0.20
const SIDE_RESERVE_FRAC := 0.03
# Aged-parchment tints, seeded per notice — warm variety without encoding anything.
const PARCH_TINTS := [
	Color(0.99, 0.92, 0.74), Color(0.97, 0.84, 0.58), Color(0.94, 0.76, 0.52),
	Color(0.91, 0.82, 0.66), Color(0.89, 0.73, 0.60), Color(0.96, 0.88, 0.68),
]

# ── Board frame + reserved bands ─────────────────────────────────────────────────
# The wooden board is INSET into the stone wall: its content is a fraction of the
# viewport, centred, leaving ~13% of stone on each flank and a slim band top/bottom.
static func inner_size(vp: Vector2) -> Vector2:
	return Vector2(vp.x * 0.74, vp.y * 0.80).max(Vector2(320, 180))

# Height of the bottom legend / active-assignment bar (LOGICAL px; board is ~288 tall
# at 640x360 @ int-scale): ~74 keeps the 4-row legend + 3-row status legible.
static func bar_height(inner: Vector2) -> float:
	return maxf(74.0, inner.y * 0.25)

# A modest routed plaque like Prototype v1 (~⅖ width), hung below the crest.
static func placard_rect(inner: Vector2) -> Rect2:
	var w := clampf(inner.x * 0.42, 150.0, maxf(150.0, inner.x - 40.0))
	var h := maxf(20.0, inner.y * 0.078)
	return Rect2(((inner.x - w) * 0.5), inner.y * 0.13, w, h).abs()

# The live-notice bounds: below the placard, inside the side reserves, above the bar.
static func live_bounds(inner: Vector2) -> Rect2:
	var side := inner.x * SIDE_RESERVE_FRAC
	var top := placard_rect(inner).end.y + 8.0
	var reserve := bar_height(inner) + 16.0
	return Rect2(side, top, inner.x - side * 2.0, maxf(40.0, inner.y - top - reserve))

# ── Notice sizing / footprint ────────────────────────────────────────────────────
# Snap to whole pixels: a parchment on a half-pixel is a blurred parchment (Nearest).
static func notice_size(fracs: Array, i: int, inner: Vector2) -> Vector2:
	return (Vector2(fracs[i % fracs.size()]) * inner).floor()

# Axis-aligned footprint of a `size` rect rotated by `tilt` degrees about its centre.
static func rotated_extent(size: Vector2, tilt: float) -> Vector2:
	var c := absf(cos(deg_to_rad(tilt)))
	var s := absf(sin(deg_to_rad(tilt)))
	return Vector2(size.x * c + size.y * s, size.x * s + size.y * c)

# ── Keep-out solver (T145): no live petition may bury another ────────────────────
static func clamp_rect(r: Rect2, bounds: Rect2) -> Rect2:
	r.position.x = clampf(r.position.x, bounds.position.x, maxf(bounds.position.x, bounds.end.x - r.size.x))
	r.position.y = clampf(r.position.y, bounds.position.y, maxf(bounds.position.y, bounds.end.y - r.size.y))
	return r

static func all_disjoint(rects: Array, pad: float) -> bool:
	for a in rects.size():
		for b in range(a + 1, rects.size()):
			if (rects[a] as Rect2).grow(pad).intersects(rects[b]):
				return false
	return true

# Push overlapping rects apart along their centre-to-centre axis until disjoint.
static func separate(rects: Array, bounds: Rect2, pad: float, iters: int = 64) -> bool:
	for _i in iters:
		if all_disjoint(rects, pad):
			return true
		for a in rects.size():
			for b in range(a + 1, rects.size()):
				var ra: Rect2 = rects[a]
				var rb: Rect2 = rects[b]
				if not ra.grow(pad).intersects(rb):
					continue
				var axis := rb.get_center() - ra.get_center()
				if axis.length() < 0.001:
					axis = Vector2(1.0, 0.3)
				var push := axis.normalized() * 2.0
				rects[a] = clamp_rect(Rect2(ra.position - push, ra.size), bounds)
				rects[b] = clamp_rect(Rect2(rb.position + push, rb.size), bounds)
	return all_disjoint(rects, pad)

# Lay out the live notices as a clean, framed GRID (Prototype-v1 composition): cells
# centred in the live bounds, each card a portrait rect inset in its cell. Disjoint by
# construction, so the keep-out self-check always passes. Returns [{centre, size}, ...].
static func layout_live(board: Array, inner: Vector2) -> Array:
	var bounds := live_bounds(inner)
	var n: int = mini(board.size(), 8)   # canonical BOARD_SIZE=8 (TD-045)
	if n == 0:
		return []
	var cols: int = mini(4, n)
	var rows: int = int(ceil(n / float(cols)))
	var gap := maxf(10.0, bounds.size.x * 0.018)
	var cell_w := (bounds.size.x - gap * (cols - 1)) / float(cols)
	var cell_h := (bounds.size.y - gap * (rows - 1)) / float(rows)
	var cw := floorf(cell_w * 0.90)
	var ch := floorf(cell_h * 0.98)
	var out: Array = []
	for idx in n:
		var r: int = idx / cols
		var c: int = idx % cols
		var in_row: int = mini(cols, n - r * cols)                 # centre a short last row
		var row_w := in_row * cell_w + (in_row - 1) * gap
		var x0 := bounds.position.x + (bounds.size.x - row_w) * 0.5
		var cx := x0 + c * (cell_w + gap) + cell_w * 0.5
		var cy := bounds.position.y + r * (cell_h + gap) + cell_h * 0.5
		out.append({"centre": Vector2(cx, cy), "size": Vector2(cw, ch)})
	return out

# ── Seeded aesthetics (deterministic per contractId) ─────────────────────────────
static func seed_jitter(seed_str: String) -> Vector2:
	var jx := float(absi((seed_str + "|jx").hash()) % 100) / 100.0 - 0.5
	var jy := float(absi((seed_str + "|jy").hash()) % 100) / 100.0 - 0.5
	return Vector2(jx, jy) * 0.06

# A seeded hang angle (degrees), ~ -6.5°..+6.5°.
static func seed_tilt(seed_str: String) -> float:
	return float(absi((seed_str + "|tilt").hash()) % 1300) / 100.0 - 6.5

static func parch_tint(seed_str: String) -> Color:
	return PARCH_TINTS[absi((seed_str + "|tint").hash()) % PARCH_TINTS.size()]

# ── Runtime render resources (no PNG import) ─────────────────────────────────────
static func additive_material() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

# Paper curl: a soft inner shadow that fades UP from the sheet's bottom edge — the foot
# of the paper lifts off the wall and shades itself, so a notice never reads dead-flat.
static func curl_gradient() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([
		Color(0.05, 0.03, 0.02, 0.0),
		Color(0.05, 0.03, 0.02, 0.10),
		Color(0.04, 0.025, 0.015, 0.34)])
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill = GradientTexture2D.FILL_LINEAR
	gt.fill_from = Vector2(0.5, 0.0)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 8
	gt.height = 16
	return gt

# Wood-age grain: a small tiling dark-speckle/streak overlay so the plank backing reads as
# aged and used, not a flat stretched slab. Runtime ImageTexture (no PNG import); laid over
# the backing at low alpha, tiled. Horizontal streaks follow the plank grain.
static func wood_grain_texture() -> ImageTexture:
	var W := 96
	var H := 96
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	for y in H:
		# a per-row streak bias so grain runs along the (horizontal) planks
		var row := absi((y * 2654435761) & 0xFFFF) % 1000 / 1000.0
		for x in W:
			var n := absi(((x * 374761393) ^ (y * 668265263)) & 0xFFFFFFFF) % 1000 / 1000.0
			var a := 0.0
			if n > 0.90:                       # sparse dark specks (wormholes, knots)
				a = 0.16 * (n - 0.90) / 0.10
			a += 0.055 * row * clampf((n - 0.3) / 0.6, 0.0, 1.0)   # faint lengthwise streaking
			img.set_pixel(x, y, Color(0.03, 0.018, 0.010, minf(a, 0.20)))
	return ImageTexture.create_from_image(img)

# A rect is "clear" when no live footprint intersects it — decay may only sit in space
# no petition claims (DESIGN binds cobweb/votive to empty corners).
static func decay_clear(rect: Rect2, footprints: Array) -> bool:
	for fp in footprints:
		if (fp as Rect2).intersects(rect):
			return false
	return true

# A radial warm-dark vignette: clear at the centre, dark at the corners — the torch-lit
# pool that gives the board its Prototype-v1 ambience.
static func vignette_gradient() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.66, 1.0])
	grad.colors = PackedColorArray([
		Color(0.03, 0.02, 0.012, 0.0),
		Color(0.028, 0.018, 0.010, 0.12),
		Color(0.02, 0.013, 0.007, 0.42)])   # gutters keep their lit wood — v1 is warm, not crushed black
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 320
	gt.height = 200
	return gt
