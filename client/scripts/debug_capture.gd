extends Node
## Dev-only frame capture. Render-only: it reads the viewport and writes a PNG.
## It never touches game state, sends no message, and is inert in an export build
## (writing to `res://` only works in a debug/editor run) — I1/I2 hold.
##
##   F12                             save one frame now
##   godot ... -- --capture=2        save one frame after 2s, then quit
##   godot ... -- --capture=2 --capture-fullscreen   ... at the screen's size
##
## An unattended capture forces a 960x540 window first, so the PNG is always the
## base viewport and never the size of whatever monitor happened to run it. The
## engine's own `--windowed`/`--resolution` flags cannot do this: the project sets
## `window/size/mode=3` (fullscreen), which overrides them. F12 captures whatever
## is on screen, untouched.
##
## `res://` resolves inside the WSL working tree even when the Windows Godot
## binary opens this project over its UNC path, so captures land in the repo
## where they can be read back. See docs/technical/dev-environment.md.

const CAPTURE_DIR := "res://.captures"
# 2x the 640x360 base (TD-042), so an unattended capture resolves to an integer factor of
# exactly 2 and the PNG *is* the logical viewport — 640x360, one image pixel per game pixel.
const BASE_SIZE := Vector2i(1280, 720)

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(CAPTURE_DIR)
	var delay := _capture_delay()
	if delay <= 0.0:
		return
	if not _has_user_arg("--capture-fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_capture_size())
	await get_tree().create_timer(delay).timeout
	await _capture("auto")
	get_tree().quit()

func _has_user_arg(name: String) -> bool:
	return OS.get_cmdline_user_args().has(name)

# `--capture-size=1600x900` fakes an arbitrary screen so stretch/aspect behaviour
# can be measured without owning the monitor.
func _capture_size() -> Vector2i:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-size="):
			var parts := arg.trim_prefix("--capture-size=").split("x")
			if parts.size() == 2:
				return Vector2i(int(parts[0]), int(parts[1]))
	return BASE_SIZE

# Only user args (after a bare `--`) are read: Godot rejects unknown engine args.
func _capture_delay() -> float:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			return arg.trim_prefix("--capture=").to_float()
	return 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode == KEY_F12:
		await _capture("f12")
		get_viewport().set_input_as_handled()

func _capture(tag: String) -> void:
	# The viewport texture is only valid once the frame has actually been drawn.
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s-%d.png" % [CAPTURE_DIR, tag, Time.get_ticks_msec()]
	var err := image.save_png(path)
	print("[capture] %s err=%d %dx%d" % [path, err, image.get_width(), image.get_height()])
	# Logical viewport: with aspect=keep it stays at BASE_SIZE; with aspect=expand it
	# grows on an aspect mismatch, which is exactly the "more visible area" trade.
	#
	# The capture is the ROOT VIEWPORT, not the window framebuffer — letterbox bars
	# are drawn outside it and can never appear in a PNG. Infer them instead: the
	# integer render scale is floor(min(win/logical)), and any window pixels beyond
	# logical*scale are bar.
	var logical := get_viewport().get_visible_rect().size
	var win := DisplayServer.window_get_size()
	var scale: int = maxi(1, mini(int(win.x / maxf(logical.x, 1.0)), int(win.y / maxf(logical.y, 1.0))))
	var bar := Vector2i(win.x - logical.x * scale, win.y - logical.y * scale)
	print("[capture] window=%dx%d logical=%dx%d int_scale=%d bars=%dx%d" % [
		win.x, win.y, logical.x, logical.y, scale, bar.x, bar.y])
