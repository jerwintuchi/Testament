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
		"note":  "Smoked glass in a brass ring. Held against a surface a manifestation "
			+ "has touched, it settles the ash that ordinary sight passes over.",
		"care":  "The glass clouds if breathed on. Wipe with linen, never the palm.",
	},
	"chirurgeons-glass": {
		"class": "Instrument of Sight",
		"asks":  "What hurts it?",
		"note":  "A surgeon's glass, reticled. It does not magnify a wound so much as "
			+ "measure it — what a thing gives up when cut names what will cut it again.",
		"care":  "Issued from the infirmary. Returned to the infirmary.",
	},
	"witness-prism": {
		"class": "Instrument of Sight",
		"asks":  "What does it shrug off?",
		"note":  "A wedge of struck glass. It reads the answer when something is offered "
			+ "to the Incarnate — without it, a Seeker may present a stimulus and learn nothing.",
		"care":  "Carry one between you. The party that offers and cannot read has spent the offering.",
	},
	"trackers-fetish": {
		"class": "Instrument of Sight",
		"asks":  "How does it hunt?",
		"note":  "Three talons bound at a knot. Held over ground a thing has crossed, it "
			+ "reads the manner of the crossing: whether it stalked, waited, or ran.",
		"care":  "Not a charm. It has no virtue of its own and protects nobody.",
	},
	"cantors-ear": {
		"class": "Instrument of Sight",
		"asks":  "How can it be ended without killing?",
		"note":  "A brass horn for the liturgy under a place. Some things are not killed "
			+ "but dismissed, and the rite that dismisses them is spoken before it is found.",
		"care":  "Deafening at close quarters. Do not sound it beside a companion.",
	},
	"augurs-bead": {
		"class": "Instrument of Sight",
		"asks":  "What does it do before it strikes?",
		"note":  "A weighted bead on a cord. It answers the moment before violence, which "
			+ "is the only warning the Collegium has ever been able to issue.",
		"care":  "Worth more than the rest of the pack together. Lose it and say so.",
	},
	"censer-of-embers": {
		"class": "Instrument of Trial",
		"asks":  "Offer it flame, and watch.",
		"note":  "A pierced thurible of live coals. What a thing does with fire offered to "
			+ "it is a plainer answer than anything it leaves on the stone.",
		"care":  "Lit before deployment. It will not be lit for you in the field.",
	},
	"phial-of-hoarfrost": {
		"class": "Instrument of Trial",
		"asks":  "Offer it cold, and watch.",
		"note":  "Stoppered rime, wax over the cork. The cold in it is not weather; it is "
			+ "kept, and it is spent the moment the seal is broken.",
		"care":  "One breaking. Choose the moment.",
	},
	"consecrated-salt": {
		"class": "Instrument of Trial",
		"asks":  "Offer it salt, and watch.",
		"note":  "Blessed at the Collegium and carried open in a dish, because a thing "
			+ "that fears it must be able to see it.",
		"care":  "Spilled salt is not replaced on the road.",
	},
	"lantern-of-the-creed": {
		"class": "Instrument of Trial",
		"asks":  "Offer it light, and watch.",
		"note":  "A shuttered lamp. The shutter matters as much as the flame: light offered "
			+ "is a question, and light spilled is an announcement.",
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
