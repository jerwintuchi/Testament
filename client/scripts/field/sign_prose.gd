## Authored prose for every sign token — what the Seeker WROTE DOWN, in their own hand.
##
## T354 (TD-093). The client used to print the raw wire token, so a player read
## `[STRESS_MARK] flinch-from-flame` and performed no inferential step at all. The
## token is now an OPAQUE IDENTIFIER and never reaches a player; this table is the
## only thing they see.
##
## Why the split lives here rather than in the token (R343): a token is a CONTRACT,
## prose is PRESENTATION. `sign-language.md` commits to Origin as "a presentation
## modifier applied to the token" — impossible if the token IS the string the player
## reads. Keeping them apart means Origin and site dialect can vary the wording later
## without moving a single wire identifier.
##
## P155 — NO STRING BELOW MAY NAME AN AXIS OR A TRAIT VALUE. Writing "frail to flame"
## here would commit on the client exactly the sin the server table stopped
## committing. Enforced by `tools/lexicon_check.py`, which also fails if a token ships
## without prose.
##
## Nothing here is game logic: the sign→meaning map is public game-truth by canon, and
## the trait roll still never crosses the wire (I5).
extends RefCounted

# ── The channel a thing was read through, in the Collegium's language ─────────
#
# The channel is HOW it was perceived, never what it means — so it stays, but as a
# heading a scholar would write rather than a machine label.
const CHANNEL_HEADING := {
	"RESIDUE":     "In the stone",
	"STRESS_MARK": "Where it was struck",
	"REACTION":    "When we presented it",
	"SPOOR":       "On the ground",
	"LITURGY":     "In its devotions",
	"OMEN":        "Before it strikes",
}

# A one-word form for listing what a Seeker can read. The sentence headings above are
# too long to sit on one line — six of them ran off the right edge, which is exactly
# the failure TD-098 made canon. Short enough that the caller can break the list itself.
const CHANNEL_SHORT := {
	"RESIDUE":     "the stone",
	"STRESS_MARK": "wounds",
	"REACTION":    "offerings",
	"SPOOR":       "the ground",
	"LITURGY":     "devotions",
	"OMEN":        "wind-ups",
}

# ── One authored observation per token ───────────────────────────────────────
#
# Each is what a Seeker SAW. The remedy is never written down; the reader supplies it.
const PROSE := {
	# What the fabric of the place remembers.
	"run-wax":        "Candles slumped and pooled in their sconces. Not one of them had ever been burning.",
	"heaved-mortar":  "The joints are split and pushed proud of the wall, as though the stone swelled from within.",
	"bloomed-iron":   "Every nail and hinge has flowered with rust. A century of it, in a season.",
	"weeping-clay":   "The floor gives up water it has no business holding. Footing turns soft where it stood.",

	# What a wound gives up. One law governs these four: the wound names the
	# substance, and the substance names the remedy.
	"tallow-sweat":   "The wound beads a fatty film that will not dry.",
	"fever-sweat":    "It runs hot where it is opened, and steams in the still air.",
	"clear-weep":     "Thin and colourless, and it will not close.",
	"shadow-bleed":   "It smokes dark from the cut. A lamp will not reach the bottom of it.",

	# What it did with what we offered.
	"swallowed-the-brand":  "The fire lay down into it and did not come back.",
	"swallowed-the-rime":   "The chill went in. The air was warmer afterward.",
	"swallowed-the-grain":  "What we scattered darkened, damped, and was gone.",
	"swallowed-the-lamp":   "The lamp dimmed toward it, then steadied wrong.",
	# Deliberately ambiguous: nothing there, or the wrong offering, and no way to
	# tell which (R55/R56). The prose must not resolve what the rule leaves open.
	"no-reaction":          "Nothing answered.",

	# What the ground records.
	"prints-in-our-prints": "Its tread sits inside our own, going the way we came.",
	"still-spoor":          "Sign of it here, and no track of it arriving.",
	"tracks-turn-back":     "Every trail runs to the same reach and turns back.",
	"broken-stride":        "No two strides alike. It ran through what it could have gone around.",

	# The shape of its devotion.
	"worn-knee-stone":      "Two ovals polished into the flagstones, where it stops.",
	"ash-offering":         "What it takes is heaped and burnt. Arranged, not scattered.",
	"covered-dead":         "Nothing it kills is left uncovered.",
	"voided-glyph":         "Inscriptions scratched out. Names struck through.",

	# The wind-up. Transparent BY DESIGN (R341): read in milliseconds while something
	# is about to kill you, so the interpretation budget here is zero.
	"drawn-breath-and-lean": "It draws breath and leans in.",
	"wide-shoulder-coil":    "Its shoulders wind wide.",
	"backward-step-brace":   "A step backward, and it sets itself.",
	"full-body-tremor":      "The whole of it trembles.",
}

## The note for one sign. Falls back to a Seeker who saw something they cannot
## describe rather than to the raw token — an unknown token must never leak the
## identifier to a player, which is the whole point of the split.
static func note(sign: Dictionary) -> String:
	var token: String = str(sign.get("token", ""))
	return PROSE.get(token, "Something here, and no words for it yet.")

## The channel heading, for grouping notes on the field page.
static func heading(channel: String) -> String:
	return CHANNEL_HEADING.get(channel, "Noted")

## What a Seeker can read, as a short list broken across lines by hand.
## Hard breaks, never autowrap: a fixed line count is what makes the measured size
## correct, and six sentence-length headings on one line ran off the screen (TD-098).
static func readable_list(channels: Array, per_line: int = 3) -> String:
	if channels.is_empty():
		return "nothing (you packed no perception gear)"
	var parts: Array[String] = []
	for ch in channels:
		parts.append(CHANNEL_SHORT.get(str(ch), str(ch).to_lower()))
	var lines: Array[String] = []
	for i in range(0, parts.size(), per_line):
		lines.append(", ".join(parts.slice(i, mini(i + per_line, parts.size()))))
	return "\n".join(lines)

## One line for the probe log: who presented what, and what they read.
## The stimulus is the party's OWN choice, so naming it reveals nothing (it is
## echoed straight back by PROBE_RESULT).
static func probe_line(who: String, stimulus: String, sign: Variant) -> String:
	var offering := stimulus.to_lower()
	if sign == null:
		return "%s presented %s. You could not read the answer." % [who, offering]
	return "%s presented %s. %s" % [who, offering, note(sign)]
