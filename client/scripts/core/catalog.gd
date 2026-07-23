class_name Catalog
## Display helpers over the generated wire contract. The catalog DATA lives in
## client/protocol/protocol.gd, codegen'd from src/shared (pnpm gen:protocol) —
## nothing here is hand-copied, so the client cannot drift from the server.

const Protocol = preload("res://protocol/protocol.gd")

const BAG_SLOTS := Protocol.BAG_SLOTS
const STIMULI := Protocol.STIMULI
const CHANNELS := Protocol.CHANNELS
const GEAR := Protocol.GEAR

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
