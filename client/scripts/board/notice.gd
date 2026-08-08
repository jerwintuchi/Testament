extends RefCounted
## Procedural notice text (R120/R121) — turns one ContractIntel dict into the
## strings a notice shows: a sacred headline, a preamble, a verb-faithful charge,
## and the petitioner's signature. Pure functions of intel + contractId; no game
## logic, no server calls (I1). Consumed via preload as `Notice`, not a global
## class_name, so it resolves headless (TD-029/30). Static funcs read the const
## grammar below.

# ── Headline: the Collegium's sacred register, a total function of the verb (R120)
const HEADLINE := {
	"INVESTIGATE": "INQUIRY",
	"ELIMINATE":   "SANCTION",
	"CAPTURE":     "CONTAINMENT ORDER",
	"BANISH":      "RITE OF BANISHMENT",
}

# ── Charge grammar (R121): a verb SYNONYM (imperative), a LOCALE frame (where), and
# a QUALIFIER (the intent, restated). Every synonym conveys its verb and the
# qualifier reinforces it, so the verb hint survives the rephrase (P68).
const VERB_SYNONYM := {
	"INVESTIGATE": ["Study", "Observe", "Read", "Chronicle"],
	"ELIMINATE":   ["Put down", "End", "Destroy", "Still"],
	"CAPTURE":     ["Take", "Bind", "Subdue", "Restrain"],
	"BANISH":      ["Banish", "Cast out", "Dispel", "Send back"],
}
const VERB_QUALIFIER := {
	"INVESTIGATE": ["Return with understanding, not a corpse.", "We want it read, not slain.", "Learn its nature, and record it faithfully."],
	"ELIMINATE":   ["See that it stays down.", "Leave nothing behind to rise.", "Silence it, by whatever holy means remain."],
	"CAPTURE":     ["It must arrive alive and whole.", "Deliver it breathing.", "Do not slay what we mean to keep."],
	"BANISH":      ["Steel alone will not do — bring the rite.", "Unmake it by liturgy, not the blade.", "Return it to the dark that bore it."],
}
const CHARGE_LOCALE := ["where it haunts %s", "loosed upon %s", "that troubles %s", "abroad in %s"]

static func headline(verb: String) -> String:
	return str(HEADLINE.get(verb, "CHARGE"))

# The petitioner's concern, one short line, seeded off the id (independent offset).
static func preamble(intel: Dictionary) -> String:
	var req: Dictionary = intel.get("requester", {})
	var role := str(req.get("role", "petitioner"))
	var place := str(req.get("place", "the fold"))
	var frames := [
		"A petition reaches the Archive from %s." % place,
		"Word has come to the Collegium out of %s." % place,
		"The %s of %s has brought this before us." % [role, place],
		"By report from %s, this charge is raised." % place,
	]
	var h := absi((str(intel.get("contractId", "")) + "|pre").hash())
	return str(frames[h % frames.size()])

# The petitioner's PLEA (R191/TD-061): danger as dread in the petitioner's own voice,
# banded by tier — the threat pips are retired ("no knowledge as a number"), so a low
# charge reads routine and a high one reads frightened; the player weighs the fear,
# never a meter. Slots from intel only; seeded off contractId (deterministic, P110).
const PLEA := {
	"VIGIL": [
		"A small unquiet thing; we would know its name.",
		"It has done no great harm yet. We would keep it so.",
		"The signs are faint, but they do not fade.",
		"An oddness only — but oddness, unattended, festers.",
	],
	"INTERDICT": [
		"The parish keeps indoors past vespers now. This is beyond us.",
		"It grows bolder by the week. We cannot say what stays it.",
		"Livestock first. Then the sexton's boy. We fear what is next.",
		"Our own rites have failed twice. We will not try a third.",
	],
	"ANATHEMA": [
		"Two wardens went to look. Neither returned. We beg haste.",
		"We have sealed the road and pray it holds. Come armed and shriven.",
		"Whole households gone silent. None will speak its name aloud.",
		"If the Collegium will not come, we abandon the place to it.",
	],
}

static func plea(intel: Dictionary) -> String:
	var frames: Array = PLEA.get(str(intel.get("tier", "VIGIL")), PLEA["VIGIL"])
	var h := absi((str(intel.get("contractId", "")) + "|plea").hash())
	return str(frames[h % frames.size()])

# The charge itself: <Verb-synonym> the <target>, <locale(site)>. <qualifier>.
static func charge(intel: Dictionary) -> String:
	var verb := str(intel.get("primaryVerb", ""))
	var target := str(intel.get("targetName", "the thing"))
	var site := str(intel.get("siteName", "the site"))
	var syns: Array = VERB_SYNONYM.get(verb, ["Attend"])
	var quals: Array = VERB_QUALIFIER.get(verb, ["Read the signs, and decide."])
	var id := str(intel.get("contractId", ""))
	var word: String = str(syns[absi(id.hash()) % syns.size()])
	var locale: String = str(CHARGE_LOCALE[absi((id + "|loc").hash()) % CHARGE_LOCALE.size()]) % site
	var qual: String = str(quals[absi((id + "|qual").hash()) % quals.size()])
	return "%s %s, %s. %s" % [word, target, locale, qual]

# The signature line: "— <name>, <role> of <place>", or the anonymous form.
static func signature(req: Dictionary) -> String:
	var pname := str(req.get("name", ""))
	var role := str(req.get("role", "petitioner"))
	var place := str(req.get("place", "the Collegium"))
	if pname.is_empty():
		return "— an unnamed %s of %s" % [role, place]
	return "— %s, %s of %s" % [pname, role, place]
