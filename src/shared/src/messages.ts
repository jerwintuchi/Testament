// The canonical wire-protocol registry: message-type names, the codegen-able
// enums, and the scalar set the GDScript codegen reads. Types and constants only,
// no game logic (invariant I4). These names are the single source of truth that the
// TypeScript server and the GDScript client both consume, so the two cannot drift.
//
// Everything codegen-able is authored as a runtime value (const objects for the
// message names, const string arrays for the enums) with the TypeScript types
// derived from those values. Union types are erased at runtime, so a codegen that
// imports this module must be able to read the values directly; deriving the types
// from the values keeps exactly one source per name.
import { CORRIDOR_HALF_WIDTH, DESIGN_VIEW_HEIGHT } from './dungeon.js';
import { MAX_PLAYERS, MIN_PLAYERS_TO_START } from './lobby.js';
import { PLAYER_RADIUS } from './player.js';
import type {
  MovePlayerRequest,
  RunStartedEvent,
  PlayerMovedEvent,
  PlayerConnectionChangedEvent,
  StateResyncEvent,
} from './events.js';
import type { JoinRoomRequest, RoomUpdateEvent, LobbyErrorEvent } from './lobby.js';

// Client -> Server message-type names. Keys are the stable codegen identifiers
// (also the GDScript const names); values are the on-the-wire strings.
export const CLIENT_MESSAGES = {
  CREATE_ROOM: 'create-room',
  JOIN_ROOM: 'join-room',
  REJOIN: 'rejoin',
  LEAVE_ROOM: 'leave-room',
  START_RUN: 'start-run',
  MOVE_PLAYER: 'move-player',
} as const;
export type ClientMessageType = (typeof CLIENT_MESSAGES)[keyof typeof CLIENT_MESSAGES];

// Server -> Client message-type names.
export const SERVER_MESSAGES = {
  ROOM_UPDATE: 'ROOM_UPDATE',
  RUN_STARTED: 'RUN_STARTED',
  PLAYER_MOVED: 'PLAYER_MOVED',
  STATE_RESYNC: 'STATE_RESYNC',
  PLAYER_CONNECTION_CHANGED: 'PLAYER_CONNECTION_CHANGED',
  LOBBY_ERROR: 'LOBBY_ERROR',
} as const;
export type ServerMessageType = (typeof SERVER_MESSAGES)[keyof typeof SERVER_MESSAGES];

// Message-name -> payload association. The four payload-free messages map to null.
// This references the existing payload interfaces; it duplicates no shapes.
export type ClientMessagePayloads = {
  'create-room': null;
  'join-room': JoinRoomRequest;
  'rejoin': null;
  'leave-room': null;
  'start-run': null;
  'move-player': MovePlayerRequest;
};
export type ServerMessagePayloads = {
  'ROOM_UPDATE': RoomUpdateEvent;
  'RUN_STARTED': RunStartedEvent;
  'PLAYER_MOVED': PlayerMovedEvent;
  'STATE_RESYNC': StateResyncEvent;
  'PLAYER_CONNECTION_CHANGED': PlayerConnectionChangedEvent;
  'LOBBY_ERROR': LobbyErrorEvent;
};

// Lobby error codes, authored as a runtime array so the codegen can read them; the
// LobbyErrorCode type is derived from it. lobby.ts re-derives LobbyErrorEvent.code
// from this, so there is one declaration site.
export const LOBBY_ERROR_CODES = [
  'ROOM_NOT_FOUND',
  'ROOM_FULL',
  'ALREADY_STARTED',
  'ALREADY_IN_ROOM',
  'NOT_ENOUGH_PLAYERS',
  'NOT_IN_ROOM',
  'INVALID_REQUEST',
  'CANNOT_REJOIN',
] as const;
export type LobbyErrorCode = (typeof LOBBY_ERROR_CODES)[number];

// Room lifecycle statuses. lobby.ts re-derives RoomStatus from this array.
export const ROOM_STATUSES = ['lobby', 'in-progress', 'ended'] as const;
export type RoomStatus = (typeof ROOM_STATUSES)[number];

// The bounded set of shared scalars that cross to GDScript. They already exist in
// dungeon.ts / lobby.ts / player.ts; this set names exactly which ones the codegen
// emits, so the client consumes them instead of hand-duplicating their values.
export const PROTOCOL_SCALARS = {
  CORRIDOR_HALF_WIDTH,
  DESIGN_VIEW_HEIGHT,
  MAX_PLAYERS,
  MIN_PLAYERS_TO_START,
  PLAYER_RADIUS,
} as const;
