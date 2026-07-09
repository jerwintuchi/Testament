// DESELECT_CONTRACT (TD-041): the leader lifts the seal. Mirror of select — same
// gates, reversible, non-committing; a deselect with nothing selected is an
// idempotent no-op (no error, no mutation, no broadcast).
import { describe, it, expect } from 'vitest';
import { handleCreateRoom } from './createRoom.js';
import { handleSelectContract } from './selectContract.js';
import { handleDeselectContract } from './deselectContract.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import { stationCenterPx } from '../stations.js';
import type { EmitFn, BroadcastFn, ServerPlayerEntry } from '../types.js';

function standAt(mgr: RoomManager, socketId: string): void {
  mgr.getRoomBySocketId(socketId)!.players.find(p => p.socketId === socketId)!.pos = stationCenterPx('CONTRACT_BOARD');
}
function makeEmit(): { fn: EmitFn; calls: Array<[string, unknown]> } {
  const calls: Array<[string, unknown]> = [];
  return { fn: (t, p) => calls.push([t, p]), calls };
}
function makeBroadcast(): { fn: BroadcastFn; calls: Array<[string, string, unknown]> } {
  const calls: Array<[string, string, unknown]> = [];
  return { fn: (c, t, p) => calls.push([c, t, p]), calls };
}
function setup() {
  const mgr = new RoomManager();
  handleCreateRoom('host', { displayName: 'Host' }, mgr, new ReconnectTokenStore(), () => {}, () => {});
  return { mgr };
}

describe('handleDeselectContract (TD-041)', () => {
  it('clears a current selection → room.contract null, still WAITING, broadcasts snapshot + un-accepted notice', () => {
    const { mgr } = setup();
    standAt(mgr, 'host');
    const room = mgr.getRoomBySocketId('host')!;
    const chosen = room.board[1]!;
    handleSelectContract('host', { contractId: chosen.contractId }, mgr, () => {}, () => {});
    const { fn: broadcast, calls } = makeBroadcast();
    handleDeselectContract('host', mgr, () => {}, broadcast);

    expect(room.contract).toBeNull();
    expect(room.phase).toBe('WAITING');
    expect(calls[0]?.[1]).toBe('LOBBY_UPDATED');
    const snap = (calls[0]?.[2] as { snapshot: { contract: unknown } }).snapshot;
    expect(snap.contract).toBeNull();
    expect(calls[1]?.[1]).toBe('CONTRACT_SELECTION');
    expect(calls[1]?.[2]).toEqual({ accepted: false, targetName: chosen.targetName, actorName: 'Host' });
  });

  it('deselect with nothing selected → no-op: no error, no mutation, no broadcast', () => {
    const { mgr } = setup();
    standAt(mgr, 'host');
    const room = mgr.getRoomBySocketId('host')!;
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bc } = makeBroadcast();
    handleDeselectContract('host', mgr, emit, broadcast);
    expect(room.contract).toBeNull();
    expect(calls).toHaveLength(0);
    expect(bc).toHaveLength(0);
  });

  it('a non-leader → NOT_LEADER, no mutation', () => {
    const { mgr } = setup();
    standAt(mgr, 'host');
    const room = mgr.getRoomBySocketId('host')!;
    handleSelectContract('host', { contractId: room.board[0]!.contractId }, mgr, () => {}, () => {});
    const p2: ServerPlayerEntry = {
      playerId: 'p2', displayName: 'P2', socketId: 'p2', isLeader: false, readyState: true,
      disconnectedAt: null, perceivedChannels: [], bag: [], pos: stationCenterPx('CONTRACT_BOARD'), moveIntent: { dx: 0, dy: 0 },
    };
    room.players.push(p2);
    const { fn: emit, calls } = makeEmit();
    handleDeselectContract('p2', mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_LEADER');
    expect(room.contract?.contractId).toBe(room.board[0]!.contractId);
  });

  it('a leader who walks away from the board → NOT_AT_CONTRACT_BOARD, selection intact', () => {
    const { mgr } = setup();
    standAt(mgr, 'host');   // select at the board first
    const room = mgr.getRoomBySocketId('host')!;
    handleSelectContract('host', { contractId: room.board[0]!.contractId }, mgr, () => {}, () => {});
    room.players[0]!.pos = { x: 0, y: 0 };   // then walk away
    const { fn: emit, calls } = makeEmit();
    handleDeselectContract('host', mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_AT_CONTRACT_BOARD');
    expect(room.contract?.contractId).toBe(room.board[0]!.contractId);
  });
});
