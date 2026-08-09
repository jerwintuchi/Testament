extends RefCounted
## The inspection counter — where a chosen instrument is set down (TD-101).
##
## The heart of the interaction (brief §8): selecting does not highlight a row, it
## brings the object here. The counter owns the CARRY — lifting an instrument off its
## shelf, moving it across, and settling it on the surface — and the return journey
## when a different one is chosen.
##
## It holds one object at a time. Choosing a second returns the first to its exact
## shelf position first; nothing is ever destroyed to make room, because an object
## that vanished would break the physical illusion the whole redesign rests on.

const Widgets := preload("res://scripts/ui/widgets.gd")

const ICON_PX := 24

# The brief's timings (§7): lift 80–120ms, carry 250–400ms, settle 100–150ms. Eased
# as an object being handled — a QUAD lift, a CUBIC carry, and a small BACK settle so
# it lands with weight rather than stopping dead.
const T_LIFT   := 0.11
const T_CARRY  := 0.32
const T_SETTLE := 0.13
const LIFT_H   := 9.0


## The resting place for the inspected object: centred on the counter's surface,
## standing on it rather than floating over it.
static func rest_point(counter_rect: Rect2) -> Vector2:
	return Vector2(
		counter_rect.position.x + counter_rect.size.x * 0.5 - ICON_PX * 0.5,
		counter_rect.position.y + 4.0)


## Builds the mat the instrument is set down on — a small leather square, so the
## surface reads as a place to put something rather than as empty wood.
static func build(host: Control, counter_rect: Rect2) -> Dictionary:
	var at := rest_point(counter_rect)
	# Leather, not a void. At near-black it read as a hole punched in the counter
	# rather than as something laid on it.
	var mat := ColorRect.new()
	mat.color = Color(0.22, 0.15, 0.10, 0.72)
	mat.position = Vector2(at.x - 8.0, at.y + 2.0)
	mat.size = Vector2(ICON_PX + 16.0, ICON_PX - 2.0)
	mat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(mat)

	var caption := Widgets.card_label("", 8, Color(0.70, 0.62, 0.46), false, true)
	caption.position = Vector2(counter_rect.position.x, counter_rect.position.y + counter_rect.size.y - 14.0)
	caption.size = Vector2(counter_rect.size.x, 10.0)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(caption)

	return {"mat": mat, "caption": caption, "rest": at, "holding": ""}


## Carries `rec`'s object from wherever it stands to the counter. `done` fires when it
## settles, so the record fills as the object lands rather than before it moves.
static func carry_in(view: Dictionary, rec: Dictionary, reduced: bool, done: Callable) -> void:
	var node: Control = rec["node"]
	var shadow: Control = rec["shadow"]
	var target: Vector2 = view["rest"]

	# The object leaves its shelf, so the shelf's contact shadow goes with it.
	shadow.visible = false
	node.z_index = 4                     # over the counter and its props while handled

	if reduced:
		node.position = target
		done.call()
		return

	var tw := node.create_tween()
	tw.tween_property(node, "position", node.position + Vector2(0, -LIFT_H), T_LIFT) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position", target + Vector2(0, -LIFT_H * 0.6), T_CARRY) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position", target, T_SETTLE) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func(): done.call())


## Returns an object to its exact shelf position. The same journey, reversed — an
## instrument that blinked back would undo the physicality the carry just established.
static func carry_out(rec: Dictionary, reduced: bool, done: Callable = Callable()) -> void:
	var node: Control = rec["node"]
	var shadow: Control = rec["shadow"]
	var home: Vector2 = rec["home"]

	var land := func():
		node.z_index = 0
		shadow.visible = true
		if done.is_valid():
			done.call()

	if reduced:
		node.position = home
		land.call()
		return

	var tw := node.create_tween()
	tw.tween_property(node, "position", node.position + Vector2(0, -LIFT_H), T_LIFT) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "position", home + Vector2(0, -LIFT_H * 0.6), T_CARRY) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "position", home, T_SETTLE) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.finished.connect(land)


## What the counter says under the object. Empty when nothing is set down.
static func set_caption(view: Dictionary, text: String) -> void:
	(view["caption"] as Label).text = text
