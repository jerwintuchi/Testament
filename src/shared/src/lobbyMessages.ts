// Wire-protocol message payload types for the Lobby & Room system.
// Types only — no logic (invariant I4). All messages use the envelope:
//   { "type": "EVENT_NAME", "payload": { ... } }

import type { LobbySnapshot, RoomCode } from './lobby.js';
import type { ContractIntel } from './contract.js';
import type { FieldSnapshot } from './fieldPhase.js';
import type { ItemId } from './gear.js';

// ── Client → Server ───────────────────────────────────────────────────────────

export type CreateRoomPayload = {
  displayName: string;
};

export type JoinRoomPayload = {
  code: RoomCode;
  displayName: string;
};

export type ToggleReadyPayload = Record<string, never>;

export type AcceptContractPayload = Record<string, never>;

// SELECT_CONTRACT (R110): the leader picks a specific contract off the board by
// its id. This is the acceptance that stakes the Surety and moves to DEPLOYING.
export type SelectContractPayload = {
  contractId: string;
};

export type LeaveRoomPayload = Record<string, never>;

export type ReconnectPayload = {
  token: string;
};

// The whole bag, replace-not-merge: requisition is idempotent and an empty
// array un-packs. Legal only during DEPLOYING (the contract is known, so
// packing is a bet on its intel).
export type RequisitionPayload = {
  itemIds: ItemId[];
};

// Leader-only: free a seat held by a DISCONNECTED player (never a connected
// one — P39) in WAITING or DEPLOYING. Illegal in FIELD: mid-expedition seats
// are sacred (R79).
export type KickPlayerPayload = {
  playerId: string;
};

// ── Server → Client ───────────────────────────────────────────────────────────

export type RoomCreatedPayload = {
  snapshot: LobbySnapshot;
  reconnectToken: string;
};

export type LobbyUpdatedPayload = {
  snapshot: LobbySnapshot;
};

// Sent to a joiner alongside the LOBBY_UPDATED broadcast. Carries the joiner's
// own playerId (self-identification): the broadcast snapshot alone cannot tell
// a joining client which entry is itself.
export type ReconnectTokenPayload = {
  reconnectToken: string;
  playerId: string;
};

export type RoomDeployingPayload = {
  contract: ContractIntel;
};

export type StateResyncPayload = {
  snapshot: LobbySnapshot;
  fieldSnapshot: FieldSnapshot | null;  // null when phase is WAITING or DEPLOYING
  reconnectToken: string;
  playerId: string;   // the reconnecting player's own id — a relaunched client
                      // holds only the token and must relearn which entry it is (R71/R75)
};

// Authored as a runtime array so the GDScript codegen can read it; the
// LobbyErrorCode type is derived from it (one declaration site — protocol-contract R3).
export const LOBBY_ERROR_CODES = [
  'ROOM_NOT_FOUND',
  'ROOM_FULL',
  'ALREADY_DEPLOYING',
  'NOT_LEADER',
  'PARTY_NOT_READY',
  'INVALID_PAYLOAD',
  'NOT_IN_ROOM',
  'TOKEN_EXPIRED',
  'TOKEN_NOT_FOUND',
  'WRONG_PHASE',
  'UNKNOWN_ITEM',    // REQUISITION: an itemId not in GEAR_CATALOG
  'UNKNOWN_CONTRACT', // SELECT_CONTRACT: a contractId not on the board (R110)
  'BAG_OVERFLOW',    // REQUISITION: more items than BAG_SLOTS
  'MISSING_GEAR',    // PROBE: sender does not carry the matching probe kit
  'CANNOT_KICK',     // KICK_PLAYER: target unknown or still connected (deliberately one code for both)
  'NOT_AT_EXTRACTION',      // EXTRACT: sender not within EXTRACTION_RADIUS of the Extraction node (field-space R90)
  'NOT_AT_CONTRACT_BOARD',  // ACCEPT_CONTRACT: leader not within STATION_RADIUS of the Contract Board (R99)
  'NOT_AT_QUARTERMASTER',   // REQUISITION: sender not within STATION_RADIUS of the Quartermaster (R100)
  'NOT_AT_DEPLOY_GATE',     // DEPLOY: leader not within STATION_RADIUS of the Deploy Gate (R101)
] as const;
export type LobbyErrorCode = (typeof LOBBY_ERROR_CODES)[number];

export type LobbyErrorPayload = {
  code: LobbyErrorCode;
  message: string;
};
