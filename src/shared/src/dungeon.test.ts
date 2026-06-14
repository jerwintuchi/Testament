import { describe, it, expect } from 'vitest';
import type {
  Point,
  Rect,
  DungeonRoom,
  Corridor,
  DungeonLayout,
  DungeonConfig,
} from './dungeon.js';

// Compile-time smoke test: instantiate each type to confirm the shapes are
// exported and compile under strict mode.
describe('dungeon types', () => {
  it('instantiate cleanly under strict mode', () => {
    const point: Point = { x: 1, y: 2 };
    const rect: Rect = { x: 0, y: 0, width: 10, height: 8 };
    const room: DungeonRoom = { id: 'room-0', rect };
    const corridor: Corridor = {
      fromRoomId: 'room-0',
      toRoomId: 'room-1',
      from: point,
      to: { x: 5, y: 5 },
    };
    const config: DungeonConfig = {
      width: 100,
      height: 100,
      minLeafSize: 12,
      maxDepth: 4,
      roomPadding: 1,
    };
    const layout: DungeonLayout = {
      runId: 'run-1',
      width: 100,
      height: 100,
      rooms: [room],
      corridors: [corridor],
    };

    expect(layout.rooms[0]?.id).toBe('room-0');
    expect(config.minLeafSize).toBe(12);
    expect(corridor.fromRoomId).toBe('room-0');
  });
});
