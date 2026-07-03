// T71: REQUISITION handler — validate, authorize, replace bag, broadcast (R65, P31)
import { describe, it, expect } from 'vitest';
import { handleRequisition } from './requisition.js';
import { handleCreateRoom } from './createRoom.js';
import { handleAcceptContract } from './acceptContract.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import type { EmitFn, BroadcastFn } from '../types.js';
import type { LobbySnapshot } from '@testament/shared';

function makeEmit(): { fn: EmitFn; calls: Array<[string, unknown]> } {
  const calls: Array<[string, unknown]> = [];
  return { fn: (t, p) => calls.push([t, p]), calls };
}
function makeBroadcast(): { fn: BroadcastFn; calls: Array<[string, string, unknown]> } {
  const calls: Array<[string, string, unknown]> = [];
  return { fn: (c, t, p) => calls.push([c, t, p]), calls };
}

// A solo room walked to DEPLOYING (contract accepted, packing is legal).
function setupDeployingRoom() {
  const mgr = new RoomManager();
  const store = new ReconnectTokenStore();
  handleCreateRoom('host', { displayName: 'Host' }, mgr, store, () => {});
  const room = mgr.getRoomBySocketId('host')!;
  room.players[0]!.readyState = true;
  handleAcceptContract('host', mgr, () => {}, () => {});
  return { mgr, room };
}

describe('handleRequisition — validation (R65, P31)', () => {
  it('non-array payload → INVALID_PAYLOAD, bag untouched, no broadcast', () => {
    const { mgr, room } = setupDeployingRoom();
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bcasts } = makeBroadcast();

    handleRequisition('host', { itemIds: 'ashen-lens' }, mgr, emit, broadcast);

    expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
    expect(room.players[0]!.bag).toEqual([]);
    expect(bcasts).toHaveLength(0);
  });

  it('non-string ids → INVALID_PAYLOAD', () => {
    const { mgr } = setupDeployingRoom();
    const { fn: emit, calls } = makeEmit();

    handleRequisition('host', { itemIds: [42] }, mgr, emit, () => {});

    expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
  });

  it('unknown item id → UNKNOWN_ITEM, bag untouched', () => {
    const { mgr, room } = setupDeployingRoom();
    room.players[0]!.bag = ['ashen-lens'];
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bcasts } = makeBroadcast();

    handleRequisition('host', { itemIds: ['sword-of-a-thousand-truths'] }, mgr, emit, broadcast);

    expect((calls[0]?.[1] as { code: string }).code).toBe('UNKNOWN_ITEM');
    expect(room.players[0]!.bag).toEqual(['ashen-lens']);
    expect(bcasts).toHaveLength(0);
  });

  it('duplicate ids → INVALID_PAYLOAD', () => {
    const { mgr } = setupDeployingRoom();
    const { fn: emit, calls } = makeEmit();

    handleRequisition('host', { itemIds: ['ashen-lens', 'ashen-lens'] }, mgr, emit, () => {});

    expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
  });

  it('more than BAG_SLOTS items → BAG_OVERFLOW', () => {
    const { mgr, room } = setupDeployingRoom();
    const { fn: emit, calls } = makeEmit();

    handleRequisition('host', {
      itemIds: ['ashen-lens', 'chirurgeons-glass', 'witness-prism', 'trackers-fetish', 'cantors-ear'],
    }, mgr, emit, () => {});

    expect((calls[0]?.[1] as { code: string }).code).toBe('BAG_OVERFLOW');
    expect(room.players[0]!.bag).toEqual([]);
  });

  it('WAITING phase → WRONG_PHASE (contract not yet known)', () => {
    const mgr = new RoomManager();
    const store = new ReconnectTokenStore();
    handleCreateRoom('host', { displayName: 'Host' }, mgr, store, () => {});
    const { fn: emit, calls } = makeEmit();

    handleRequisition('host', { itemIds: ['ashen-lens'] }, mgr, emit, () => {});

    expect((calls[0]?.[1] as { code: string }).code).toBe('WRONG_PHASE');
  });

  it('no room → NOT_IN_ROOM', () => {
    const { fn: emit, calls } = makeEmit();

    handleRequisition('stranger', { itemIds: [] }, new RoomManager(), emit, () => {});

    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_IN_ROOM');
  });
});

describe('handleRequisition — success path (R65)', () => {
  it('replaces the bag and broadcasts LOBBY_UPDATED with bags in the snapshot', () => {
    const { mgr, room } = setupDeployingRoom();
    const { fn: broadcast, calls: bcasts } = makeBroadcast();

    handleRequisition('host', { itemIds: ['witness-prism', 'phial-of-hoarfrost'] }, mgr, () => {}, broadcast);

    expect(room.players[0]!.bag).toEqual(['witness-prism', 'phial-of-hoarfrost']);
    expect(bcasts).toHaveLength(1);
    expect(bcasts[0]?.[1]).toBe('LOBBY_UPDATED');
    const snapshot = (bcasts[0]?.[2] as { snapshot: LobbySnapshot }).snapshot;
    expect(snapshot.players[0]?.bag).toEqual(['witness-prism', 'phial-of-hoarfrost']);
  });

  it('is replace-not-merge: requisitioning [] empties the bag', () => {
    const { mgr, room } = setupDeployingRoom();
    room.players[0]!.bag = ['ashen-lens'];
    const { fn: broadcast, calls: bcasts } = makeBroadcast();

    handleRequisition('host', { itemIds: [] }, mgr, () => {}, broadcast);

    expect(room.players[0]!.bag).toEqual([]);
    expect(bcasts).toHaveLength(1);
  });

  it('only sets the sender\'s own bag', () => {
    const { mgr, room } = setupDeployingRoom();
    room.players.push({
      playerId: 'p2', displayName: 'P2', socketId: 'p2-sock',
      isLeader: false, readyState: true, disconnectedAt: null,
      perceivedChannels: [], bag: [],
    });

    handleRequisition('p2-sock', { itemIds: ['augurs-bead'] }, mgr, () => {}, () => {});

    expect(room.players[0]!.bag).toEqual([]);
    expect(room.players[1]!.bag).toEqual(['augurs-bead']);
  });
});
