import { SERVER_MESSAGES } from '@testament/shared';
import type { RoomManager } from '../RoomManager.js';
import type { EmitFn } from '../types.js';
import { assertPhase } from '../phaseGuard.js';

// MOVE (R86, invariant I2): the client sends a *direction intent*, never a
// position. We validate the payload, confirm the room is in FIELD, then store
// the sender's intent. No position math and no broadcast happen here — the
// authoritative field tick (fieldTick.ts) is the sole mover (I1/P44), so client
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
  if (!assertPhase(room, 'FIELD', emit)) return;

  const sender = room.players.find(pl => pl.socketId === socketId)!;
  sender.moveIntent = { dx, dy };
}
