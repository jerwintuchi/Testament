import type { LobbySnapshot, FieldSnapshot, PlayerPositions } from '@testament/shared';
import type { RoomRecord } from './types.js';
import type { SessionArchive } from './SessionArchive.js';
import { toPublicPlayer } from './types.js';
import { toContractIntel } from '../incarnate/generateContract.js';
import { deriveAmbientSigns } from '../incarnate/deriveSigns.js';
import { filterSigns } from './perception.js';
import { COLLEGIUM } from '../collegium/collegium.js';

// Pure function. Strips server-only fields before sending to any client (I5, P2).
// Carries the Collegium map + every present player's feet position so a client
// (including a reconnecting one) renders the hall and the party (R98).
export function toSnapshot(room: RoomRecord): LobbySnapshot {
  const positions: PlayerPositions = {};
  for (const p of room.players) {
    if (p.pos !== null) positions[p.playerId] = p.pos;
  }
  return {
    roomCode: room.code,
    phase: room.phase,
    players: room.players.map(toPublicPlayer),
    // The board as intel only — toContractIntel strips expeditionSeed + traitRoll,
    // so no hidden roll ever reaches a client (I3/I5/P58). No Incarnate art field
    // exists on the wire: mystery is the mechanic (vision.md pillar 3).
    board: room.board.map(toContractIntel),
    contract: room.contract ? toContractIntel(room.contract) : null,
    collegium: COLLEGIUM,
    positions,
  };
}

// Returns null when the room is not in FIELD phase (A8) or the player is unknown.
export function buildFieldSnapshot(
  room: RoomRecord,
  archive: SessionArchive,
  playerId: string,
): FieldSnapshot | null {
  if (room.phase !== 'FIELD' || !room.fieldData || !room.contract || !room.site) return null;
  const player = room.players.find(p => p.playerId === playerId);
  if (!player) return null;

  // Every player's current feet position, so the reconnecting client renders the
  // party where they actually are, not at spawn (R89).
  const positions: PlayerPositions = {};
  for (const p of room.players) {
    if (p.pos !== null) positions[p.playerId] = p.pos;
  }
  // Ambient signs plus every reaction sign the party has revealed by probing,
  // filtered to what this player perceives (P24, P28): the reconnecting player
  // recovers exactly what they are entitled to read, nothing more.
  return {
    fieldData:         room.fieldData,
    archiveEntries:    archive.getEntries(room.code),
    signs:             filterSigns(
      [
        ...deriveAmbientSigns(room.contract.traitRoll, room.contract.tier),
        ...room.revealedSigns,
      ],
      player.perceivedChannels,
    ),
    perceivedChannels: player.perceivedChannels,
    site:              room.site,
    positions,
  };
}
