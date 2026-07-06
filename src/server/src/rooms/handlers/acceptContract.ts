import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { handleSelectContract } from './selectContract.js';
import { SERVER_MESSAGES } from '@testament/shared';

// ACCEPT_CONTRACT is now a convenience over SELECT_CONTRACT (R110): it selects the
// first board entry, so there is exactly one contract-promotion path (all the
// leader/board/ready/Surety logic lives in handleSelectContract). Kept for the
// existing flow; a client that wants to choose a specific card sends
// SELECT_CONTRACT with its contractId instead.
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
  const first = room.board[0];
  if (!first) {
    // Defensive: the board is always populated at room creation.
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'UNKNOWN_CONTRACT', message: 'The board is empty.' });
    return;
  }
  handleSelectContract(socketId, { contractId: first.contractId }, roomManager, emit, broadcast);
}
