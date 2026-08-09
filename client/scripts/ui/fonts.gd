extends RefCounted
## ⚠ `project.godot` MUST STAY COMMENT-FREE INSIDE A SECTION (TD-102).
##
## Godot's project-settings parser **folds a preceding `#` comment block into the
## following key's name**. `gui/theme/custom_font` carried an explanatory comment from
## TD-097 until 2026-08-09, so the key Godot read was not `theme/custom_font` at all and
## **the project default face was silently Godot's fallback SANS for that entire time** —
## while the canon below claimed Almendra was the default. Call sites asking
## `Fonts.body()/heading()/ornament()` were always correct; only the default was wrong.
##
## Proven before fixing, and reproducible: deleting the comment flipped the Contract
## Board to Almendra (29% of pixels differ, `minhit` 80x53 -> 80x51), and a re-import had
## already rewritten the folded key back out as one long garbage key, deleting the
## setting outright.
##
## FIXED (author's call): the comment is deleted and the key applies. Board re-checked —
## `keepout ok=true`, `hit_ok=true`, all eight writs live. Put the reasons HERE, in a file
## a parser cannot corrupt, never beside the key.
##
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
