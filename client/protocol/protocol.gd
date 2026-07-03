# GENERATED FILE - do not edit by hand.
# Source: src/shared/src (messages.ts, lobby.ts, lobbyMessages.ts, signs.ts, gear.ts)
# Regenerate: pnpm gen:protocol
#
# The wire-protocol contract shared with the authoritative server: message-type
# names, lobby error codes, room phases, sign channels, probe stimuli, the gear
# catalog, and shared scalars. The server reads the same names from src/shared,
# so the two sides cannot drift. Carries wire vocabulary only - never trait data.
#
# Consume via preload, not a global class_name, so it resolves in a headless run
# and on a fresh checkout without an editor reimport:
#   const Protocol = preload("res://protocol/protocol.gd")

# Client -> Server message types.
const CREATE_ROOM := "CREATE_ROOM"
const JOIN_ROOM := "JOIN_ROOM"
const TOGGLE_READY := "TOGGLE_READY"
const ACCEPT_CONTRACT := "ACCEPT_CONTRACT"
const LEAVE_ROOM := "LEAVE_ROOM"
const RECONNECT := "RECONNECT"
const REQUISITION := "REQUISITION"
const DEPLOY := "DEPLOY"
const PROBE := "PROBE"
const EXTRACT := "EXTRACT"

# Server -> Client message types.
const ROOM_CREATED := "ROOM_CREATED"
const LOBBY_UPDATED := "LOBBY_UPDATED"
const RECONNECT_TOKEN := "RECONNECT_TOKEN"
const ROOM_DEPLOYING := "ROOM_DEPLOYING"
const FIELD_STARTED := "FIELD_STARTED"
const PROBE_RESULT := "PROBE_RESULT"
const FIELD_TESTAMENT := "FIELD_TESTAMENT"
const ARCHIVE_UPDATED := "ARCHIVE_UPDATED"
const STATE_RESYNC := "STATE_RESYNC"
const LOBBY_ERROR := "LOBBY_ERROR"

# Lobby error codes (LobbyErrorPayload.code).
const ERR_ROOM_NOT_FOUND := "ROOM_NOT_FOUND"
const ERR_ROOM_FULL := "ROOM_FULL"
const ERR_ALREADY_DEPLOYING := "ALREADY_DEPLOYING"
const ERR_NOT_LEADER := "NOT_LEADER"
const ERR_PARTY_NOT_READY := "PARTY_NOT_READY"
const ERR_INVALID_PAYLOAD := "INVALID_PAYLOAD"
const ERR_NOT_IN_ROOM := "NOT_IN_ROOM"
const ERR_TOKEN_EXPIRED := "TOKEN_EXPIRED"
const ERR_TOKEN_NOT_FOUND := "TOKEN_NOT_FOUND"
const ERR_WRONG_PHASE := "WRONG_PHASE"
const ERR_UNKNOWN_ITEM := "UNKNOWN_ITEM"
const ERR_BAG_OVERFLOW := "BAG_OVERFLOW"
const ERR_MISSING_GEAR := "MISSING_GEAR"

# Room lifecycle phases (LobbySnapshot.phase).
const PHASE_WAITING := "WAITING"
const PHASE_DEPLOYING := "DEPLOYING"
const PHASE_FIELD := "FIELD"
const PHASE_COMPLETE := "COMPLETE"

# Perception channels, canonical order (Sign.channel).
const CHANNELS := ["RESIDUE", "STRESS_MARK", "REACTION", "SPOOR", "LITURGY", "OMEN"]

# Probe stimuli (ProbePayload.stimulus).
const STIMULI := ["FLAME", "COLD", "SALT", "LIGHT"]

# The gear catalog (public requisition data; ids match RequisitionPayload.itemIds).
const GEAR := [
	{"id": "ashen-lens", "name": "Ashen Lens", "kind": "PERCEPTION", "channel": "RESIDUE"},
	{"id": "chirurgeons-glass", "name": "Chirurgeon's Glass", "kind": "PERCEPTION", "channel": "STRESS_MARK"},
	{"id": "witness-prism", "name": "Witness Prism", "kind": "PERCEPTION", "channel": "REACTION"},
	{"id": "trackers-fetish", "name": "Tracker's Fetish", "kind": "PERCEPTION", "channel": "SPOOR"},
	{"id": "cantors-ear", "name": "Cantor's Ear", "kind": "PERCEPTION", "channel": "LITURGY"},
	{"id": "augurs-bead", "name": "Augur's Bead", "kind": "PERCEPTION", "channel": "OMEN"},
	{"id": "censer-of-embers", "name": "Censer of Embers", "kind": "PROBE", "stimulus": "FLAME"},
	{"id": "phial-of-hoarfrost", "name": "Phial of Hoarfrost", "kind": "PROBE", "stimulus": "COLD"},
	{"id": "consecrated-salt", "name": "Consecrated Salt", "kind": "PROBE", "stimulus": "SALT"},
	{"id": "lantern-of-the-creed", "name": "Lantern of the Creed", "kind": "PROBE", "stimulus": "LIGHT"},
]

# Shared scalars.
const MAX_ROOM_PLAYERS := 4
const ROOM_CODE_LENGTH := 6
const BAG_SLOTS := 4
