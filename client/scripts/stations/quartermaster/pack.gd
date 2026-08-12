extends RefCounted
## The expedition pack — the one object on the writ that is not paper.
##
## A case with compartments, not an inventory grid: leather over a wood frame, an
## iron rim, a brass clasp and a tied-on label. The slots are RECESSES a thing drops
## into (the art shades the lip so they read as holes), and they are the mechanic —
## bounded capacity is the whole preparation pillar, so the pack states it by being
## the largest object on the sheet rather than by printing a number.
##
## Owns the flight animation: an instrument physically travels from the shelf into a
## compartment. Restrained by design (TD-079's register) and skipped whole under
## reduced motion, which the project honours everywhere.

const Widgets    := preload("res://scripts/ui/widgets.gd")
const PopupTheme := preload("res://scripts/ui/popup_theme.gd")
const Fonts      := preload("res://scripts/ui/fonts.gd")

# The OPEN satchel (TD-107): a closed case says "storage", an open bag says "being
# loaded", which is what this screen is for.
const CASE  := "res://assets/ui/stations/qm_satchel.png"
const SLOT  := "res://assets/ui/stations/pack_slot.png"
const CLASP := "res://assets/ui/stations/pack_clasp.png"
const LABEL := "res://assets/ui/stations/label_strip.png"

const CASE_M  := 18      # 9-slice margins, matching gen_qm_room.py
const SLOT_M  := 12
const LABEL_M := 8
const ICON_PX := 24

# Brief's timings. The flight is the only thing here that moves, and it moves once.
const T_LIFT   := 0.12
const T_FLY    := 0.28
const T_SETTLE := 0.12


static func build(host: Node, slot_count: int) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	host.add_child(root)

	# The plaque, in the shelves' own crimson-and-gold signage so the room speaks one
	# language (TD-110). It replaces the plain strip TD-107 deleted: what was redundant
	# was the WORDS, not the object.
	var plate := Panel.new()
	var psb := StyleBoxTexture.new()
	psb.texture = load("res://assets/ui/stations/qm_label.png") as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		psb.set("texture_margin_" + side, 7.0)
	plate.add_theme_stylebox_override("panel", psb)
	plate.custom_minimum_size = Vector2(0, 13)
	root.add_child(plate)
	var pcap := Widgets.card_label("EXPEDITION PACK", 10, Color(0.78, 0.64, 0.34), false, true)
	pcap.set_anchors_preset(Control.PRESET_FULL_RECT)
	pcap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pcap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(pcap)

	# NO SECOND TITLE STRIP (TD-107). The tally beneath already reads "EXPEDITION PACK — n / 4",
	# so a strip above saying "EXPEDITION PACK" was the same words twice — and the brief
	# is explicit that the scene must not be cluttered. Dropping it also gives the bag
	# the vertical room to show its folded-back flap, which is what makes it read OPEN.

	# A PanelContainer, NOT a Panel. A Panel does not lay out its children, so the
	# anchored column fell back on its own minimum size and rendered OUTSIDE a
	# zero-height panel — the case texture was drawing all along, at no size, while the
	# compartments floated in front of it. A PanelContainer sizes to its child and
	# applies the stylebox's content margins, which is what the insets should have been.
	var case_panel := _nine_container(CASE, CASE_M, 10, 6)
	case_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(case_panel)

	# A PanelContainer takes ONE child, so the case holds a column: the compartments
	# across the top, the clasp beneath them.
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	case_panel.add_child(stack)

	# Compartments run ACROSS, not down. A satchel's slots sit side by side, and a
	# stacked column was also half as tall again as the space the room gives it — it
	# overran the tally and drew the seal through itself.
	var col := HBoxContainer.new()
	col.add_theme_constant_override("separation", 3)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(col)

	var slots: Array = []
	for i in range(slot_count):
		var s := _compartment()
		col.add_child(s)
		slots.append(s)

	# The clasp: the case's closure, and what the seal rite presses. It belongs BELOW
	# the compartments — inside the row it read as a fifth slot, which is worse than
	# not drawing it at all.
	var clasp := TextureRect.new()
	clasp.texture = load(CLASP) as Texture2D
	clasp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	clasp.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	clasp.custom_minimum_size = Vector2(0, 11)
	clasp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(clasp)

	return {"root": root, "case": case_panel, "slots": slots, "clasp": clasp}


## Paints which compartments are occupied. `icon_of(id)` supplies the texture so the
## pack never reaches into the catalog itself.
static func refresh(view: Dictionary, packed: Array, icon_of: Callable, on_remove: Callable) -> void:
	var slots: Array = view["slots"]
	for i in range(slots.size()):
		var slot: Button = slots[i]
		var held: TextureRect = slot.get_node("Held")
		var tag: Label = slot.get_node("Tag")
		var num: Label = slot.get_node("Num")
		num.text = str(i + 1)
		if i < packed.size():
			var id := String(packed[i])
			held.texture = icon_of.call(id)
			held.visible = true
			tag.text = ""
			num.visible = false
			slot.disabled = false
			slot.tooltip_text = "Take it back out of the pack."
			if not slot.pressed.is_connected(on_remove):
				pass
			for c in slot.pressed.get_connections():
				slot.pressed.disconnect(c["callable"])
			slot.pressed.connect(func(): on_remove.call(id))
		else:
			held.texture = null
			held.visible = false
			tag.text = "\u2720"
			num.visible = true
			slot.disabled = true
			slot.tooltip_text = ""
			for c in slot.pressed.get_connections():
				slot.pressed.disconnect(c["callable"])


## Flies an instrument from `from_ctrl` into the next free compartment, then calls
## `done`. Under reduced motion it calls `done` immediately — the state change is the
## point; the flight is only how it is felt.
static func fly_in(host: Node, view: Dictionary, from_ctrl: Control, tex: Texture2D,
		slot_index: int, reduced: bool, done: Callable) -> void:
	var slots: Array = view["slots"]
	if reduced or tex == null or slot_index >= slots.size() or from_ctrl == null:
		done.call()
		return

	var lay := CanvasLayer.new()
	lay.layer = 96            # above the popup, below the pause menu's 128
	host.add_child(lay)
	var ghost := TextureRect.new()
	ghost.texture = tex
	ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	ghost.size = Vector2(ICON_PX, ICON_PX)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lay.add_child(ghost)

	var a := from_ctrl.get_global_rect().get_center() - Vector2(ICON_PX, ICON_PX) * 0.5
	var target: Control = slots[slot_index]
	var b := target.get_global_rect().get_center() - Vector2(ICON_PX, ICON_PX) * 0.5
	ghost.position = a

	var tw := lay.create_tween()
	# Lift, carry, drop: the instrument is picked up before it travels, which is what
	# makes it read as handled rather than teleported.
	tw.tween_property(ghost, "position", a + Vector2(0, -7), T_LIFT).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ghost, "scale", Vector2(1.12, 1.12), T_LIFT)
	tw.tween_property(ghost, "position", b, T_FLY).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(ghost, "scale", Vector2.ONE, T_FLY)
	tw.tween_property(ghost, "modulate:a", 0.0, T_SETTLE)
	tw.finished.connect(func():
		done.call()
		lay.queue_free())


# ── builders ────────────────────────────────────────────────────────────────

## A 9-slice that LAYS OUT its child, with the border inset expressed as the
## stylebox's content margin so the case's brackets and straps are never covered.
static func _nine_container(path: String, margin: int, pad_x: int, pad_y: int) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(margin))
	sb.content_margin_left = float(pad_x)
	sb.content_margin_right = float(pad_x)
	sb.content_margin_top = float(pad_y)
	sb.content_margin_bottom = float(pad_y)
	p.add_theme_stylebox_override("panel", sb)
	return p


static func _nine(path: String, margin: int) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxTexture.new()
	sb.texture = load(path) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(margin))
	p.add_theme_stylebox_override("panel", sb)
	return p


static func _compartment() -> Button:
	# A Button, so a packed instrument can be taken back out by clicking it and so the
	# pack is reachable by keyboard — the shelf and the pack are both focusable columns.
	var b := Button.new()
	b.custom_minimum_size = Vector2(ICON_PX + 6, ICON_PX + 6)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.size_flags_vertical = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_ALL
	var sb := StyleBoxTexture.new()
	sb.texture = load(SLOT) as Texture2D
	for side in ["left", "top", "right", "bottom"]:
		sb.set("texture_margin_" + side, float(SLOT_M))
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("disabled", sb)
	b.add_theme_stylebox_override("hover", sb)
	b.add_theme_stylebox_override("pressed", sb)
	b.add_theme_stylebox_override("focus", Widgets.focus_ring())

	var held := TextureRect.new()
	held.name = "Held"
	held.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	held.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	held.set_anchors_preset(Control.PRESET_FULL_RECT)
	held.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(held)

	# A numeral, so the pack reads as four ISSUED places rather than four blanks. It is
	# drawn under the instrument and hidden when one lands.
	var num := Widgets.card_label("", 10, Color(0.60, 0.52, 0.38, 0.60), false, true)
	num.name = "Num"
	num.set_anchors_preset(Control.PRESET_FULL_RECT)
	num.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(num)

	var tag := Widgets.card_label("\u2720", 10, Color(0.55, 0.48, 0.36, 0.40), false, true)
	tag.name = "Tag"
	tag.set_anchors_preset(Control.PRESET_FULL_RECT)
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	b.add_child(tag)
	return b
