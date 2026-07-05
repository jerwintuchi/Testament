import type { RoomManager } from '../RoomManager.js';
import type { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { sanitizeDisplayName } from '../sanitize.js';
import { toSnapshot } from '../snapshot.js';
import { spawnInCollegium } from '../collegiumSpawn.js';
import { startMovementTick } from '../movementTick.js';
import { SERVER_MESSAGES } from '@testament/shared';

export function handleCreateRoom(
  socketId: string,
  payload: unknown,
  roomManager: RoomManager,
  tokenStore: ReconnectTokenStore,
  emit: EmitFn,
  broadcast: BroadcastFn,
): void {
  const p = payload as Record<string, unknown> | null;
  if (typeof p !== 'object' || p === null) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: 'Payload must be an object.' });
    return;
  }

  const nameResult = sanitizeDisplayName(p['displayName']);
  if (typeof nameResult === 'object') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: nameResult.reason });
    return;
  }

  const room = roomManager.createRoom(socketId, nameResult);
  const player = room.players[0]!;
  // Spawn the creator into the Collegium and start the movement tick, which now
  // lives for the room's whole walkable life (R95/R96); it collides against the
  // Collegium grid until DEPLOY swaps in the site.
  spawnInCollegium(room, player);
  startMovementTick(room, broadcast);
  const token = tokenStore.issue(player.playerId, room.code);
  emit(SERVER_MESSAGES.ROOM_CREATED, { snapshot: toSnapshot(room), reconnectToken: token });
}
