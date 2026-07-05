import type { RoomManager } from '../RoomManager.js';
import type { SessionArchive } from '../SessionArchive.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import { buildStubTestament } from '../testament.js';
import { assertPhase } from '../phaseGuard.js';
import { withinRadius } from '../stations.js';
import { SERVER_MESSAGES, EXTRACTION_RADIUS } from '@testament/shared';

export function handleExtract(
  socketId: string,
  roomManager: RoomManager,
  sessionArchive: SessionArchive,
  emit: EmitFn,
  broadcast: BroadcastFn,
): void {
  const room = roomManager.getRoomBySocketId(socketId);
  if (!assertPhase(room, 'FIELD', emit)) return;

  // Extraction is a place, not a button (TD-018/R90): the sender's feet must be
  // within EXTRACTION_RADIUS of the EXTRACTION node's tile center. Gate before
  // any state change, and error only to the sender (I2).
  const sender = room.players.find(p => p.socketId === socketId)!;
  const extraction = room.site?.nodes.find(n => n.kind === 'EXTRACTION');
  if (!extraction || !withinRadius(sender.pos, extraction.x, extraction.y, EXTRACTION_RADIUS)) {
    emit(SERVER_MESSAGES.LOBBY_ERROR, {
      code: 'NOT_AT_EXTRACTION',
      message: 'You must stand at the Extraction to leave the field.',
    });
    return;
  }

  const testament = buildStubTestament(room);
  const code = room.code;

  room.phase = 'COMPLETE';
  broadcast(code, SERVER_MESSAGES.FIELD_TESTAMENT, { testament });

  sessionArchive.append(code, testament.entries);
  const entries = sessionArchive.getEntries(code);
  broadcast(code, SERVER_MESSAGES.ARCHIVE_UPDATED, { entries });

  roomManager.destroyRoom(code);
  sessionArchive.destroyArchive(code);
}
