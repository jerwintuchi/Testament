class_name Catalog
## PROTOCOL MIRROR — hand-generated from `src/shared/src/gear.ts` and
## `src/shared/src/signs.ts`. Keep in lockstep with @testament/shared: this is
## public requisition data the client renders (ids, names, channels, stimuli),
## never trait semantics.

const BAG_SLOTS := 4

const STIMULI: Array[String] = ["FLAME", "COLD", "SALT", "LIGHT"]

const CHANNELS: Array[String] = ["RESIDUE", "STRESS_MARK", "REACTION", "SPOOR", "LITURGY", "OMEN"]

const GEAR: Array[Dictionary] = [
	# Perception gear — one per channel
	{"id": "ashen-lens",           "name": "Ashen Lens",           "kind": "PERCEPTION", "channel": "RESIDUE"},
	{"id": "chirurgeons-glass",    "name": "Chirurgeon's Glass",   "kind": "PERCEPTION", "channel": "STRESS_MARK"},
	{"id": "witness-prism",        "name": "Witness Prism",        "kind": "PERCEPTION", "channel": "REACTION"},
	{"id": "trackers-fetish",      "name": "Tracker's Fetish",     "kind": "PERCEPTION", "channel": "SPOOR"},
	{"id": "cantors-ear",          "name": "Cantor's Ear",         "kind": "PERCEPTION", "channel": "LITURGY"},
	{"id": "augurs-bead",          "name": "Augur's Bead",         "kind": "PERCEPTION", "channel": "OMEN"},
	# Probe kits — one per stimulus (reusable in v1)
	{"id": "censer-of-embers",     "name": "Censer of Embers",     "kind": "PROBE", "stimulus": "FLAME"},
	{"id": "phial-of-hoarfrost",   "name": "Phial of Hoarfrost",   "kind": "PROBE", "stimulus": "COLD"},
	{"id": "consecrated-salt",     "name": "Consecrated Salt",     "kind": "PROBE", "stimulus": "SALT"},
	{"id": "lantern-of-the-creed", "name": "Lantern of the Creed", "kind": "PROBE", "stimulus": "LIGHT"},
]

static func item_by_id(id: String) -> Dictionary:
	for item in GEAR:
		if item["id"] == id:
			return item
	return {}

static func item_label(item: Dictionary) -> String:
	if item.is_empty():
		return "?"
	if item["kind"] == "PERCEPTION":
		return "%s  (reads %s)" % [item["name"], item["channel"]]
	return "%s  (presents %s)" % [item["name"], item["stimulus"]]

static func short_name(id: String) -> String:
	var item := item_by_id(id)
	return item.get("name", id)
