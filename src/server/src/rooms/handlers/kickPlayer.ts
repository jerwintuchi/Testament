import { SERVER_MESSAGES } from '@testament/shared';
import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { toSnapshot } from '../snapshot.js';

// Leader-only: free a seat held by a DISCONNECTED player (R79). Never legal in
// FIELD (mid-expedition seats are sacred) and never against a connected player
// (P39 — no griefing lever). CANNOT_KICK deliberately covers both "no such
// player" and "player is connected" so the response reveals neither.
export function handleKickPlayer(
  socketId: string,
  payload: unknown,
  roomManager: RoomManager,
  emit: EmitFn,
  broadcast: BroadcastFn,
): void {
  const p = payload as Record<string, unknown> | null;
  if (typeof p !== 'object' || p === null || typeof p['playerId'] !== 'string') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: 'Payload must include a string playerId.' });
    return;
  }

  const room = roomManager.getRoomBySocketId(socketId);
  if (!room) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_IN_ROOM', message: 'You are not in any room.' });
    return;
  }

  const sender = room.players.find(pl => pl.socketId === socketId);
  if (!sender?.isLeader) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'NOT_LEADER', message: 'Only the room leader can kick.' });
    return;
  }

  if (room.phase === 'FIELD') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'WRONG_PHASE', message: 'Seats cannot be kicked mid-expedition.' });
    return;
  }

  const targetId = p['playerId'] as string;
  const target = room.players.find(pl => pl.playerId === targetId);
  if (!target || target.disconnectedAt === null) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'CANNOT_KICK', message: 'That player cannot be kicked.' });
    return;
  }

  room.players = room.players.filter(pl => pl.playerId !== targetId);
  broadcast(room.code, SERVER_MESSAGES.LOBBY_UPDATED, { snapshot: toSnapshot(room) });
}
