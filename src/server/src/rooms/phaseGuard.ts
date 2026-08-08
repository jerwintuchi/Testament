import type { RoomPhase } from '@testament/shared';
import type { RoomRecord, EmitFn } from './types.js';
import { SERVER_MESSAGES } from '@testament/shared';

export function assertPhase(
  room: RoomRecord | undefined,
  expected: RoomPhase,
  emit: EmitFn,
): room is RoomRecord {
  if (room === undefined) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return false;
  }
  if (room.phase !== expected) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'WRONG_PHASE',
      message: `Expected ${expected}, room is in ${room.phase}.`,
    });
    return false;
  }
  return true;
}


/**
 * Like `assertPhase`, but for an action legal across more than one phase.
 *
 * Requisition is the first such action (TD-096): the bag is a bet on the contract's
 * intel, so what it actually requires is that the contract is KNOWN and the party has
 * not deployed — which is true from selection onward, not only after the commit.
 */
export function assertAnyPhase(
  room: RoomRecord | undefined,
  expected: readonly RoomPhase[],
  emit: EmitFn,
): room is RoomRecord {
  if (room === undefined) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return false;
  }
  if (!expected.includes(room.phase)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'WRONG_PHASE',
      message: `Expected ${expected.join(' or ')}, room is in ${room.phase}.`,
    });
    return false;
  }
  return true;
}
