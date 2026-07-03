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

export type LobbyErrorCode =
  | 'ROOM_NOT_FOUND'
  | 'ROOM_FULL'
  | 'ALREADY_DEPLOYING'
  | 'NOT_LEADER'
  | 'PARTY_NOT_READY'
  | 'INVALID_PAYLOAD'
  | 'NOT_IN_ROOM'
  | 'TOKEN_EXPIRED'
  | 'TOKEN_NOT_FOUND'
  | 'WRONG_PHASE'
  | 'UNKNOWN_ITEM'    // REQUISITION: an itemId not in GEAR_CATALOG
  | 'BAG_OVERFLOW'    // REQUISITION: more items than BAG_SLOTS
  | 'MISSING_GEAR';   // PROBE: sender does not carry the matching probe kit

export type LobbyErrorPayload = {
  code: LobbyErrorCode;
  message: string;
};
