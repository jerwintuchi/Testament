import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { allReady } from '../readyCheck.js';
import { atStation } from '../stations.js';
import { toContractIntel } from '../../incarnate/generateContract.js';
import { SERVER_MESSAGES } from '@testament/shared';

// ACCEPT_CONTRACT (legacy convenience, pre-TD-041): a one-shot "select the first
// board entry AND commit" — it stakes acceptance and moves the room straight to
// DEPLOYING, the old single-step flow. The new client flow does NOT use this: it
// selects a specific contract with SELECT_CONTRACT (reversible, non-committing) and
// commits at the Deploy Gate via DEPLOY (TD-041). Kept because it is the terse way
// server tests reach DEPLOYING; retire it once the deploy-commit UX is settled.
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
  if (room.phase !== 'WAITING') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'WRONG_PHASE', message: `Cannot accept a contract in ${room.phase}.` });
    return;
  }

  const player = room.players.find(pl => pl.socketId === socketId)!;
  if (!player.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the room leader can accept a contract.' });
    return;
  }
  if (!atStation(player.pos, 'CONTRACT_BOARD')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_AT_CONTRACT_BOARD', message: 'Stand at the Contract Board to accept a contract.' });
    return;
  }
  if (!allReady(room.players)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'PARTY_NOT_READY', message: 'All players must be ready before accepting a contract.' });
    return;
  }

  const first = room.board[0];
  if (!first) {
    // Defensive: the board is always populated at room creation.
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'UNKNOWN_CONTRACT', message: 'The board is empty.' });
    return;
  }

  room.contract = first;
  room.phase = 'DEPLOYING';
  broadcast(room.code, SERVER_MESSAGES.ROOM_DEPLOYING, { contract: toContractIntel(first) });
}
