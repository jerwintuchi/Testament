extends Node
## Pixel-perfect integer scaling that fills any screen. Render-only (I1/I2).
##
## Godot's `stretch/aspect="expand"` sizes the logical viewport from the
## *fractional* scale, then `scale_mode="integer"` floors the draw scale. The
## leftover shows as black bars — measured 444x204 on a 2778x1284 phone screen.
##
## So we choose the integer factor ourselves, then size the viewport to
## `window / factor`. The draw scale is then exactly that integer (crisp pixels,
## the art canon) and the viewport covers the whole window (no bars, any device).
##
## The trade: a wider or taller screen sees *more area*, not bigger pixels. That
## is the correct behaviour for a pixel game, but it means UI must be anchored and
## the field camera may want a clamp — see docs/technical/dev-environment.md.

const BASE := Vector2i(640, 360)

# A very wide screen would otherwise reveal an unbounded slice of the field. Cap
# the logical area; beyond this the extra window space becomes (small) bars again.
const MAX_LOGICAL := Vector2i(1280, 720)

var _applying := false

func _ready() -> void:
	get_tree().root.size_changed.connect(_apply)
	_apply()

func _apply() -> void:
	if _applying:
		return
	_applying = true
	var win := DisplayServer.window_get_size()
	# Integer division floors: the largest whole factor at which BASE still fits.
	var factor: int = maxi(1, mini(win.x / BASE.x, win.y / BASE.y))
	var logical := Vector2i(win.x / factor, win.y / factor)
	logical.x = clampi(logical.x, BASE.x, MAX_LOGICAL.x)
	logical.y = clampi(logical.y, BASE.y, MAX_LOGICAL.y)
	var window := get_window()
	window.content_scale_size = logical
	if OS.is_debug_build():
		print("[pixelscale] win=%dx%d factor=%d -> content_scale_size=%dx%d (actual %dx%d)" % [
			win.x, win.y, factor, logical.x, logical.y,
			window.content_scale_size.x, window.content_scale_size.y])
	_applying = false

## The logical viewport a given window size resolves to. Pure; used by tooling.
static func logical_for(win: Vector2i) -> Vector2i:
	var factor: int = maxi(1, mini(win.x / BASE.x, win.y / BASE.y))
	return Vector2i(
		clampi(win.x / factor, BASE.x, MAX_LOGICAL.x),
		clampi(win.y / factor, BASE.y, MAX_LOGICAL.y))
