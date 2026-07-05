import { SERVER_MESSAGES } from '@testament/shared';
import type { RoomManager } from '../RoomManager.js';
import type { EmitFn } from '../types.js';

// MOVE (R86/R97, invariant I2): the client sends a *direction intent*, never a
// position. We validate the payload, confirm the sender has a body (any walkable
// phase — WAITING/DEPLOYING in the Collegium, FIELD in the site), then store the
// intent. No position math and no broadcast happen here — the authoritative
// movement tick (movementTick.ts) is the sole mover (I1/P44/P50), so client
// message rate can never outrun SEEKER_SPEED.

function isDirComponent(v: unknown): v is number {
  return typeof v === 'number' && Number.isFinite(v) && v >= -1 && v <= 1;
}

export function handleMove(
  socketId: string,
  payload: unknown,
  roomManager: RoomManager,
  emit: EmitFn,
): void {
  const p = payload as Record<string, unknown> | null;
  const dx = p !== null && typeof p === 'object' ? p['dx'] : undefined;
  const dy = p !== null && typeof p === 'object' ? p['dy'] : undefined;
  if (!isDirComponent(dx) || !isDirComponent(dy)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'INVALID_PAYLOAD',
      message: 'MOVE requires finite dx and dy, each in [-1, 1].',
    });
    return;
  }

  const room = roomManager.getRoomBySocketId(socketId);
  if (room === undefined) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return;
  }
  // Legal in any walkable phase; only COMPLETE has no body to move.
  if (room.phase === 'COMPLETE') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'WRONG_PHASE',
      message: `Cannot move in ${room.phase}.`,
    });
    return;
  }

  const sender = room.players.find(pl => pl.socketId === socketId)!;
  sender.moveIntent = { dx, dy };
}
