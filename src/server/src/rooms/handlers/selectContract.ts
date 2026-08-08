import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { atStation } from '../stations.js';
import { canAccept } from '../rank.js';
import { toSnapshot } from '../snapshot.js';
import { SERVER_MESSAGES } from '@testament/shared';

// SELECT_CONTRACT (R110, revised TD-041): the leader stamps a contract off the
// board as the party's chosen one. REVERSIBLE — DESELECT_CONTRACT lifts the seal —
// and NON-committing: no Surety is staked and the phase does not change. The commit
// to DEPLOYING happens later at the Deploy Gate (handleDeploy). Every gate is
// checked before any mutation and errors go to the sender only (I2). The chosen
// contract is PROMOTED from the board — never re-rolled — so the hidden trait roll
// the party reads in the field is the one the board was seeded with.
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

  const chosen = room.board.find(c => c.contractId === contractId);
  if (!chosen) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'UNKNOWN_CONTRACT', message: 'That contract is not on the board.' });
    return;
  }
  // "The board is free, the rank is the gate" (contracts.md, TD-012/TD-095). Every
  // Seeker SEES every writ; Rank decides what they may take responsibility for — and
  // only the ACCEPTING player is checked, never the party (author ruling: rank gates
  // what you may LEAD, not what you may JOIN).
  if (!canAccept(player.rank, chosen.tier)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'RANK_TOO_LOW',
      message: 'Your standing in the Collegium does not answer for this charge.',
    });
    return;
  }

  // Set the party's selection (reversible). The authoritative state travels on the
  // LOBBY_UPDATED snapshot's `contract`; CONTRACT_SELECTION is the transient toast.
  room.contract = chosen;
  broadcast(room.code, SERVER_MESSAGES.LOBBY_UPDATED, { snapshot: toSnapshot(room) });
  broadcast(room.code, SERVER_MESSAGES.CONTRACT_SELECTION, {
    accepted: true,
    targetName: chosen.targetName,
    actorName: player.displayName,
  });
}
