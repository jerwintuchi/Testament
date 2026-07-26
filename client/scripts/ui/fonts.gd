extends RefCounted
## Shared font builders (TD-067). Preloaded as `Fonts`, never a global class_name so a
## headless parse/import resolves it (TD-029/30).

# Cinzel (SIL OFL, client/assets/fonts/) — a Roman inscriptional serif, the register carved
# cathedral signage is actually cut in. It carries the header's authority; the default sans
# could only imitate it by letter-spacing, which read as a game UI label, not stone-cut letters.
# The face is imported with antialiasing OFF and subpixel positioning DISABLED (Cinzel.ttf.import),
# so it joins the project's no-AA register instead of standing outside it (R264, TD-077). It used to
# carry an exception on the grounds that "its fine serifs shatter at this size" — captured at 3x that
# does not hold: hard edges sharpen the title and the 13px options stay readable, and the Contract
# Board was re-captured before this landed rather than assumed safe.
# `wght` is a real variable axis on this file (Regular/Bold/Black).
static func cinzel(weight: int) -> FontVariation:
	var base := load("res://assets/fonts/Cinzel.ttf") as FontFile
	if base == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	return fv
