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
