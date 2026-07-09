import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { atStation } from '../stations.js';
import { toSnapshot } from '../snapshot.js';
import { SERVER_MESSAGES } from '@testament/shared';

// DESELECT_CONTRACT (TD-041): the leader lifts the seal, clearing the party's
// current contract selection. The mirror of handleSelectContract — same gates
// (leader, WAITING, at the Contract Board), reversible, non-committing. A deselect
// with nothing selected is a no-op (idempotent), never an error or a mutation (I2).
export function handleDeselectContract(
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
  if (room.phase !== 'WAITING') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'WRONG_PHASE', message: `Cannot deselect a contract in ${room.phase}.` });
    return;
  }

  const player = room.players.find(pl => pl.socketId === socketId)!;
  if (!player.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the room leader can deselect a contract.' });
    return;
  }
  if (!atStation(player.pos, 'CONTRACT_BOARD')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_AT_CONTRACT_BOARD', message: 'Stand at the Contract Board to deselect a contract.' });
    return;
  }

  // Nothing staked yet — idempotent no-op, no broadcast (I2: no needless mutation).
  const cleared = room.contract;
  if (!cleared) return;

  room.contract = null;
  broadcast(room.code, SERVER_MESSAGES.LOBBY_UPDATED, { snapshot: toSnapshot(room) });
  broadcast(room.code, SERVER_MESSAGES.CONTRACT_SELECTION, {
    accepted: false,
    targetName: cleared.targetName,
    actorName: player.displayName,
  });
}
