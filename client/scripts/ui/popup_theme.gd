extends RefCounted
## The station popup's Theme (TD-067; re-authored to the writ idiom, TD-089). Preloaded as
## `PopupTheme`, never a global class_name (TD-029/30).
##
## Applied to `_popup` so it cascades to every child. It **was** a dark stone panel in an aged-gold
## frame with filled gold-on-charcoal buttons — the same chrome the join screen shed in TD-080, and
## by TD-088 the last place in the pre-expedition flow still wearing it.
##
## Now it is the writ: **the Contract Board's own parchment**, nine-sliced, with ink text, ruled
## lines instead of boxes, and Almendra throughout. A station is a thing you walk up to and read, which
## is the same object the join and options screens already are.
##
## **The Theme carries the SHEET ONLY.** It does not style `Label` or `Button`, and that restraint is
## load-bearing rather than tidiness: the Contract Board lives inside this same popup, its notice
## cards ARE `Button`s, and `_fit_writ` measures each writ with the font it will actually be drawn
## in. A cascading `Label`/`Button` font therefore silently re-flows every writ — the first pass did
## exactly that, wrapping "Congregation" mid-word and clipping "at The Broken Cloister".
##
## The board overrides colour explicitly but NOT font, so colour was safe and font was not. Anything
## the non-board stations need is applied by their own builders (`_popup_label`, `_popup_button`,
## `_muster_row`), where it reaches only what it is aimed at.

const Fonts := preload("res://scripts/ui/fonts.gd")

const INK := Color(0.16, 0.12, 0.07)
const INK_DIM := Color(0.32, 0.25, 0.16)
const RULE := Color(0.34, 0.26, 0.15, 0.55)
const RULE_LIT := Color(0.26, 0.19, 0.10, 0.95)


static func build() -> Theme:
	var th := Theme.new()

	# ── the sheet ──
	# The board's live parchment, nine-sliced so the deckled edge never stretches. A StyleBoxTexture
	# is what a Theme can carry; `WritForm` reaches the same look with a NinePatchRect because it
	# owns its node, and both read as one material.
	var panel_sb: StyleBox
	var tex := load("res://assets/ui/board/parch_v1_0.png") as Texture2D
	if tex != null:
		var sbt := StyleBoxTexture.new()
		sbt.texture = tex
		sbt.set_texture_margin_all(14.0)
		sbt.set_content_margin_all(18.0)
		panel_sb = sbt
	else:
		# A missing/late import must never crash the popup — the same guard the stone panel carried.
		var flat := StyleBoxFlat.new()
		flat.bg_color = Color(0.80, 0.72, 0.53)
		flat.set_content_margin_all(18.0)
		panel_sb = flat
	th.set_stylebox("panel", "PanelContainer", panel_sb)

	# NOTHING here styles Label or Button. See the class comment: those cascade into the Contract
	# Board, whose writs are Buttons measured against their own font.

	# ── tooltips: a slip of the same paper, not Godot's grey bubble ──
	var tip := StyleBoxFlat.new()
	tip.bg_color = Color(0.83, 0.75, 0.56, 0.97)
	tip.set_border_width_all(1)
	tip.border_color = Color(0.42, 0.33, 0.19)
	tip.content_margin_left = 8.0; tip.content_margin_right = 8.0
	tip.content_margin_top = 4.0; tip.content_margin_bottom = 4.0
	th.set_stylebox("panel", "TooltipPanel", tip)
	th.set_color("font_color", "TooltipLabel", INK_DIM)
	th.set_font_size("font_size", "TooltipLabel", 11)
	return th


## An action's rule: transparent, with a single hairline under the text. Content margins keep the
## words off the line so it reads as an underscore rather than a box edge.
static func ruled(line: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = Color(0, 0, 0, 0)
	b.border_width_bottom = 1
	b.border_color = line
	b.content_margin_left = 6.0
	b.content_margin_right = 6.0
	b.content_margin_top = 4.0
	b.content_margin_bottom = 3.0
	return b
