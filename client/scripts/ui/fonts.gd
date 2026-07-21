extends RefCounted
## Shared font builders (TD-067). Preloaded as `Fonts`, never a global class_name so a
## headless parse/import resolves it (TD-029/30).

# Cinzel (SIL OFL, client/assets/fonts/) — a Roman inscriptional serif, the register carved
# cathedral signage is actually cut in. It carries the header's authority; the default sans
# could only imitate it by letter-spacing, which read as a game UI label, not stone-cut letters.
# The face imports with its OWN antialiasing (see Cinzel.ttf.import) — the project default is
# no-AA for crisp pixel text, which would shatter Cinzel's fine serifs at this size.
# `wght` is a real variable axis on this file (Regular/Bold/Black).
static func cinzel(weight: int) -> FontVariation:
	var base := load("res://assets/fonts/Cinzel.ttf") as FontFile
	if base == null:
		return null
	var fv := FontVariation.new()
	fv.base_font = base
	fv.variation_opentype = {"wght": weight}
	return fv
