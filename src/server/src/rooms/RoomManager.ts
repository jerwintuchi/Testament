// Testament Phase 3 RoomManager. In-memory only — never persisted (I7).
import type { RoomCode } from '@testament/shared';
import type { RoomRecord, ServerPlayerEntry } from './types.js';
import { generateRoomCode } from './roomCode.js';
import { stopMovementTick } from './movementTick.js';
import { randomUUID } from 'node:crypto';

export class RoomManager {
  private rooms = new Map<RoomCode, RoomRecord>();

  private uniqueCode(): RoomCode {
    const active = new Set(this.rooms.keys());
    return generateRoomCode(active);
  }

  createRoom(socketId: string, displayName: string): RoomRecord {
    const code = this.uniqueCode();
    const playerId = randomUUID();
    const player: ServerPlayerEntry = {
      playerId,
      displayName,
      socketId,
      isLeader: true,
      readyState: false,
      disconnectedAt: null,
      perceivedChannels: [], bag: [],
      pos: null, moveIntent: { dx: 0, dy: 0 },
    };
    const room: RoomRecord = {
      code,
      phase: 'WAITING',
      players: [player],
      contract: null,
      fieldData: null,
      exposure: 0,
      revealedSigns: [],
      site: null,
      moveTick: null,
    };
    this.rooms.set(code, room);
    return room;
  }

  getRoom(code: RoomCode): RoomRecord | undefined {
    return this.rooms.get(code);
  }

  getRoomBySocketId(socketId: string): RoomRecord | undefined {
    for (const room of this.rooms.values()) {
      if (room.players.some(p => p.socketId === socketId)) return room;
    }
    return undefined;
  }

  destroyRoom(code: RoomCode): void {
    // Stop the movement tick so no timer outlives its room (R96/P52). This is the
    // single teardown choke point — extract-completion, last-player removal, and
    // all-disconnected all route through here, in whatever phase the room died in.
    const room = this.rooms.get(code);
    if (room) stopMovementTick(room);
    this.rooms.delete(code);
  }
}
