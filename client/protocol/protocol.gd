# GENERATED FILE - do not edit by hand.
# Source: src/shared/src/messages.ts
# Regenerate: pnpm gen:protocol
#
# The wire-protocol contract shared with the authoritative server: message-type
# names, lobby error codes, room statuses, and shared scalars. The server reads the
# same names from src/shared, so the two sides cannot drift.
#
# Consume via preload, not a global class_name, so it resolves in a headless run
# and on a fresh checkout without an editor reimport:
#   const Protocol = preload("res://protocol/protocol.gd")

# Client -> Server message types.
const CREATE_ROOM := "create-room"
const JOIN_ROOM := "join-room"
const REJOIN := "rejoin"
const LEAVE_ROOM := "leave-room"
const START_RUN := "start-run"
const MOVE_PLAYER := "move-player"

# Server -> Client message types.
const ROOM_UPDATE := "ROOM_UPDATE"
const RUN_STARTED := "RUN_STARTED"
const PLAYER_MOVED := "PLAYER_MOVED"
const STATE_RESYNC := "STATE_RESYNC"
const PLAYER_CONNECTION_CHANGED := "PLAYER_CONNECTION_CHANGED"
const LOBBY_ERROR := "LOBBY_ERROR"

# Lobby error codes (LobbyErrorEvent.code).
const ERR_ROOM_NOT_FOUND := "ROOM_NOT_FOUND"
const ERR_ROOM_FULL := "ROOM_FULL"
const ERR_ALREADY_STARTED := "ALREADY_STARTED"
const ERR_ALREADY_IN_ROOM := "ALREADY_IN_ROOM"
const ERR_NOT_ENOUGH_PLAYERS := "NOT_ENOUGH_PLAYERS"
const ERR_NOT_IN_ROOM := "NOT_IN_ROOM"
const ERR_INVALID_REQUEST := "INVALID_REQUEST"
const ERR_CANNOT_REJOIN := "CANNOT_REJOIN"

# Room lifecycle statuses (RoomSummary.status).
const STATUS_LOBBY := "lobby"
const STATUS_IN_PROGRESS := "in-progress"
const STATUS_ENDED := "ended"

# Shared scalars.
const CORRIDOR_HALF_WIDTH := 20
const DESIGN_VIEW_HEIGHT := 260
const MAX_PLAYERS := 4
const MIN_PLAYERS_TO_START := 1
const PLAYER_RADIUS := 12
