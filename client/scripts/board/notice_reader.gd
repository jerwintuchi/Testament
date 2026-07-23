## Taking a writ down to read it: the dimmed overlay, the enlarged parchment, the leader's wax
## seal and its ceremony (TD-067 T230, extracting the TD-041/060/061/062/064/065/068 logic
## out of main.gd verbatim).
##
## A preloaded RefCounted namespace (S3.2/S3.4) rather than a scene, because the reader is
## TRANSIENT — built on open, freed on close, and rebuilt in place on a stamp. It follows the
## `BoardDecor.add_torches(host, …)` idiom: static builders that create nodes on a passed-in
## host. The reader's own memory (which writ is open, its scroll offset, the seal's previous
## state, the stamp cooldown) lives here as static state, because it IS reader state.
##
## The shell keeps the socket (S3.5): this module never touches `_net`. It calls back through
## `Ctx.on_seal` / `Ctx.on_dismiss`, so affordance stays separate from authority (P66/P119) and
## the server remains the only thing that decides anything.
##
## Preserves TD-068's fast path (P123): `show()` attaches ONE named `ReaderOverlay`, so a stamp
## or a close swaps only that node and never rebuilds the board beneath it.
extends RefCounted

const BoardGeo = preload("res://scripts/board/board_geometry.gd")
const Notice = preload("res://scripts/board/notice.gd")
const WaxSeal = preload("res://scripts/board/wax_seal.gd")
const OrnamentScrollbar = preload("res://scripts/board/ornament_scrollbar.gd")
const Widgets = preload("res://scripts/ui/widgets.gd")

const SEAL_COOLDOWN_MS := 900          # stamp/lift interaction lockout ≈ the press length (R209)

# The asserted genus, as prose. A falsifiable claim reads as words, never pressed in wax
# (TD-060) — which is why there is no Origin seal anywhere in this file.
const ORIGIN_GLOSS := {
	"BELIEF": "a corrupted thought",
	"SIN": "a corrupted deed",
	"RELIC": "corrupted matter",
}

# ── Reader memory. Static because it belongs to the reader, not to the shell. ──
static var _open_cid := ""             # which notice is open (R199 scroll continuity)
static var _scroll_mem := 0            # its last scroll offset, restored on a same-notice rebuild
static var _seal_prev: Dictionary = {} # cid -> sealed? at last build — detects the stamp/lift (R200)
static var _cooldown_until := 0        # Time.get_ticks_msec() until which the stamp is locked


## Everything the reader needs from the shell, passed explicitly so this module reads nothing
## global and mutates no game state (I1).
class Ctx extends RefCounted:
	var host: Node                 # for get_tree()/get_viewport() and the flash's own CanvasLayer
	var canvas: Control            # the board canvas the overlay attaches to
	var intel: Dictionary          # the writ being read
	var snapshot: Dictionary       # authoritative; the seal's state is derived from it
	var seeker_name := "Seeker"    # the local Seeker's name, for the oath
	var leader := false
	var reduced_motion := false
	var parch: Array = []          # live parchment textures
	var inner := Vector2(480, 288) # the board's inner size
	var on_dismiss: Callable       # () -> void          — return to the wall
	var on_seal: Callable          # (cid, selected) -> void — the shell sends the intent
	var logger: Callable           # (String) -> void


## Forget the open writ. Called when the reader closes: the scroll offset and the seal's
## transition memory are per-open (R199/R200), so a fresh open pins to the top and plays no
## ceremony for a state it never showed.
static func forget() -> void:
	_open_cid = ""
	_scroll_mem = 0
	_seal_prev.clear()


## Fade a closing overlay out and drop it. Renamed and made click-through first: a dying
## overlay must never be found by the next `find_child("ReaderOverlay")`, and its dim (which
## STOPs mouse) must not swallow a click aimed at the board during the fade (TD-068).
static func retire(ov: Control) -> void:
	ov.name = "ReaderOverlayClosing"
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ch in ov.get_children():
		if ch is Control:
			(ch as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := ov.create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(ov, "modulate:a", 0.0, 0.07)
	t.tween_callback(ov.queue_free)


## Build the reader onto `ctx.canvas` and return its overlay.
static func show(ctx: Ctx) -> Control:
	# The whole reader (dim + centred reader row) lives under ONE named container so a
	# stamp/lift can refresh JUST the reader in place (TD-065/R211) — free this and re-show,
	# without rebuilding the board notices/torches (the stutter). Pass-through mouse so the
	# dim still catches click-off and the reader still reads.
	var overlay := Control.new()
	overlay.name = "ReaderOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ctx.canvas.add_child(overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.58)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.z_index = 10   # above the placard (z 5) so a taken-down writ covers the sign too
	# Capture hardening: under `-- --reader` (unattended `--board-preview` captures) the
	# click-off dismiss is suppressed — the Godot window pops under the OS cursor and stray
	# physical clicks kept toggling the taken-down writ closed mid-capture (known gotcha).
	# Debug-preview only; the Return button still dismisses.
	if not (OS.is_debug_build() and OS.get_cmdline_user_args().has("--reader")):
		# Left-button only — wheel ticks are ALSO InputEventMouseButton (WHEEL_UP/DOWN,
		# pressed), so an unguarded check made over-scrolling the writ dismiss it.
		dim.gui_input.connect(func(e: InputEvent):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				ctx.on_dismiss.call())
	overlay.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.z_index = 10
	overlay.add_child(cc)
	# Reader + the quill-line scrollbar side by side (TD-061 / R194): the ornament rides
	# OUTSIDE the sheet, on the dimmed board, mirroring the reader's scroll both ways.
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	cc.add_child(row)
	var rdr := _build(ctx)
	row.add_child(rdr)
	var orn := OrnamentScrollbar.new()
	orn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	orn.custom_minimum_size = Vector2(18, rdr.custom_minimum_size.y * 0.82)
	row.add_child(orn)
	orn.attach(rdr.find_child("ReaderScroll", true, false) as ScrollContainer)
	# Scroll continuity (TD-062/R199, P114): a snapshot rebuild of the SAME open notice
	# (stamping/unstamping the seal) restores the prior offset — the pin-to-top belongs to
	# a FRESH open only. `--reader-foot` (debug capture) rides the same path.
	var cid := str(ctx.intel.get("contractId", ""))
	var target := 0
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--reader-foot"):
		target = 100000
	elif cid == _open_cid:
		target = _scroll_mem
	_open_cid = cid
	_settle_scroll.call_deferred(ctx, rdr, target)
	return overlay


# Settle a freshly-(re)built reader at `target` (0 = the headline; a remembered offset on
# a same-notice rebuild, R199; 100000 = the debug foot pin). The one-shot set lost a race
# with a late reflow/focus pass, so the value is held across several frames; afterwards
# the scrollbar feeds `_scroll_mem` so the NEXT rebuild can restore the reader.
static func _settle_scroll(ctx: Ctx, rdr: Control, target: int) -> void:
	var sc: ScrollContainer = null
	for _i in 8:
		if not is_instance_valid(rdr):
			return
		sc = rdr.find_child("ReaderScroll", true, false) as ScrollContainer
		if sc != null:
			ctx.host.get_viewport().gui_release_focus()   # no focused footer control to follow
			sc.scroll_vertical = target
		await ctx.host.get_tree().process_frame
	if sc != null:
		_scroll_mem = int(sc.scroll_vertical)
		var track := sc
		sc.get_v_scroll_bar().value_changed.connect(func(_v):
			if is_instance_valid(track):
				_scroll_mem = int(track.scroll_vertical))


static func _origin_word(origin: String) -> String:
	if origin.is_empty():
		return "?"
	return origin.substr(0, 1) + origin.substr(1).to_lower()


static func _build(ctx: Ctx) -> Control:
	var intel := ctx.intel
	# The enlarged parchment poster. The reader IS the parchment sprite (torn shape),
	# enlarged — no rectangular backing behind it (that was the "square"). The reading is
	# padded well inside the intact centre so no glyph rides a tear; the dimmed board shows
	# past the torn edges, exactly like a poster taken off the wall.
	var tint := BoardGeo.parch_tint(str(intel.get("contractId", "")))
	var reader := Control.new()
	reader.mouse_filter = Control.MOUSE_FILTER_STOP   # clicks on the writ don't dismiss
	var inner := ctx.inner
	reader.custom_minimum_size = Vector2(min(486.0, inner.x - 40.0), min(inner.y - 24.0, 396.0))
	if not ctx.parch.is_empty():
		var bg := TextureRect.new()
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.stretch_mode = TextureRect.STRETCH_SCALE
		bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # fill the enlarged reader sheet
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST   # crisp deckled edge, no blur
		bg.texture = ctx.parch[absi(str(intel.get("contractId", "")).hash()) % ctx.parch.size()]
		bg.modulate = tint
		reader.add_child(bg)
	var scroll := ScrollContainer.new()   # a long writ scrolls within the sheet
	scroll.name = "ReaderScroll"          # found by _settle_scroll to pin it to the top
	# The scroll (= the CLIP boundary) is inset to the parchment's intact centre, not the
	# reader's full rect: with a full-rect scroll the pad margins live INSIDE the scrolled
	# content, so once scrolled the text rode up over the torn edge and past the sheet
	# (TD-060 review). Clipping is forced explicitly so no glyph ever escapes the sheet.
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	# TD-061 (R193): the text consumes the sheet — insets tightened (34/30 → 26/22) and the
	# internal scrollbar retired (SHOW_NEVER: wheel scrolling lives on, the bar is the
	# external ornament, R194), so its width goes to text too. The clip boundary still sits
	# inside the solid parchment (R189: no glyph ever rides the torn edge).
	scroll.offset_left = 26.0
	scroll.offset_right = -26.0
	scroll.offset_top = 22.0
	scroll.offset_bottom = -22.0
	scroll.clip_contents = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.follow_focus = false            # a focused footer control must not drag the writ down
	reader.add_child(scroll)
	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 8)
	scroll.add_child(pad)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.custom_minimum_size = Vector2(min(418.0, inner.x - 108.0), 0)   # sheet width minus R193 insets
	col.add_theme_constant_override("separation", 6)
	pad.add_child(col)
	var ink := Color(0.20, 0.11, 0.04)
	# Secondary text (site, gloss, preamble, Archive, seal caption): the old 0.38/0.27/0.15 was
	# only a shade off the parchment and washed out. Darkened to a firm brown that reads.
	var ink_soft := Color(0.26, 0.16, 0.07)
	# Headline (sacred register), inked by charge + rule.
	var rverb := str(intel.get("primaryVerb", ""))
	var head := Widgets.card_label(Notice.headline(rverb), 12, Widgets.INK, true, true)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(head)
	col.add_child(Widgets.hrule(Color(0.42, 0.28, 0.16, 0.7)))
	var title := Widgets.card_label(str(intel.get("targetName", "?")), 21, ink, true, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(title)
	var site := Widgets.card_label("at %s" % intel.get("siteName", "?"), 12, ink_soft, true, true)
	site.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(site)
	# Asserted genus (text-only gloss — the Origin wax seal is retired, TD-060: the
	# assertion is a falsifiable claim and reads as prose, never pressed in wax).
	var org := str(intel.get("origin", "SIN"))
	var org_lbl := Widgets.card_label("Asserted %s: %s" % [_origin_word(org), ORIGIN_GLOSS.get(org, "")], 12, ink_soft, true, true)
	org_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(org_lbl)
	# Preamble + the petitioner's plea + the charge (procedural, verb-faithful). The plea
	# replaces the retired threat pips (TD-061): danger reads as the DREAD in the
	# petitioner's own words, banded by tier — words from a person, never a meter (P110).
	var pre := Widgets.card_label(Notice.preamble(intel), 12, ink_soft, true, true)
	pre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(pre)
	var plea := Widgets.card_label(Notice.plea(intel), 12, ink_soft, true, true)
	plea.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(plea)
	var charge := Widgets.card_label(Notice.charge(intel), 14, ink, true, true)
	charge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(charge)
	# Honest empty Archive (no fabricated signs/notes/reward).
	var arch := Widgets.card_label("From the Archive: no prior testament on record.", 11, ink_soft, true, true)
	arch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(arch)
	# The signature of the petitioner who reported it.
	var sig := Widgets.card_label(Notice.signature(intel.get("requester", {})), 12, ink, true, true)
	sig.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(sig)
	col.add_child(Widgets.hrule(Color(0.42, 0.28, 0.16, 0.7)))
	# The seal: the leader stamps to take up the charge (reversible).
	col.add_child(_seal_block(ctx, ink, ink_soft))
	# Return to the board. Built inline (not via _popup_button) so it takes no keyboard
	# focus — a focused footer button is what dragged the freshly-opened writ to its foot.
	var ret := Button.new()
	ret.text = "Return to the board"
	ret.focus_mode = Control.FOCUS_NONE
	ret.pressed.connect(func(): ctx.on_dismiss.call())
	col.add_child(ret)
	return reader


# The seal (TD-041): the leader stamps their seal on the open charge to take it up,
# and clicks the stamped seal again to lift it — a reversible SELECT/DESELECT over
# the Contract Board. Non-leaders see the seal's state read-only. Affordance is not
# authority: the server validates (a raced NOT_* / WRONG_PHASE surfaces in status).
static func _seal_block(ctx: Ctx, ink: Color, ink_soft: Color) -> Control:
	var intel := ctx.intel
	var cid := str(intel.get("contractId", ""))
	var sel_c: Variant = ctx.snapshot.get("contract")
	var selected := sel_c != null and str(sel_c.get("contractId", "")) == cid
	var leader := ctx.leader

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 4)

	# The stamp target: a clickable area holding a wax seal (faint until stamped) and
	# a caption. The whole area is the hit target so "stamp your seal" reads as one act.
	var stamp := Button.new()
	stamp.flat = true
	stamp.clip_contents = false
	# Interaction lockout (TD-064/R209, made robust TD-065/R212): the stamp is disabled for a
	# short window after a stamp/lift so the ceremony can't be interrupted or spam-fired. The
	# REAL spam guard is a time-check in the click handler below (independent of this disabled
	# state, so it can neither be defeated nor stick); this disable is visual feedback only and
	# ALWAYS re-enables — an unconditional buffered timer (no strict deadline recheck, which
	# used to miss by a frame and leave the button stuck until reopen). Affordance ≠ authority
	# (P119): the server still validates.
	var cool_left := _cooldown_until - Time.get_ticks_msec()
	stamp.disabled = (not leader) or cool_left > 0
	if leader and cool_left > 0:
		ctx.host.get_tree().create_timer(cool_left / 1000.0 + 0.08).timeout.connect(func():
			if is_instance_valid(stamp):
				stamp.disabled = false)
	# Keyboard reachable for the leader only (T146 / L6): a non-leader's seal is read-only, so it
	# takes no focus. The gilt ring marks it when Tabbed to; Enter/Space stamps.
	stamp.focus_mode = Control.FOCUS_ALL if leader else Control.FOCUS_NONE
	stamp.custom_minimum_size = Vector2(0, 76)
	stamp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stamp.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if leader else Control.CURSOR_ARROW
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "disabled"]:
		stamp.add_theme_stylebox_override(st, empty)
	stamp.add_theme_stylebox_override("focus", Widgets.focus_ring() if leader else empty)
	if leader:
		stamp.pressed.connect(func():
			# The spam guard (TD-065/R212): a hard time-check, independent of the button's
			# disabled state, so the lockout can neither be defeated (a queued click firing
			# after re-enable) nor stick. A click inside the window sends nothing.
			var now := Time.get_ticks_msec()
			if now < _cooldown_until:
				return
			# One stamp per window: open the lockout, disable for feedback, send the intent.
			_cooldown_until = now + SEAL_COOLDOWN_MS
			stamp.disabled = true
			ctx.logger.call("seal %s accepted=%s" % [cid, not selected])
			ctx.on_seal.call(cid, selected))

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	stamp.add_child(row)

	# The wax seal: a faint imprint waiting to be pressed, or a firm seal once stamped —
	# the generic COLLEGIUM seal (TD-060): the leader stamps the order's device, not a genus.
	var seal := WaxSeal.new()
	seal.name = "ReaderSeal"                            # found by --flash-preview (V1 capture)
	seal.custom_minimum_size = Vector2(46, 46)
	seal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Unsealed = the empty dashed socket (TD-063/R203 — the dash carries its own low
	# opacity, so the control's modulate stays 1.0 for every role).
	seal.set_faint(not selected)
	row.add_child(seal)

	# The OATH (TD-062/R198, author ruling: named-target form): the leader speaks in the
	# first person; the how-to lives in the hover tooltip, never on the sheet. Non-leaders
	# read the party form.
	var target := str(intel.get("targetName", "the charge"))
	var seeker := ctx.seeker_name
	if seeker.is_empty():
		seeker = "Seeker"
	var caption: String
	if selected:
		caption = "It is witnessed. %s is ours to answer." % target
	elif leader:
		caption = "I, %s, take up the charge against %s. Let it be witnessed." % [seeker, target]
	else:
		caption = "Awaiting the leader's seal."
	if leader:
		stamp.tooltip_text = "Click the seal to lift it" if selected else "Click the seal to stamp it"
	var cap := Widgets.card_label(caption, 12, ink if selected else ink_soft, true, false)
	cap.custom_minimum_size = Vector2(220, 0)
	row.add_child(cap)

	# The ceremony (TD-062/R200): if this rebuild FLIPPED the seal's state, the new seal
	# plays the press (stamp) or the peel (lift). Pure theatre: no state, no message; a
	# reduced-motion client renders the end state only (P115).
	var prev: Variant = _seal_prev.get(cid)
	_seal_prev[cid] = selected
	if prev != null and bool(prev) != selected and not ctx.reduced_motion:
		_animate_seal(ctx, seal, selected)
	box.add_child(stamp)
	return box


# The stamp/lift theatre (R200; reworked TD-063/R204: SLOWER and HEAVIER, and it may
# displace NOTHING — the flash lives on its own layer, never the HBox row (whose layout
# shoved the caption sideways), and the sheet-thump is gone (it moved the prose under the
# reader's eyes). Runs on the freshly rebuilt seal after one frame (so the container has
# sized it); if another rebuild lands mid-tween the nodes are freed and the tweens die with
# them — safe. (P116)
static func _animate_seal(ctx: Ctx, seal: Control, sealed: bool) -> void:
	await ctx.host.get_tree().process_frame
	if not is_instance_valid(seal):
		return
	seal.pivot_offset = seal.size * 0.5
	if sealed:
		# The press: a hovering wind-up, an accelerating drop, a deep squash on impact
		# with the wax flash blooming, and a heavy wobbling settle (~0.82s total). The
		# flash lives on its OWN overlay above the board (TD-064/R207), not under the seal:
		# the seal sits inside the reader's clipped ScrollContainer, which trapped the
		# flash's radius at the sheet edge. Spawn it timed to the impact (~0.40s in).
		spawn_flash(ctx, seal, 0.40)
		seal.scale = Vector2(2.2, 2.2)
		seal.modulate.a = 0.0
		var t := seal.create_tween()
		t.tween_property(seal, "modulate:a", 0.85, 0.10)                                   # hover in
		t.parallel().tween_property(seal, "scale", Vector2(2.05, 2.05), 0.10)
		t.tween_property(seal, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)  # the fall
		t.parallel().tween_property(seal, "modulate:a", 1.0, 0.30)
		t.tween_property(seal, "scale", Vector2(1.22, 0.80), 0.09)                          # impact squash
		t.tween_property(seal, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # heavy settle
	else:
		# The peel: the firm wax lifts, rises and fades, then the empty dashed socket
		# remains (the block's true unsealed render).
		seal.set_faint(false)
		seal.modulate.a = 1.0
		var t := seal.create_tween()
		t.tween_property(seal, "scale", Vector2(1.55, 1.55), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(seal, "modulate:a", 0.0, 0.28)
		t.tween_callback(func():
			if is_instance_valid(seal):
				seal.set_faint(true)
				seal.scale = Vector2.ONE
				seal.modulate.a = 1.0)


# The impact flash on its OWN overlay (TD-064/R207): a warm additive bloom centred on the
# seal's on-screen position, drawn ABOVE the board so its full radius shows (the seal lives
# inside the reader's clipped ScrollContainer, which trapped a child flash at the sheet
# edge). The seal's centre stays fixed (it only scales about its pivot), so we capture it
# once. The overlay is independent of the seal's lifecycle — a snapshot rebuild that frees
# the seal leaves the bloom to finish and free its own layer (no leak, no orphan).
static func spawn_flash(ctx: Ctx, seal: Control, delay: float) -> void:
	var gt := seal.get_global_transform_with_canvas()
	var centre := gt * (seal.size * 0.5)         # seal centre in logical (canvas) space
	var fsz := seal.size * 2.3 * gt.get_scale()
	var lay := CanvasLayer.new()
	lay.layer = 95                               # above the popup dim/reader and the rite banner (90)
	ctx.host.add_child(lay)
	var flash := TextureRect.new()
	flash.texture = BoardGeo.backlight_gradient()
	flash.material = BoardGeo.additive_material()
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.stretch_mode = TextureRect.STRETCH_SCALE
	flash.size = fsz
	flash.pivot_offset = fsz * 0.5
	flash.position = centre - fsz * 0.5
	flash.scale = Vector2(0.6, 0.6)
	# Overdriven warm core (>1) so the additive burst reads even over the bright parchment
	# (additive on a light surface saturates); still candlelit/in-register, no bloom shader.
	flash.modulate = Color(1.3, 1.0, 0.58, 0.0)
	lay.add_child(flash)
	var ft := flash.create_tween()
	ft.tween_interval(delay)                     # bloom on IMPACT, not on the wind-up
	ft.tween_property(flash, "modulate:a", 0.92, 0.04)
	ft.parallel().tween_property(flash, "scale", Vector2(1.8, 1.8), 0.42)
	ft.tween_property(flash, "modulate:a", 0.0, 0.30)
	ft.tween_callback(lay.queue_free)
