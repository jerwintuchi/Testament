// Production wiring of the Testament protocol (godot-client-catchup spec, R69).
// Pure transport plumbing: the only state owned here is the socketId → socket
// registry (P36); every routing decision — including room membership for
// broadcasts — is derived from RoomManager. No game logic, no game state.
import type { RoomCode } from '@testament/shared';
import { RoomManager } from './rooms/RoomManager.js';
import { ReconnectTokenStore } from './rooms/ReconnectTokenStore.js';
import { SessionArchive } from './rooms/SessionArchive.js';
import { routeMessage } from './rooms/messageRouter.js';
import { handleSocketDisconnect } from './rooms/handlers/disconnect.js';

// The minimal raw-socket surface, satisfied by `ws.WebSocket` and test fakes.
export interface BootSocket {
  send(data: string): void;
  on(event: 'message', cb: (data: { toString(): string }) => void): void;
  on(event: 'close', cb: () => void): void;
}

// The 'connection' surface of `ws.WebSocketServer` (and test fakes).
export interface BootServer {
  on(event: 'connection', cb: (socket: BootSocket) => void): void;
}

export type TestamentServer = {
  roomManager: RoomManager;
  tokenStore: ReconnectTokenStore;
  sessionArchive: SessionArchive;
};

let nextSocketId = 0;

export function attachTestamentServer(wss: BootServer): TestamentServer {
  const roomManager = new RoomManager();
  const tokenStore = new ReconnectTokenStore();
  const sessionArchive = new SessionArchive();
  const sockets = new Map<string, BootSocket>();

  // A socket can close between the membership check and the send; delivery to
  // a dying socket is a no-op, never a crash.
  const send = (socket: BootSocket, type: string, payload: unknown): void => {
    try {
      socket.send(JSON.stringify({ type, payload }));
    } catch {
      /* socket is closing */
    }
  };

  wss.on('connection', (raw) => {
    const socketId = `s${nextSocketId++}`;
    sockets.set(socketId, raw);

    const emit = (type: string, payload: unknown): void => send(raw, type, payload);

    const emitTo = (targetSocketId: string, type: string, payload: unknown): void => {
      const target = sockets.get(targetSocketId);
      if (target) send(target, type, payload);
    };

    // Membership comes from the room's player entries (P35/P36): a player whose
    // socket dropped has socketId '' and is skipped; a reconnected player was
    // rebound to their new socketId by handleReconnect.
    const broadcast = (roomCode: RoomCode, type: string, payload: unknown): void => {
      const room = roomManager.getRoom(roomCode);
      if (!room) return;
      for (const player of room.players) {
        const target = sockets.get(player.socketId);
        if (target) send(target, type, payload);
      }
    };

    raw.on('message', (data) => {
      routeMessage(socketId, data.toString(), roomManager, tokenStore, emit, emitTo, broadcast, sessionArchive);
    });

    raw.on('close', () => {
      // Deregister first so no broadcast triggered by the disconnect (or after
      // it) can ever target the closed socket (P36).
      sockets.delete(socketId);
      handleSocketDisconnect(socketId, roomManager, broadcast);
    });
  });

  return { roomManager, tokenStore, sessionArchive };
}
