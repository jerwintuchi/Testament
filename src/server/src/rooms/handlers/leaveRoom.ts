import type { RoomManager } from '../RoomManager.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { reassignLeader } from '../leaderElection.js';
import { toSnapshot } from '../snapshot.js';
import { SERVER_MESSAGES } from '@testament/shared';

export function handleLeaveRoom(
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

  const wasLeader = room.players.find(p => p.socketId === socketId)?.isLeader ?? false;
  room.players = room.players.filter(p => p.socketId !== socketId);

  if (room.players.length === 0) {
    roomManager.destroyRoom(room.code);
    return;
  }

  if (wasLeader) {
    room.players = reassignLeader(room.players);
  }

  broadcast(room.code, SERVER_MESSAGES.LOBBY_UPDATED, { snapshot: toSnapshot(room) });
}
