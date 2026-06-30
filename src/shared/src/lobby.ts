// Lobby and room types and constants. Types/constants only (invariant I4).
// RoomStatus and the LobbyErrorEvent codes are derived from the runtime arrays in
// messages.ts so the wire vocabulary has a single source the codegen can read.
import type { PlayerId } from './ids.js';
import type { LobbyErrorCode, RoomStatus } from './messages.js';

export const MAX_PLAYERS = 4;
// Solo play is supported: a lone host can start a run. Set DEV_MIN_PLAYERS higher
// (server-side) to force co-op-only behaviour for testing.
export const MIN_PLAYERS_TO_START = 1;

export type RoomCode = string;

export type RoomSummary = {
  code: RoomCode;
  status: RoomStatus;
  hostId: PlayerId;
  players: PlayerId[];
};

// Client -> Server
export type JoinRoomRequest = { code: RoomCode; playerId: PlayerId };

// Server -> client / room
export type RoomUpdateEvent = { room: RoomSummary };

export type LobbyErrorEvent = {
  code: LobbyErrorCode;
  message: string;
};
