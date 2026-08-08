extends RefCounted
## The Escape menu (TD-085). Preloaded as `PauseMenu`, never a global class_name so a headless
## parse/import resolves it (TD-029/30).
##
## Two idioms now live in this game and the split is deliberate: **a document you fill in is a writ**
## (the join screen, options — parchment, ink, ruled lines), and **a choice you make is a menu row**
## (the title screen, and this). So the pause menu is the title's own language — gilt Cinzel, no
## chrome, the laurel marking the focused line — laid over a dimmed world rather than over the hall.
##
## It exists because there was no way out of the game except closing the window (the author, during
## testing). Two exits, because they are genuinely different acts: leaving the expedition and
## leaving the program.
##
## Render + input only. It reports intent through callbacks and never touches the socket (I1): the
## shell decides that leaving a room means telling the server, because the shell owns the socket.

const Fonts := preload("res://scripts/ui/fonts.gd")
const Widgets := preload("res://scripts/ui/widgets.gd")

# Deep enough that the world RECEDES rather than competing. At 0.72 the Seeker and his name label
# were still bright enough to tangle with the heading, and both are centred, so they always will be
# — the answer is for the hall to step back, not for the menu to dodge it.
const DIM := Color(0.02, 0.015, 0.01, 0.86)


## Build the overlay onto `host` (a full-rect Control on its own layer). Returns the root, which the
## caller frees to dismiss — there is no hidden state here and nothing to reset.
static func build(host: Control, reduced: bool, room_code: String, on_resume: Callable,
		on_main_menu: Callable, on_quit: Callable) -> Control:
	var root := Control.new()
	root.name = "PauseMenu"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# STOP, not IGNORE: the world must not keep taking clicks through an open menu.
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(root)

	var dim := ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)

	# A CenterContainer, then a SHRINK_CENTER column inside it. A full-rect VBox stretches its
	# children to the frame's width, and a Label drawn into that sits wherever its own alignment
	# puts it — which is how the heading came out off-centre on the first pass. This is the same
	# shape the title screen uses, and it centres both axes without arithmetic.
	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(centre)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centre.add_child(col)

	# NOT SHRINK_CENTER. `engraved_line` returns a zero-width Control whose labels anchor full-rect
	# to it, so it must FILL its column for the text to centre — shrinking it collapses the box to
	# nothing and the text draws from the centre rightward, which is exactly what the first pass did.
	var head := Widgets.engraved_line("THE COLLEGIUM", 15, Color(0.86, 0.72, 0.42), 700)
	head.custom_minimum_size = Vector2(230, 16)
	col.add_child(head)
	var rule := Widgets.hrule(Color(0.62, 0.50, 0.31, 0.65))
	rule.custom_minimum_size = Vector2(150, 1)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(rule)
	# The room code, where a player actually goes looking for it — the question "how do I get my
	# friend in?" is asked from the menu, not from a station across the hall (TD-088 R315).
	if room_code != "":
		var code := Widgets.card_label("ROOM CODE   " + room_code, 9,
			Color(0.74, 0.64, 0.44), false, true)
		var cf := Fonts.cinzel(600)
		if cf != null:
			code.add_theme_font_override("font", cf)
		code.custom_minimum_size = Vector2(230, 12)
		col.add_child(code)
	col.add_child(_gap(14))

	# "Return to game", not "Return to your post": the author's call, and the right one — the flavour
	# reading cost a beat of comprehension at the exact moment the player wants the obvious answer.
	var first := Widgets.choice(col, "Return to game", 12, on_resume)
	# Named for what they cost you, not for where they send you (the author's call, twice over).
	# "Leave the expedition" says what you are giving up; "leave for the title" described the
	# destination, which is the one thing the player is not thinking about at that moment.
	Widgets.choice(col, "Leave the expedition", 12, on_main_menu)
	Widgets.choice(col, "Quit to desktop", 12, on_quit)

	if not reduced:
		root.modulate.a = 0.0
		var t := root.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(root, "modulate:a", 1.0, 0.12)
	# Resume takes focus, so Enter is always the safe answer and the laurel marks it on arrival.
	first.grab_focus.call_deferred()
	return root


static func _gap(px: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, px)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c
