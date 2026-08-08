extends RefCounted
## Sealing the pack — the commitment beat.
##
## Deliberately built from the pieces the Contract Board's seal ceremony already
## established (TD-063): the clasp is pressed, wax is set on it, and a banner names
## what was done. Reusing that vocabulary is the point — a Seeker who has sealed a
## contract should recognise this as the same gesture.
##
## What it does NOT claim: this is not deployment. Requisition stays reversible until
## the leader deploys at the Deploy Gate, which is a server phase gate. The banner
## says the pack is sealed, because that is what happened.

const RiteBanner := preload("res://scripts/ui/rite_banner.gd")
const WaxSeal    := preload("res://scripts/board/wax_seal.gd")

const SEAL_TEX := "res://assets/ui/board/seal_collegium.png"
const SEAL_PX  := 34

# The board's own press: a slow fall, then a heavy BACK settle. Same numbers, so the
# two ceremonies feel like one hand.
const T_FALL   := 0.30
const T_SETTLE := 0.28


## Presses the Collegium's seal onto the pack's clasp, raises the rite banner, then
## calls `done`. Under reduced motion the end state is rendered with no movement —
## the commitment still happens, it simply is not performed.
static func press(host: Node, pack_view: Dictionary, reduced: bool, done: Callable) -> void:
	var clasp: Control = pack_view.get("clasp")
	if clasp == null:
		_banner(host, reduced)
		done.call()
		return

	var lay := CanvasLayer.new()
	lay.layer = 97
	host.add_child(lay)

	var wax := TextureRect.new()
	wax.texture = load(SEAL_TEX) as Texture2D
	wax.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	wax.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wax.size = Vector2(SEAL_PX, SEAL_PX)
	wax.pivot_offset = wax.size * 0.5
	wax.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wax.position = clasp.get_global_rect().get_center() - wax.size * 0.5
	lay.add_child(wax)

	if reduced:
		_banner(host, true)
		done.call()
		# The seal stays on the clasp for a moment so the state is legible, then goes.
		host.get_tree().create_timer(1.2).timeout.connect(func(): lay.queue_free())
		return

	wax.scale = Vector2(2.1, 2.1)
	wax.modulate.a = 0.0
	var tw := lay.create_tween()
	tw.tween_property(wax, "modulate:a", 1.0, 0.10)
	tw.parallel().tween_property(wax, "scale", Vector2.ONE, T_FALL).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(wax, "scale", Vector2(1.06, 0.94), 0.06)     # the squash of a press
	tw.tween_property(wax, "scale", Vector2.ONE, T_SETTLE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.finished.connect(func():
		_banner(host, false)
		done.call()
		host.get_tree().create_timer(1.1).timeout.connect(func(): lay.queue_free()))


static func _banner(host: Node, reduced: bool) -> void:
	# "PACK SEALED", not "EXPEDITION BEGUN" — the pack is what was committed here.
	RiteBanner.show(host, "PACK SEALED", "the Collegium has issued your instruments", reduced)
