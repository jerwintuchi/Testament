import { randomUUID } from 'node:crypto';
import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { allReady } from '../readyCheck.js';
import { atStation } from '../stations.js';
import { createRng, hashSeed } from '../../rng/seeded.js';
import { generateContract, toContractIntel } from '../../incarnate/generateContract.js';
import { SERVER_MESSAGES } from '@testament/shared';

export function handleAcceptContract(
  socketId: string,
  roomManager: RoomManager,
  emit: EmitFn,
  broadcast: BroadcastFn,
): void {
  const room = roomManager.getRoomBySocketId(socketId);
  if (!room) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return;
  }

  const player = room.players.find(p => p.socketId === socketId)!;
  if (!player.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the room leader can accept a contract.' });
    return;
  }
  // Accepting is an action at the Contract Board (R99): the leader must stand
  // there. Gate before any state change, error to the sender only (I2).
  if (!atStation(player.pos, 'CONTRACT_BOARD')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_AT_CONTRACT_BOARD', message: 'Stand at the Contract Board to accept a contract.' });
    return;
  }
  if (!allReady(room.players)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'PARTY_NOT_READY', message: 'All players must be ready before accepting a contract.' });
    return;
  }

  const expeditionSeed = randomUUID();
  const contractId     = randomUUID();
  const rng            = createRng(hashSeed(expeditionSeed));
  const contract       = generateContract(rng, 'APPRENTICE', contractId, expeditionSeed);

  room.phase    = 'DEPLOYING';
  room.contract = contract;
  broadcast(room.code, SERVER_MESSAGES.ROOM_DEPLOYING, { contract: toContractIntel(contract) });
}
