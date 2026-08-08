extends RefCounted
## Field records for the Collegium's instruments — the prose half of the catalog.
##
## This lives CLIENT-SIDE deliberately, and the precedent is TD-093: a token is a
## contract, prose is presentation. `GearItem` on the wire carries id, name, kind and
## channel/stimulus — the facts the server validates against. What an instrument reads
## like in the Register is authored here, so re-writing a description is not a wire
## change and never needs codegen.
##
## Keyed by the catalog's own ids, so this file cannot invent an instrument that does
## not exist — `Register.missing_ids()` proves the two stay in step.

const RECORDS := {
	"ashen-lens": {
		"class": "Instrument of Sight",
		"asks":  "What did it leave behind?",
		"note":  "Ground from the glass of a chapel that burned at Ashfen. It settles what ordinary sight passes over.",
		"care":  "The glass clouds if breathed on. Wipe with linen, never the palm.",
	},
	"chirurgeons-glass": {
		"class": "Instrument of Sight",
		"asks":  "What hurts it?",
		"note":  "Infirmary issue, reticled. A wound is measured, not admired — what a thing gives up when cut names what will cut it again.",
		"care":  "Issued from the infirmary. Returned to the infirmary.",
	},
	"witness-prism": {
		"class": "Instrument of Sight",
		"asks":  "What does it shrug off?",
		"note":  "Struck, not blown. Without one the party may offer a stimulus and never learn the answer.",
		"care":  "Carry one between you. The party that offers and cannot read has spent the offering.",
	},
	"trackers-fetish": {
		"class": "Instrument of Sight",
		"asks":  "How does it hunt?",
		"note":  "Three talons on a knot, in the old Choir manner. It reads the manner of a crossing: stalked, waited, or ran.",
		"care":  "Not a charm. It has no virtue of its own and protects nobody.",
	},
	"cantors-ear": {
		"class": "Instrument of Sight",
		"asks":  "How can it be ended without killing?",
		"note":  "Brass, and older than the Collegium's charter. Some things are dismissed rather than killed, and the rite is heard before it is found.",
		"care":  "Deafening at close quarters. Do not sound it beside a companion.",
	},
	"augurs-bead": {
		"class": "Instrument of Sight",
		"asks":  "What does it do before it strikes?",
		"note":  "Weighted lead on a cord. It answers the moment before violence — the only warning the order has ever managed to issue.",
		"care":  "Worth more than the rest of the pack together. Lose it and say so.",
	},
	"censer-of-embers": {
		"class": "Instrument of Trial",
		"asks":  "Offer it flame, and watch.",
		"note":  "Lit at the Collegium and carried burning. What a thing does with fire is a plainer answer than anything it leaves on stone.",
		"care":  "Lit before deployment. It will not be lit for you in the field.",
	},
	"phial-of-hoarfrost": {
		"class": "Instrument of Trial",
		"asks":  "Offer it cold, and watch.",
		"note":  "Cold kept, not weather. It is spent the moment the wax is broken, so the moment is the decision.",
		"care":  "One breaking. Choose the moment.",
	},
	"consecrated-salt": {
		"class": "Instrument of Trial",
		"asks":  "Offer it salt, and watch.",
		"note":  "Blessed at the font and carried open, because a thing that fears it must be able to see it.",
		"care":  "Spilled salt is not replaced on the road.",
	},
	"lantern-of-the-creed": {
		"class": "Instrument of Trial",
		"asks":  "Offer it light, and watch.",
		"note":  "The shutter matters as much as the flame. Light offered is a question; light spilled is an announcement.",
		"care":  "Shuttered when not in use. Assume you are being watched.",
	},
}

const FOOTER := "COLLEGIUM PROPERTY · RETURNED ON EXTRACTION"


static func of(item_id: String) -> Dictionary:
	return RECORDS.get(item_id, {
		"class": "Unclassified",
		"asks":  "",
		"note":  "No record survives for this instrument.",
		"care":  "",
	})


## Ids the catalog has that this file does not, and vice versa. Called by the panel's
## self-check so a new instrument on the wire cannot silently render as "Unclassified".
static func drift(catalog_ids: Array) -> Dictionary:
	var missing: Array = []
	for id in catalog_ids:
		if not RECORDS.has(String(id)):
			missing.append(String(id))
	var orphan: Array = []
	for id in RECORDS.keys():
		if not catalog_ids.has(id):
			orphan.append(String(id))
	return {"missing": missing, "orphan": orphan}
