// The canonical wire-protocol registry: message-type names, the codegen-able
// enums, and the scalar set the GDScript codegen reads. Types and constants only,
// no game logic (invariant I4). These names are the single source of truth that the
// TypeScript server and the GDScript client both consume, so the two cannot drift.
//
// Everything codegen-able is authored as a runtime value (const objects for the
// message names, const string arrays for the enums) with the TypeScript types
// derived from those values. Union types are erased at runtime, so a codegen that
// imports this module must be able to read the values directly.
//
// Import direction is one-way to avoid runtime cycles: the per-domain modules
// (lobby, lobbyMessages, signs, gear) declare their own value arrays next to their
// derived types; this module aggregates them for the codegen and declares only the
// names that belong to the protocol as a whole.
import { MAX_ROOM_PLAYERS, ROOM_CODE_LENGTH } from './lobby.js';
import { BAG_SLOTS } from './gear.js';
import type {
  CreateRoomPayload,
  JoinRoomPayload,
  ToggleReadyPayload,
  AcceptContractPayload,
  SelectContractPayload,
  DeselectContractPayload,
  LeaveRoomPayload,
  ReconnectPayload,
  RequisitionPayload,
  KickPlayerPayload,
  RoomCreatedPayload,
  LobbyUpdatedPayload,
  ReconnectTokenPayload,
  RoomDeployingPayload,
  ContractSelectionPayload,
  StateResyncPayload,
  LobbyErrorPayload,
} from './lobbyMessages.js';
import type {
  DeployPayload,
  ExtractPayload,
  ProbePayload,
  MovePayload,
  FieldStartedPayload,
  ProbeResultPayload,
  PositionsPayload,
  FieldTestamentPayload,
  ArchiveUpdatedPayload,
} from './fieldMessages.js';

// Client -> Server message-type names. Keys are the stable codegen identifiers
// (also the GDScript const names); values are the on-the-wire strings.
export const CLIENT_MESSAGES = {
  CREATE_ROOM: 'CREATE_ROOM',
  JOIN_ROOM: 'JOIN_ROOM',
  TOGGLE_READY: 'TOGGLE_READY',
  ACCEPT_CONTRACT: 'ACCEPT_CONTRACT',
  SELECT_CONTRACT: 'SELECT_CONTRACT',
  DESELECT_CONTRACT: 'DESELECT_CONTRACT',
  LEAVE_ROOM: 'LEAVE_ROOM',
  RECONNECT: 'RECONNECT',
  REQUISITION: 'REQUISITION',
  KICK_PLAYER: 'KICK_PLAYER',
  DEPLOY: 'DEPLOY',
  PROBE: 'PROBE',
  MOVE: 'MOVE',
  EXTRACT: 'EXTRACT',
} as const;
export type ClientMessageType = (typeof CLIENT_MESSAGES)[keyof typeof CLIENT_MESSAGES];

// Server -> Client message-type names.
export const SERVER_MESSAGES = {
  ROOM_CREATED: 'ROOM_CREATED',
  LOBBY_UPDATED: 'LOBBY_UPDATED',
  RECONNECT_TOKEN: 'RECONNECT_TOKEN',
  ROOM_DEPLOYING: 'ROOM_DEPLOYING',
  CONTRACT_SELECTION: 'CONTRACT_SELECTION',
  FIELD_STARTED: 'FIELD_STARTED',
  PROBE_RESULT: 'PROBE_RESULT',
  POSITIONS: 'POSITIONS',
  FIELD_TESTAMENT: 'FIELD_TESTAMENT',
  ARCHIVE_UPDATED: 'ARCHIVE_UPDATED',
  STATE_RESYNC: 'STATE_RESYNC',
  LOBBY_ERROR: 'LOBBY_ERROR',
} as const;
export type ServerMessageType = (typeof SERVER_MESSAGES)[keyof typeof SERVER_MESSAGES];

// Message-name -> payload association. References the existing payload types;
// duplicates no shapes. A registry entry without a payload type here is a bug.
export type ClientMessagePayloads = {
  CREATE_ROOM: CreateRoomPayload;
  JOIN_ROOM: JoinRoomPayload;
  TOGGLE_READY: ToggleReadyPayload;
  ACCEPT_CONTRACT: AcceptContractPayload;
  SELECT_CONTRACT: SelectContractPayload;
  DESELECT_CONTRACT: DeselectContractPayload;
  LEAVE_ROOM: LeaveRoomPayload;
  RECONNECT: ReconnectPayload;
  REQUISITION: RequisitionPayload;
  KICK_PLAYER: KickPlayerPayload;
  DEPLOY: DeployPayload;
  PROBE: ProbePayload;
  MOVE: MovePayload;
  EXTRACT: ExtractPayload;
};
export type ServerMessagePayloads = {
  ROOM_CREATED: RoomCreatedPayload;
  LOBBY_UPDATED: LobbyUpdatedPayload;
  RECONNECT_TOKEN: ReconnectTokenPayload;
  ROOM_DEPLOYING: RoomDeployingPayload;
  CONTRACT_SELECTION: ContractSelectionPayload;
  FIELD_STARTED: FieldStartedPayload;
  PROBE_RESULT: ProbeResultPayload;
  POSITIONS: PositionsPayload;
  FIELD_TESTAMENT: FieldTestamentPayload;
  ARCHIVE_UPDATED: ArchiveUpdatedPayload;
  STATE_RESYNC: StateResyncPayload;
  LOBBY_ERROR: LobbyErrorPayload;
};

// The bounded set of shared scalars that cross to GDScript. They already exist in
// lobby.ts / gear.ts; this set names exactly which ones the codegen emits, so the
// client consumes them instead of hand-duplicating their values.
export const PROTOCOL_SCALARS = {
  MAX_ROOM_PLAYERS,
  ROOM_CODE_LENGTH,
  BAG_SLOTS,
} as const;
