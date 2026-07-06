import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { allReady } from '../readyCheck.js';
import { atStation } from '../stations.js';
import { toContractIntel } from '../../incarnate/generateContract.js';
import { SERVER_MESSAGES } from '@testament/shared';

// SELECT_CONTRACT (R110, invariant I2): the leader picks a contract off the board.
// Selection IS the acceptance that stakes the Surety and moves the room to
// DEPLOYING. Every gate is checked before any mutation, and an error goes to the
// sender only. The chosen contract is PROMOTED from the board — never re-rolled —
// so the hidden trait roll the party will read in the field is the one the board
// was seeded with (the board the party browsed is the expedition they get).
export function handleSelectContract(
  socketId: string,
  payload: unknown,
  roomManager: RoomManager,
  emit: EmitFn,
  broadcast: BroadcastFn,
): void {
  const p = payload as Record<string, unknown> | null;
  const contractId = p !== null && typeof p === 'object' ? p['contractId'] : undefined;
  if (typeof contractId !== 'string') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'INVALID_PAYLOAD',
      message: 'SELECT_CONTRACT requires a contractId string.',
    });
    return;
  }

  const room = roomManager.getRoomBySocketId(socketId);
  if (!room) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return;
  }
  if (room.phase !== 'WAITING') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'WRONG_PHASE', message: `Cannot select a contract in ${room.phase}.` });
    return;
  }

  const player = room.players.find(pl => pl.socketId === socketId)!;
  if (!player.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the room leader can select a contract.' });
    return;
  }
  // Selecting is an action at the Contract Board (R99/R110): gate on position
  // before any state change, error to the sender only (I2).
  if (!atStation(player.pos, 'CONTRACT_BOARD')) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_AT_CONTRACT_BOARD', message: 'Stand at the Contract Board to select a contract.' });
    return;
  }
  if (!allReady(room.players)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'PARTY_NOT_READY', message: 'All players must be ready before selecting a contract.' });
    return;
  }

  const chosen = room.board.find(c => c.contractId === contractId);
  if (!chosen) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'UNKNOWN_CONTRACT', message: 'That contract is not on the board.' });
    return;
  }

  room.contract = chosen;
  room.phase = 'DEPLOYING';
  broadcast(room.code, SERVER_MESSAGES.ROOM_DEPLOYING, { contract: toContractIntel(chosen) });
}
