## The player-facing display name for a station kind — the one place the wire's enum is turned
## into English. A preloaded RefCounted namespace (S3.2), never a global class_name (TD-029/30).
extends RefCounted

# The wire carries the enum (`CONTRACT_BOARD`); only presentation knows the words. Both the
# proximity prompt in main.gd and the world markers in world/space_view.gd read this table —
# it previously lived in main.gd alone, so the markers rendered the raw enum (TD-071/R224).
const LABEL := {
	"CONTRACT_BOARD": "Contract Board", "QUARTERMASTER": "Quartermaster",
	"DEPLOY_GATE": "Deploy Gate", "EXTRACTION": "Extraction",
}

# Unknown kinds degrade to their raw value, never to blank: a station the server grows before the
# client knows its name must still render something a player can read out (P125).
static func of(kind: String) -> String:
	return LABEL.get(kind, kind)
