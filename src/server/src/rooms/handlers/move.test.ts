// T99 [R86 / P44]: MOVE is validated before any state change and stores intent
// only — position math happens exclusively on the field tick (T100), never here.
import { describe, it, expect } from 'vitest';
import { handleMove } from './move.js';
import { handleCreateRoom } from './createRoom.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import type { EmitFn } from '../types.js';
import type { RoomPhase } from '@testament/shared';

function makeEmit(): { fn: EmitFn; calls: Array<[string, unknown]> } {
  const calls: Array<[string, unknown]> = [];
  return { fn: (t, p) => calls.push([t, p]), calls };
}

// A solo room forced into FIELD phase; MOVE's only phase precondition is FIELD.
function fieldRoom() {
  const mgr = new RoomManager();
  handleCreateRoom('host', { displayName: 'Host' }, mgr, new ReconnectTokenStore(), () => {});
  const room = mgr.getRoomBySocketId('host')!;
  room.phase = 'FIELD';
  room.players[0]!.pos = { x: 100, y: 100 };
  return { mgr, room };
}

const BAD_PAYLOADS: Array<[string, unknown]> = [
  ['null payload', null],
  ['missing dx', { dy: 0 }],
  ['missing dy', { dx: 0 }],
  ['dx NaN', { dx: NaN, dy: 0 }],
  ['dy Infinity', { dx: 0, dy: Infinity }],
  ['dx string', { dx: '1', dy: 0 }],
  ['dx > 1', { dx: 1.5, dy: 0 }],
  ['dy < -1', { dx: 0, dy: -2 }],
];

describe('handleMove — validation (R86)', () => {
  for (const [label, payload] of BAD_PAYLOADS) {
    it(`${label} → INVALID_PAYLOAD to sender, no intent stored`, () => {
      const { mgr, room } = fieldRoom();
      const { fn: emit, calls } = makeEmit();
      handleMove('host', payload, mgr, emit);
      expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
      expect(room.players[0]!.moveIntent).toEqual({ dx: 0, dy: 0 });
    });
  }

  it('MOVE outside any room → NOT_IN_ROOM, no crash', () => {
    const mgr = new RoomManager();
    const { fn: emit, calls } = makeEmit();
    handleMove('ghost', { dx: 1, dy: 0 }, mgr, emit);
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_IN_ROOM');
  });

  for (const phase of ['WAITING', 'DEPLOYING', 'COMPLETE'] as RoomPhase[]) {
    it(`MOVE in ${phase} phase → WRONG_PHASE, no intent stored`, () => {
      const { mgr, room } = fieldRoom();
      room.phase = phase;
      const { fn: emit, calls } = makeEmit();
      handleMove('host', { dx: 1, dy: 0 }, mgr, emit);
      expect((calls[0]?.[1] as { code: string }).code).toBe('WRONG_PHASE');
      expect(room.players[0]!.moveIntent).toEqual({ dx: 0, dy: 0 });
    });
  }
});

describe('handleMove — success (P44)', () => {
  it('valid MOVE stores intent, emits nothing, moves nothing', () => {
    const { mgr, room } = fieldRoom();
    const before = { ...room.players[0]!.pos! };
    const { fn: emit, calls } = makeEmit();
    handleMove('host', { dx: 1, dy: -1 }, mgr, emit);
    expect(calls).toHaveLength(0);
    expect(room.players[0]!.moveIntent).toEqual({ dx: 1, dy: -1 });
    // Position is untouched — only the tick integrates.
    expect(room.players[0]!.pos).toEqual(before);
  });

  it('boundary values ±1 are accepted', () => {
    const { mgr, room } = fieldRoom();
    const { fn: emit, calls } = makeEmit();
    handleMove('host', { dx: -1, dy: 1 }, mgr, emit);
    expect(calls).toHaveLength(0);
    expect(room.players[0]!.moveIntent).toEqual({ dx: -1, dy: 1 });
  });
});
