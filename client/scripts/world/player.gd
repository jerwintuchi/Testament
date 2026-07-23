class_name Player
extends Node2D
## Server-driven party puppet + reusable directional-animation component (R103).
##
## The trust boundary on the client side: `target` (feet px) is set ONLY from a
## server message (main.gd `_apply_positions`) — never from local input, and there
## is no physics/`move_and_slide` here (R104/R108/P54). `_process` only smooths the
## drawn position toward the server target and derives *facing/state* from that
## server motion, then plays the matching clip.
##
## Animation is a plain `AnimatedSprite2D.play("<state>_<dir>")` — the scalable
## pattern for discrete 4-directional pixel art (see specs/collegium-client). The
## SpriteFrames are built from the config below, so a future NPC/Incarnate reuses
## this script with a different sheet set (data-driven; no per-entity anim graphs).

# ── Animation config (data — swap these for another actor) ───────────────────
const FRAME := 64
const IDLE_FPS := 6.0   # idles read calmer slow; also keeps the short (4-frame) north idle from racing
const WALK_FPS := 9.0
const RUN_FPS := 12.0   # run cycles faster than walk
const IDLE_SHEET := preload("res://assets/entities/player/Unarmed_Idle_with_shadow.png")
const WALK_SHEET := preload("res://assets/entities/player/Unarmed_Walk_with_shadow.png")
const RUN_SHEET := preload("res://assets/entities/player/Unarmed_Run_with_shadow.png")
# Max columns per row; fully-transparent cells are skipped at build time, so a
# ragged sheet (e.g. idle north = 4 real frames of 12) yields no blank frames.
const IDLE_COLS := 12
const WALK_COLS := 6
const RUN_COLS := 8
# Sheet row (y = row * FRAME) per facing. Verified/adjusted visually.
const DIR_ROW := {"south": 0, "west": 1, "east": 2, "north": 3}
const MOVE_HOLD := 0.12   # keep the move clip this long after the last position delta (bridges the 20 Hz gaps)
# px/s at which the run clip replaces the walk clip. It is the midpoint of the
# server's two registers (WALK_SPEED 40, SEEKER_SPEED 80), and it is compared
# against a speed *estimated from the server's own motion* — so the animation
# reflects the authoritative register, never local input (the client never knows
# a remote teammate's shift key, only how fast the server is moving their body).
const RUN_ANIM_THRESHOLD := 60.0
# Interpolation stiffness (1/s): frame-rate-independent exponential smoothing of
# the drawn position toward the server target. Higher = snappier, less trailing.
# ~22 → a ~45 ms time constant: smooths the 20 Hz/4 px server steps without the
# sluggish lag a slow lerp gives. Pure visual interpolation, never prediction.
const SMOOTH_K := 22.0

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _name: Label = $Name

var target := Vector2.ZERO
var is_self := false
var label_text := ""

var _facing := "south"
var _prev_target := Vector2.ZERO
var _move_hold := 0.0
var _speed_est := 0.0        # px/s, estimated from the gap between server position updates
var _time_since_move := 0.0  # s since the last server position update (for that estimate)

func setup(feet_px: Vector2, self_flag: bool, name_text: String) -> void:
	target = feet_px
	position = feet_px
	_prev_target = feet_px
	is_self = self_flag
	label_text = name_text
	if is_node_ready():
		_refresh()

func _ready() -> void:
	_sprite.sprite_frames = _build_frames()
	_refresh()
	_sprite.play("idle_south")

func _refresh() -> void:
	_name.text = label_text
	_name.modulate = Color(1.0, 0.9, 0.55) if is_self else Color(0.8, 0.85, 0.95)

func _process(delta: float) -> void:
	# Facing, register (walk/run) and move-state all come from server motion (the
	# change in target over time), never from local input.
	_time_since_move += delta
	var step := target - _prev_target
	if step.length() > 0.5:                       # a server position update landed
		_facing = _facing_from(step)
		_move_hold = MOVE_HOLD
		if _time_since_move > 0.0:                # px moved / time since the last update = px/s
			_speed_est = lerpf(_speed_est, step.length() / _time_since_move, 0.4)
		_time_since_move = 0.0
	_prev_target = target
	_move_hold = maxf(0.0, _move_hold - delta)
	if _move_hold > 0.0:
		_play("run" if _speed_est >= RUN_ANIM_THRESHOLD else "walk")
	else:
		_play("idle")
	position = position.lerp(target, 1.0 - exp(-SMOOTH_K * delta))

func _facing_from(v: Vector2) -> String:
	# Diagonals face east/west (horizontal reads best); face north/south only when
	# the movement is essentially vertical. The server sends 8 discrete directions,
	# so any real horizontal component is unambiguous — no jitter, no hysteresis.
	if absf(v.x) > 0.5:
		return "east" if v.x > 0.0 else "west"
	return "south" if v.y > 0.0 else "north"

func _play(state: String) -> void:
	var anim := "%s_%s" % [state, _facing]
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)

# Build idle_<dir> / run_<dir> clips by slicing each sheet's direction row into
# FRAME-sized AtlasTextures. Data-in, SpriteFrames-out — no hand-authored .tres.
func _build_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	var idle_img := IDLE_SHEET.get_image()
	var walk_img := WALK_SHEET.get_image()
	var run_img := RUN_SHEET.get_image()
	for dir in DIR_ROW:
		var row: int = DIR_ROW[dir]
		_add_clip(sf, "idle_%s" % dir, IDLE_SHEET, idle_img, row, IDLE_COLS, IDLE_FPS)
		_add_clip(sf, "walk_%s" % dir, WALK_SHEET, walk_img, row, WALK_COLS, WALK_FPS)
		_add_clip(sf, "run_%s" % dir, RUN_SHEET, run_img, row, RUN_COLS, RUN_FPS)
	return sf

func _add_clip(sf: SpriteFrames, clip: String, sheet: Texture2D, img: Image, row: int, max_cols: int, fps: float) -> void:
	sf.add_animation(clip)
	sf.set_animation_loop(clip, true)
	sf.set_animation_speed(clip, fps)
	for col in max_cols:
		if _cell_blank(img, col * FRAME, row * FRAME):
			continue  # ragged sheet: skip fully-transparent cells
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(col * FRAME, row * FRAME, FRAME, FRAME)
		sf.add_frame(clip, at)

func _cell_blank(img: Image, x0: int, y0: int) -> bool:
	# Sample every 2px (content is ≥15px wide, so this never misses a real frame).
	for y in range(y0, y0 + FRAME, 2):
		for x in range(x0, x0 + FRAME, 2):
			if img.get_pixel(x, y).a > 0.03:
				return false
	return true
