// Server-only room types. Never exported from @testament/shared (I4).
import type { RoomCode, RoomPhase, LobbyPlayer, StubFieldData, Sign, Channel, ItemId, SiteLayout } from '@testament/shared';
import type { ContractRecord } from '../incarnate/contractRecord.js';

export type { RoomCode };

export type ServerPlayerEntry = {
  playerId: string;
  displayName: string;
  socketId: string;
  isLeader: boolean;
  readyState: boolean;
  disconnectedAt: number | null;
  // Distributed Perception (R61): empty until DEPLOY assigns. Keyed to the
  // player entry (playerId), not the socket, so it survives reconnection (R63).
  perceivedChannels: Channel[];
  // Loadout (R68): empty until REQUISITION during DEPLOYING; survives reconnection.
  bag: ItemId[];
  // Field-space (R85): feet position in px, null outside FIELD. Set on DEPLOY.
  pos: { x: number; y: number } | null;
  // Last validated MOVE direction (R86); {0,0} = standing. Applied on the tick,
  // never immediately. Cleared to {0,0} on disconnect so ghosts don't drift (R87).
  moveIntent: { dx: number; dy: number };
};

export type RoomRecord = {
  code: RoomCode;
  phase: RoomPhase;
  players: ServerPlayerEntry[];
  contract: ContractRecord | null;
  fieldData: StubFieldData | null;  // null until DEPLOY succeeds; never client-supplied
  exposure: number;                 // field pressure accrued by party behavior; reset on DEPLOY (R57)
  revealedSigns: Sign[];            // reaction signs revealed by probes, deduped by token (R58)
  site: SiteLayout | null;          // field-space geometry; null until DEPLOY generates it (R85)
  fieldTick: NodeJS.Timeout | null; // 20Hz movement integrator; null unless in FIELD (R87/R91)
};

export type ReconnectToken = string;

export type ReconnectEntry = {
  token: ReconnectToken;
  playerId: string;
  roomCode: RoomCode;
  issuedAt: number;
};

// Injected I/O functions — keep handlers pure and unit-testable without a real WebSocket server.
export type EmitFn = (type: string, payload: unknown) => void;
export type EmitToFn = (socketId: string, type: string, payload: unknown) => void;
export type BroadcastFn = (roomCode: RoomCode, type: string, payload: unknown) => void;

// Converts a ServerPlayerEntry to the shared LobbyPlayer type (strips server-only fields).
// Bags are party-visible coordination state (TD-007), not secrets. `connected` is
// derived here from disconnectedAt — the single stored source of liveness (P38).
export function toPublicPlayer(p: ServerPlayerEntry): LobbyPlayer {
  return {
    playerId: p.playerId,
    displayName: p.displayName,
    isLeader: p.isLeader,
    readyState: p.readyState,
    connected: p.disconnectedAt === null,
    bag: p.bag,
  };
}
