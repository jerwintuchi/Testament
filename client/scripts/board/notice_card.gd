## One writ on the wall: the live contract card, the inert flavor scrap, and the furniture
## they wear (tack, verb badge, focus reticle, hover lift) — extracted verbatim from main.gd
## under TD-067 T231.
##
## A preloaded RefCounted namespace (S3.2/S3.4), not a scene: a card is TRANSIENT — every
## board build makes fresh ones and throws the old away. `ContractBoard` assembles the wall
## out of these; nothing here knows the wall exists, so the dependency runs one way only.
##
## The card's own art (parchment, tacks) and its keyboard-focus memory live here as static
## state, because they belong to the card, not to the shell. Selection and the click intent
## are passed IN (`selection`, `on_select`) — this module never touches `_net` (S3.5) and
## never decides anything (P66: affordance is not authority).
extends RefCounted

const BoardGeo = preload("res://scripts/board/board_geometry.gd")
const VerbBadge = preload("res://scripts/board/verb_badge.gd")
const Widgets = preload("res://scripts/ui/widgets.gd")

# ── Card art. Static because it belongs to the card; `load_art()` is called once from the
#    shell's `_ready` so the load timing is exactly what it was before the extraction.
static var _parch_live: Array = []     # deckled LIVE parchment (warm, inner light) — 2 tear seeds (T143)
static var _parch_flavor: Array = []   # deckled FLAVOR parchment (aged, foxed) — 2 tear seeds
static var _tack_tex: Array = []       # nail · wax · pin · ribbon, seeded per live notice

# contractId of the keyboard-focused writ, kept across rebuilds (T146 / L6).
static var _focus_cid := ""


## Load the card art. Idempotent; a missing texture is simply skipped (every consumer
## tolerates an empty array).
static func load_art() -> void:
	if not _parch_live.is_empty() or not _tack_tex.is_empty():
		return
	for i in 2:
		var lv := load("res://assets/ui/board/parch_v1_%d.png" % i) as Texture2D   # deckled cards on v1 painted paper
		if lv != null:
			_parch_live.append(lv)
		var fv := load("res://assets/ui/board/parch_flavor_%d.png" % i) as Texture2D
		if fv != null:
			_parch_flavor.append(fv)
	for tk in ["nail", "wax", "pin", "ribbon"]:
		var t := load("res://assets/ui/board/tack_%s.png" % tk) as Texture2D
		if t != null:
			_tack_tex.append(t)


## The live parchment textures — the wall's cast shadows and the reader's sheet draw the
## same paper, so they read it from here rather than keeping a second copy.
static func parch_live() -> Array:
	return _parch_live


## Which writ holds keyboard focus, by contractId. Read by the wall so a rebuild can restore it.
static func focus_cid() -> String:
	return _focus_cid


# Ash & Ember ink ramp. The headline is INK, never wax and never a per-verb hue: wax is
# the palette's lowest-luminance colour and fails the contrast floor as text.
const INK := Widgets.INK
const INK_SOFT := Widgets.INK_SOFT
# Live-tone floor (T145 / L1): a live writ's paper never composites darker than this warm
# ivory, so ink (INK/INK_SOFT) always clears the 4.5:1 contrast floor regardless of where on
# the wall the notice lands. Enforced on every live-paper modulate (incl. hover).
const TONE_FLOOR := Color("CBB583")
# Minimum interactive size for a live notice (T145 / L6): a touch/click target is never
# smaller than 44x44 even on a cramped viewport. The grid already exceeds this; this is the guard.
const HIT_MIN := Vector2(44.0, 44.0)
# The live-notice stack (backlight, shadow, card) draws at this z — above the wall vignette
# (z 2), below the bar (4) / placard (5) / reader (10). Keeps the writs off the shadowed wall.
const LIVE_Z := 3

# Clamp a colour so no channel falls below the live-tone floor (alpha untouched).
static func _floor_tone(c: Color) -> Color:
	return Color(maxf(c.r, TONE_FLOOR.r), maxf(c.g, TONE_FLOOR.g), maxf(c.b, TONE_FLOOR.b), c.a)

# A keyboard-focus reticle (T146 / L6): four BRIGHT corner brackets over a FAINT full-edge
# outline — the selection read from the reference. Drawn via the `draw` signal so it needs no
# separate script or asset; sits over its card, hidden until the card takes focus. Returns the
# reticle Control (add as the card's last child; toggle its visibility on focus).
static func _focus_reticle() -> Control:
	var r := Control.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.visible = false
	r.draw.connect(func() -> void:
		var s := r.size
		var bright := Color(0.99, 0.87, 0.48)
		var faint := Color(0.93, 0.80, 0.44, 0.26)
		var arm := clampf(minf(s.x, s.y) * 0.24, 7.0, 18.0)
		# Faint hairline on all four edges.
		r.draw_rect(Rect2(Vector2.ZERO, s), faint, false, 1.0)
		# Bright L-brackets at each corner (thin, offset in a hair so the arms read as a frame).
		var corners := [
			[Vector2(0.5, 0.5), Vector2(1, 0), Vector2(0, 1)],
			[Vector2(s.x - 0.5, 0.5), Vector2(-1, 0), Vector2(0, 1)],
			[Vector2(0.5, s.y - 0.5), Vector2(1, 0), Vector2(0, -1)],
			[Vector2(s.x - 0.5, s.y - 0.5), Vector2(-1, 0), Vector2(0, -1)],
		]
		for c in corners:
			var o: Vector2 = c[0]
			r.draw_line(o, o + (c[1] as Vector2) * arm, bright, 1.0)
			r.draw_line(o, o + (c[2] as Vector2) * arm, bright, 1.0))
	r.resized.connect(r.queue_redraw)
	return r

# A live contract notice: a clickable landscape parchment — sacred headline, target,
# site, requester signature, and an Origin wax seal as a corner badge. No prose here
# (glanceable); the full writ is read only when taken down.
# Fit one writ inside its grid cell (TD-061 / R192, P111): a seeded width, then the text
# measured with the SAME font/sizes/wrap the labels render with (ThemeDB.fallback_font is
# the default theme font — no custom default is set), plus the card's furniture headroom
# (pad 13 top / 4 bottom / 7 sides, VBox separation 1 — mirrors _make_live_notice). If the
# cell can't hold the block at 9/7, the fonts step down once to 8/6 — the guarantee that a
# long site ("at Hollowmere Crossing") never clips at the sheet edge.
static func fit(intel: Dictionary, cell: Vector2) -> Dictionary:
	var cid := str(intel.get("contractId", ""))
	var u_w := float(absi((cid + "|w").hash()) % 1000) / 999.0
	var u_h := float(absi((cid + "|h").hash()) % 1000) / 999.0
	var w := clampf(floorf(cell.x * (0.84 + 0.16 * u_w)), HIT_MIN.x, cell.x)
	var font := ThemeDB.fallback_font
	var target := str(intel.get("targetName", "?"))
	var site := "at %s" % intel.get("siteName", "?")
	var text_w := w - 14.0                    # pad margins 7+7
	# Labels insert the theme's `line_spacing` (default 3) BETWEEN wrapped lines, which
	# get_multiline_string_size does not count — the TD-061 fit was ~6px short on two
	# 2-line blocks, clipping "Ossuary" at the sheet edge (TD-062/R196, P113).
	var ls := float(ThemeDB.get_default_theme().get_constant("line_spacing", "Label"))
	var chosen := [8, 6]                      # fallback if even stepping down can't fit
	var need := 0.0
	for fs in [[9, 7], [8, 6]]:
		var th := font.get_multiline_string_size(target, HORIZONTAL_ALIGNMENT_CENTER, text_w, fs[0]).y
		th += ls * maxf(0.0, roundf(th / font.get_height(fs[0])) - 1.0)
		var sh := font.get_multiline_string_size(site, HORIZONTAL_ALIGNMENT_CENTER, text_w, fs[1]).y
		sh += ls * maxf(0.0, roundf(sh / font.get_height(fs[1])) - 1.0)
		need = 13.0 + 4.0 + th + 1.0 + sh + 2.0   # headroom + text block + safety (measure == render)
		if need <= cell.y:
			chosen = fs
			break
	# Seeded slack: even a short writ varies, growing part of the way into its remaining
	# cell room — but the content floor (and the 44px hit floor) always wins.
	var h := clampf(ceilf(need + u_h * maxf(0.0, cell.y - need) * 0.6), HIT_MIN.y, cell.y)
	return {"size": Vector2(w, floorf(h)), "tfs": chosen[0], "sfs": chosen[1]}

static func live(intel: Dictionary, idx: int, selection: Dictionary, on_select: Callable, tfs: int = 9, sfs: int = 7) -> Control:
	var sel := not selection.is_empty() and str(selection.get("contractId", "")) == str(intel.get("contractId", ""))
	var card := Button.new()
	card.flat = true
	card.clip_contents = true   # a long target never spills its writ onto the wall below
	# Keyboard reachable (T146 / L6): Tab traverses the writs in board (reading) order, Enter/
	# Space takes one down. The focus mark is a corner-bracket reticle (added below), not a
	# stylebox ring, so all four states stay flat.
	card.focus_mode = Control.FOCUS_ALL
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus"]:
		card.add_theme_stylebox_override(st, empty)
	if sel:
		card.rotation_degrees = 0.0   # the one taken down hangs straight
	card.pressed.connect(func(): on_select.call(intel))
	var tint := BoardGeo.parch_tint(str(intel.get("contractId", "")))
	var bg := TextureRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	# Obey the notice rect, not the texture's own 182x118: EXPAND_KEEP_SIZE (default)
	# floors the min size to the full texture, so the paper overflowed the keep-out
	# footprint and buried its neighbours. IGNORE_SIZE lets FULL_RECT shrink it to fit.
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR   # v1 painted paper stays soft/painterly
	if not _parch_live.is_empty():
		bg.texture = _parch_live[idx % _parch_live.size()]
	# Lift the paper toward v1's bright, lit ivory, then floor it so no seed/tint ever drops a
	# live writ below the legibility floor (T145 / L1). The stack also rides above the vignette.
	bg.modulate = _floor_tone(tint.lightened(0.16))
	card.add_child(bg)
	# Paper curl: a soft inner shadow fading up from the foot, so the sheet lifts off the
	# wall and shades itself (never a dead-flat rectangle). Above the paper, under the text.
	var curl := TextureRect.new()
	curl.texture = BoardGeo.curl_gradient()
	curl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curl.stretch_mode = TextureRect.STRETCH_SCALE
	curl.anchor_left = 0.06; curl.anchor_right = 0.94
	curl.anchor_top = 1.0; curl.anchor_bottom = 1.0
	curl.offset_top = -11.0; curl.offset_bottom = -2.0
	card.add_child(curl)
	# Faint impressed watermark ring behind the writ (the aged-official read in the
	# reference): a barely-there ink circle, inert, drawn above the paper, under the text.
	var mark := Panel.new()
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.anchor_left = 0.20
	mark.anchor_right = 0.80
	mark.anchor_top = 0.28
	mark.anchor_bottom = 0.72
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0, 0, 0, 0)
	msb.set_border_width_all(2)
	msb.border_color = Color(0.26, 0.18, 0.10, 0.14)
	msb.set_corner_radius_all(60)
	mark.add_theme_stylebox_override("panel", msb)
	card.add_child(mark)
	# Lift toward the viewer AND raise above neighbours, so an overlapped notice is
	# never occluded while you read/click it (dense scatter can stack corners).
	# Hover takes precedence over the Tab position: moving the mouse onto a writ grabs focus, so
	# the reticle jumps straight to the hovered writ (and Tab keeps working from there). (T146.)
	card.mouse_entered.connect(func(): card.grab_focus(); card.move_to_front(); hover(card, 1.05); bg.modulate = _floor_tone(tint.lightened(0.26)))
	card.mouse_exited.connect(func(): hover(card, 1.03 if sel else 1.0); bg.modulate = _floor_tone(tint.lightened(0.16)))
	var verb := str(intel.get("primaryVerb", ""))
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right"]:
		pad.add_theme_constant_override(side, 7)
	# Room at the top for the corner furniture: the verb badge (upper-left) and the wax
	# seal (upper-right) both straddle the top edge, so the text column starts below them.
	pad.add_theme_constant_override("margin_top", 13)
	pad.add_theme_constant_override("margin_bottom", 4)
	card.add_child(pad)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 1)
	pad.add_child(v)
	# No sacred-register type WORD on the card: the corner verb badge (keyed by the bottom
	# legend) already carries it, and a long headline like "RITE OF BANISHMENT" both wrapped
	# under the badge/seal and read illegibly faint. The card now leads with the target
	# (Prototype v1), leaving room so every card keeps its site line.
	# Centre the target/site block so the portrait writ fills top-to-bottom (Prototype v1).
	var gap_top := Control.new()
	gap_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap_top)
	v.add_child(Widgets.card_label(str(intel.get("targetName", "?")), tfs, INK, true, true))
	v.add_child(Widgets.card_label("at %s" % intel.get("siteName", "?"), sfs, INK_SOFT, true, true))
	# Threat/reward are deliberately NOT shown on the wall (trait-free board; knowledge is
	# not a number) — you learn threat only by taking the notice down to read. The
	# requester's signature is shown in the reader, not on the glanceable card, so a
	# two-line target never fights the foot for the short portrait's vertical room.
	var gap_bot := Control.new()
	gap_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap_bot)
	# Corner furniture (own children, above the text): the PRIMARY-VERB badge stamped in
	# the upper-left (its legend is the bottom-left key). The asserted-Origin wax seal is
	# RETIRED from the writ (TD-060): the petition-type badge is the only corner mark —
	# a sealed assertion of genus implied a certainty the Collegium doesn't have.
	card.add_child(_notice_tack(str(intel.get("contractId", ""))))
	card.add_child(_verb_corner_badge(verb))
	if sel:
		var ring := Panel.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.set_anchors_preset(Control.PRESET_FULL_RECT)
		var rb := StyleBoxFlat.new()
		rb.bg_color = Color(0, 0, 0, 0)
		rb.set_border_width_all(2)
		rb.border_color = Color(0.90, 0.74, 0.36)
		rb.shadow_color = Color(0.85, 0.62, 0.24, 0.55)   # warm glow bleeding off the gilt edge
		rb.shadow_size = 6
		ring.add_theme_stylebox_override("panel", rb)
		card.add_child(ring)
	# Keyboard-focus reticle (T146 / L6): the last child so its brackets draw over the writ.
	# Focus is tracked by contractId so a board rebuild (a ready-toggle, a seal) restores it.
	var cid := str(intel.get("contractId", ""))
	card.set_meta("cid", cid)
	var reticle := _focus_reticle()
	card.add_child(reticle)
	card.focus_entered.connect(func():
		_focus_cid = cid
		reticle.visible = true
		reticle.queue_redraw())
	card.focus_exited.connect(func(): reticle.visible = false)
	return card

# An inert flavor notice: aged parchment, a header + a few lines, never clickable.
static func flavor(f: Dictionary, idx: int) -> Control:
	var note := Panel.new()
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	note.modulate = Color(0.58, 0.55, 0.52)   # older, greyed hard so live notices always pop
	var sb := StyleBoxEmpty.new()
	note.add_theme_stylebox_override("panel", sb)
	var bg := TextureRect.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE   # fit the scrap to the notice rect
	bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _parch_flavor.is_empty():
		bg.texture = _parch_flavor[idx % _parch_flavor.size()]   # already aged + foxed (T143)
	bg.modulate = BoardGeo.parch_tint("flavor-%d" % idx).darkened(0.12)
	note.add_child(bg)
	var pad := MarginContainer.new()
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		pad.add_theme_constant_override(side, 11)
	note.add_child(pad)
	var v := VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 3)
	pad.add_child(v)
	v.add_child(Widgets.card_label(str(f.get("head", "")), 10, Color(0.32, 0.16, 0.09), true, true))
	v.add_child(Widgets.card_label(str(f.get("body", "")), 8, Color(0.36, 0.27, 0.16), true, false))
	return note

# Lift a card toward the viewer on hover (scale from its centre pivot).
static func hover(card: Control, s: float) -> void:
	if not is_instance_valid(card):
		return
	# One hover tween per card, remembered so it can be killed: a lift still in flight would
	# otherwise animate straight over a direct scale write (the open/close reset, P123) — and
	# two overlapping lifts used to fight each other on a fast re-hover.
	kill_hover_tween(card)
	var t := card.create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2(s, s), 0.09)
	card.set_meta("hover_tween", t)

static func kill_hover_tween(card: Control) -> void:
	# has_meta first: Godot treats a NULL default as "no default given" and errors on a missing
	# key, so get_meta("hover_tween", null) is not the safe read it looks like.
	if not card.has_meta("hover_tween"):
		return
	var prev = card.get_meta("hover_tween")
	if prev is Tween and (prev as Tween).is_valid():
		(prev as Tween).kill()

# The primary-verb type badge, anchored in a notice's upper-left corner (Prototype v1).
static func _verb_corner_badge(verb: String) -> Control:
	var badge := VerbBadge.new()
	badge.set_verb(verb)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.anchor_left = 0.0; badge.anchor_right = 0.0
	badge.anchor_top = 0.0; badge.anchor_bottom = 0.0
	badge.offset_left = 5.0; badge.offset_right = 20.0
	badge.offset_top = 4.0; badge.offset_bottom = 19.0
	return badge

# A tack pinning a notice's top edge — nail · wax · pin · ribbon, chosen by the
# contractId so a given notice always wears the same tack (deterministic). Static decor.
static func _notice_tack(cid: String) -> Control:
	var tack := TextureRect.new()
	tack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tack.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not _tack_tex.is_empty():
		tack.texture = _tack_tex[absi((cid + "|tack").hash()) % _tack_tex.size()]
	tack.anchor_left = 0.5; tack.anchor_right = 0.5
	tack.anchor_top = 0.0; tack.anchor_bottom = 0.0
	tack.offset_left = -6.0; tack.offset_right = 6.0
	tack.offset_top = -5.0; tack.offset_bottom = 9.0
	return tack