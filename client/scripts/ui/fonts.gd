extends RefCounted
## ⚠ FINDING, NOT YET FIXED — `theme/custom_font` HAS NEVER APPLIED (TD-102).
##
## `project.godot` sets `gui/theme/custom_font` to Almendra with an explanatory `#`
## comment block directly above it. Godot's project-settings parser **folds those
## comment lines into the following key's name**, so the key it actually reads is not
## `theme/custom_font` — and the project default has silently stayed Godot's fallback
## SANS since TD-097. Proven twice: deleting the comment flips the Contract Board to
## Almendra (29% of pixels differ, `minhit` 80x53 → 80x51), and a re-import rewrote the
## folded key back out as one long garbage key.
##
## So today: call sites asking `Fonts.body()/heading()/ornament()` DO get Almendra;
## anything relying on the project default (e.g. `Widgets.card_label`) gets the sans.
## CLAUDE.md's "the board's small text is the default sans" recorded the symptom.
##
## NOT fixed here on purpose: removing the comment re-flows the Contract Board, which is
## finished work, and changes type across the whole game — the author's call, not a
## side effect of a Quartermaster pass. `notice_card.gd` measures writs against
## `ThemeDB.fallback_font` while `card_label` renders with the default, so the pairing
## (P111) survives either way; only the face changes.
## Shared font builders (TD-067, retypeset TD-097). Preloaded as `Fonts`, never a global
## class_name so a headless parse/import resolves it (TD-029/30).
##
## THE CANON (TD-097): Testament is set in **Almendra**, with **Almendra Display** reserved
## for large ornament. Both are SIL OFL, like Cinzel before them (`OFL-Almendra.txt`).
##
## Why the change. Cinzel is an inscriptional roman and **has no true lowercase** — its
## lowercase glyphs ARE small capitals, so every sentence set in it rendered as SHOUTING
## no matter how it was written. That is a property of the typeface, not a styling slip,
## and it cost a run of "why is this all caps" fixes that could never have worked. Almendra
## is a gothic/medieval serif in the same register with a real lowercase, so a title can
## still be cut in stone and a sentence can still read as a sentence.
##
## THREE ROLES, and the third is narrower than its name suggests:
##
##   body()     Almendra Regular — everything a player reads. Legible down to 7px, which
##              is what the world notices and the writ captions actually use.
##   heading()  Almendra Bold — titles, actions, emphasis. This is the practical display
##              weight at UI sizes.
##   ornament() Almendra Display — LARGE ORNAMENT ONLY, >= 21px.
##
## `ornament()` is an **inline/outline** face: the glyphs are hollow. Measured at the sizes
## this game actually draws (7/9/11/14px) it collapses into a smear, and only resolves from
## about 21px. So it is not "the secondary UI font" — it is for the title screen and rite
## banners, and a call site under 21px is a mistake the size guard below refuses.

const _BODY := "res://assets/fonts/Almendra.ttf"
const _BOLD := "res://assets/fonts/Almendra-Bold.ttf"
const _ORNAMENT := "res://assets/fonts/AlmendraDisplay.ttf"

## Smallest size at which the hollow display face resolves into letters rather than fringe.
const ORNAMENT_MIN_PX := 21


static func _load(path: String) -> FontFile:
	return load(path) as FontFile


## Everything a player reads: body copy, captions, field text, world notices.
static func body() -> FontFile:
	return _load(_BODY)


## Titles, actions and emphasis. Almendra has no variable weight axis (unlike Cinzel), so
## weight is a SEPARATE FILE rather than a `wght` variation — callers ask for a role, not
## a number, which is why this module exposes roles at all.
static func heading() -> FontFile:
	return _load(_BOLD)


## Large ornament only. `px` is the size the caller will draw at; below ORNAMENT_MIN_PX
## this returns the heading face instead, because the hollow glyphs do not survive there
## and a silent smear is worse than a substitution.
static func ornament(px: int) -> FontFile:
	if px < ORNAMENT_MIN_PX:
		push_warning("Fonts.ornament(%d): below %d px the display face is illegible; using heading()."
			% [px, ORNAMENT_MIN_PX])
		return heading()
	return _load(_ORNAMENT)
