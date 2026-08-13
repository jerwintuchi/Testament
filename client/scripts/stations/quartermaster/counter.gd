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
const Room    := preload("res://scripts/stations/quartermaster/room.gd")

const ICON_PX := 24

# The brief's timings (§7): lift 80–120ms, carry 250–400ms, settle 100–150ms. Eased
# as an object being handled — a QUAD lift, a CUBIC carry, and a small BACK settle so
# it lands with weight rather than stopping dead.
const T_LIFT   := 0.11
const T_CARRY  := 0.32
const T_SETTLE := 0.13
const LIFT_H   := 9.0


## The resting place for the inspected object: on the ALTAR CLOTH, derived from the
## cloth's own rect (TD-110/P176). Deriving rather than declaring is what stops the
## instrument landing beside the cloth it is supposed to be set down on — the same
## mistake the candle and its light made in TD-105.
## The cloth still decides WHERE across the counter (it is the surface, P176); the
## counter's top plane now decides HOW HIGH. The old offset put the instrument's feet
## below the arris, i.e. standing on the counter's front face — invisible while the
## counter was a flat rectangle, wrong the moment it gained planes (TD-112).
static func rest_point(counter_rect: Rect2) -> Vector2:
	var cloth := Room.cloth_rect(counter_rect)
	return Vector2(cloth.position.x + cloth.size.x * 0.5 - ICON_PX * 0.5,
		Room.counter_stand_y(counter_rect) - ICON_PX)


## Builds the mat the instrument is set down on — a small leather square, so the
## surface reads as a place to put something rather than as empty wood.
static func build(host: Control, counter_rect: Rect2) -> Dictionary:
	var at := rest_point(counter_rect)
	# No mat: the altar cloth IS the surface now (TD-110), drawn by the room, so a
	# second rectangle under the instrument would be a mat laid on a cloth.
	# THE DECISION LIVES ON THE BENCH NOW (TD-120). What stood here was the instrument's
	# NAME, and the name is already engraved on the record board's title plate — so the
	# caption was the same word twice while the verb sat across the room, pinned under a
	# document. The verb belongs beside the object it acts on.
	# A CenterContainer, so the verb sits UNDER the instrument rather than at the far end
	# of the bench. A plain Control would leave the button at its own origin, which is
	# what put "Pack it" against the left wall on the first pass.
	var act_host := CenterContainer.new()
	act_host.position = Vector2(counter_rect.position.x,
		Room.cloth_rect(counter_rect).end.y + 3.0)
	act_host.size = Vector2(counter_rect.size.x, 20.0)
	host.add_child(act_host)

	# The counter's own contact shadow. The shelf shadow travels with the object only
	# in the sense that it is switched OFF — so until now an instrument on the counter
	# cast nothing at all, and floated on the cloth. This one lives on the counter and
	# is re-textured per instrument, so the shadow always describes the silhouette
	# standing in it (the P173 rule, applied to the second surface).
	#
	# It is WIDER and SHORTER than the shelf's: the counter's top plane recedes, and a
	# shadow cast across a receding plane foreshortens away from the eye rather than
	# falling straight down as it does on the near edge of a shelf board.
	var cshadow := TextureRect.new()
	cshadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	cshadow.stretch_mode = TextureRect.STRETCH_SCALE
	cshadow.position = Vector2(at.x - 2.0, Room.counter_stand_y(counter_rect) - 1.0)
	cshadow.size = Vector2(ICON_PX + 4.0, 3.0)
	cshadow.modulate = Color(1, 1, 1, 0.72)
	cshadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cshadow.visible = false
	host.add_child(cshadow)

	return {"action_host": act_host, "rest": at, "holding": "", "shadow": cshadow}


## Carries `rec`'s object from wherever it stands to the counter. `done` fires when it
## settles, so the record fills as the object lands rather than before it moves.
static func carry_in(view: Dictionary, rec: Dictionary, reduced: bool, done: Callable) -> void:
	var node: Control = rec["node"]
	var shadow: Control = rec["shadow"]
	var target: Vector2 = view["rest"]

	# The object leaves its shelf, so the shelf's contact shadow goes with it — and the
	# counter's own takes over, wearing this instrument's silhouette.
	shadow.visible = false
	node.z_index = 4                     # over the counter and its props while handled
	var cshadow: Control = view.get("shadow")
	if cshadow != null:
		cshadow.texture = shadow.texture
		cshadow.visible = true

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
## `view` is optional only so existing call sites keep working; pass it whenever the
## object is leaving the COUNTER, or the counter's contact shadow is left behind
## describing an instrument that is no longer standing there.
static func carry_out(rec: Dictionary, reduced: bool, done: Callable = Callable(),
		view: Dictionary = {}) -> void:
	var node: Control = rec["node"]
	var shadow: Control = rec["shadow"]
	var home: Vector2 = rec["home"]
	var cshadow: Control = view.get("shadow")
	if cshadow != null:
		cshadow.visible = false

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


## Retired with the caption it set (TD-120): the record board's plate carries the name.
