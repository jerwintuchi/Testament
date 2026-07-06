import type { RoomManager } from './RoomManager.js';
import type { ReconnectTokenStore } from './ReconnectTokenStore.js';
import type { SessionArchive } from './SessionArchive.js';
import type { EmitFn, EmitToFn, BroadcastFn } from './types.js';
import { handleCreateRoom } from './handlers/createRoom.js';
import { handleJoinRoom } from './handlers/joinRoom.js';
import { handleToggleReady } from './handlers/toggleReady.js';
import { handleAcceptContract } from './handlers/acceptContract.js';
import { handleSelectContract } from './handlers/selectContract.js';
import { handleLeaveRoom } from './handlers/leaveRoom.js';
import { handleReconnect } from './handlers/reconnect.js';
import { handleDeploy } from './handlers/deploy.js';
import { handleExtract } from './handlers/extract.js';
import { handleProbe } from './handlers/probe.js';
import { handleMove } from './handlers/move.js';
import { handleRequisition } from './handlers/requisition.js';
import { handleKickPlayer } from './handlers/kickPlayer.js';
import { handleUnknownMessage } from './handlers/unknown.js';
import { CLIENT_MESSAGES, SERVER_MESSAGES } from '@testament/shared';

export function routeMessage(
  socketId: string,
  raw: string,
  roomManager: RoomManager,
  tokenStore: ReconnectTokenStore,
  emit: EmitFn,
  emitTo: EmitToFn,
  broadcast: BroadcastFn,
  sessionArchive: SessionArchive,
): void {
  let parsed: { type?: unknown; payload?: unknown };
  try {
    parsed = JSON.parse(raw) as { type?: unknown; payload?: unknown };
  } catch {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: 'Message is not valid JSON.' });
    return;
  }

  if (typeof parsed.type !== 'string') {
    emit(SERVER_MESSAGES.LOBBY_ERROR, { code: 'INVALID_PAYLOAD', message: 'Message must have a string "type" field.' });
    return;
  }

  const { type, payload } = parsed;

  switch (type) {
    case CLIENT_MESSAGES.CREATE_ROOM:
      handleCreateRoom(socketId, payload, roomManager, tokenStore, emit, broadcast);
      break;
    case CLIENT_MESSAGES.JOIN_ROOM:
      handleJoinRoom(socketId, payload, roomManager, tokenStore, emit, broadcast);
      break;
    case CLIENT_MESSAGES.TOGGLE_READY:
      handleToggleReady(socketId, roomManager, emit, broadcast);
      break;
    case CLIENT_MESSAGES.ACCEPT_CONTRACT:
      handleAcceptContract(socketId, roomManager, emit, broadcast);
      break;
    case CLIENT_MESSAGES.SELECT_CONTRACT:
      handleSelectContract(socketId, payload, roomManager, emit, broadcast);
      break;
    case CLIENT_MESSAGES.LEAVE_ROOM:
      handleLeaveRoom(socketId, roomManager, emit, broadcast);
      break;
    case CLIENT_MESSAGES.RECONNECT:
      handleReconnect(socketId, payload, roomManager, tokenStore, sessionArchive, emit, broadcast);
      break;
    case CLIENT_MESSAGES.DEPLOY:
      handleDeploy(socketId, roomManager, tokenStore, emit, emitTo, broadcast);
      break;
    case CLIENT_MESSAGES.EXTRACT:
      handleExtract(socketId, roomManager, sessionArchive, emit, broadcast);
      break;
    case CLIENT_MESSAGES.PROBE:
      handleProbe(socketId, payload, roomManager, emit, emitTo);
      break;
    case CLIENT_MESSAGES.MOVE:
      handleMove(socketId, payload, roomManager, emit);
      break;
    case CLIENT_MESSAGES.REQUISITION:
      handleRequisition(socketId, payload, roomManager, emit, broadcast);
      break;
    case CLIENT_MESSAGES.KICK_PLAYER:
      handleKickPlayer(socketId, payload, roomManager, emit, broadcast);
      break;
    default:
      handleUnknownMessage(socketId, type, emit);
  }
}
