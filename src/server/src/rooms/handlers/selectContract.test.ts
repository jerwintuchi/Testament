// T123 [R110 / P59]: SELECT_CONTRACT validates every gate before any mutation
// (I2) and promotes the *chosen* board entry (never a re-roll). ACCEPT_CONTRACT's
// own tests (acceptContract.test.ts) still pass — it now delegates here.
import { describe, it, expect } from 'vitest';
import { handleCreateRoom } from './createRoom.js';
import { handleToggleReady } from './toggleReady.js';
import { handleSelectContract } from './selectContract.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import { stationCenterPx } from '../stations.js';
import type { EmitFn, BroadcastFn, ServerPlayerEntry } from '../types.js';

function standAt(mgr: RoomManager, socketId: string, kind: 'CONTRACT_BOARD' | 'QUARTERMASTER' | 'DEPLOY_GATE'): void {
  mgr.getRoomBySocketId(socketId)!.players.find(p => p.socketId === socketId)!.pos = stationCenterPx(kind);
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
function readyAtBoard(mgr: RoomManager): void {
  handleToggleReady('host', mgr, () => {}, () => {});
  standAt(mgr, 'host', 'CONTRACT_BOARD');
}

describe('handleSelectContract (R110 / P59)', () => {
  it('a ready leader at the board selects a specific entry → DEPLOYING with THAT contract', () => {
    const { mgr } = setup();
    readyAtBoard(mgr);
    const room = mgr.getRoomBySocketId('host')!;
    const chosen = room.board[2]!;   // a non-first entry, to prove selection is by id
    const { fn: broadcast, calls } = makeBroadcast();
    handleSelectContract('host', { contractId: chosen.contractId }, mgr, () => {}, broadcast);
    expect(room.phase).toBe('DEPLOYING');
    expect(room.contract?.contractId).toBe(chosen.contractId);
    expect(calls[0]?.[1]).toBe('ROOM_DEPLOYING');
    const payload = calls[0]?.[2] as { contract: Record<string, unknown> };
    expect(payload.contract['contractId']).toBe(chosen.contractId);
    expect(Object.keys(payload.contract)).not.toContain('traitRoll');       // intel only (P58)
    expect(Object.keys(payload.contract)).not.toContain('expeditionSeed');
  });

  it('an unknown contractId → UNKNOWN_CONTRACT, nothing mutates', () => {
    const { mgr } = setup();
    readyAtBoard(mgr);
    const room = mgr.getRoomBySocketId('host')!;
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bc } = makeBroadcast();
    handleSelectContract('host', { contractId: 'not-on-the-board' }, mgr, emit, broadcast);
    expect((calls[0]?.[1] as { code: string }).code).toBe('UNKNOWN_CONTRACT');
    expect(room.phase).toBe('WAITING');
    expect(room.contract).toBeNull();
    expect(bc).toHaveLength(0);
  });

  it('a missing contractId → INVALID_PAYLOAD', () => {
    const { mgr } = setup();
    readyAtBoard(mgr);
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('host', {}, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
  });

  it('a non-leader → NOT_LEADER, no mutation', () => {
    const { mgr } = setup();
    const room = mgr.getRoomBySocketId('host')!;
    const p2: ServerPlayerEntry = {
      playerId: 'p2', displayName: 'P2', socketId: 'p2', isLeader: false, readyState: true,
      disconnectedAt: null, perceivedChannels: [], bag: [], pos: null, moveIntent: { dx: 0, dy: 0 },
    };
    room.players.push(p2);
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('p2', { contractId: room.board[0]!.contractId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_LEADER');
    expect(room.phase).toBe('WAITING');
  });

  it('a leader away from the board → NOT_AT_CONTRACT_BOARD', () => {
    const { mgr } = setup();
    handleToggleReady('host', mgr, () => {}, () => {});  // ready, but at spawn, not the board
    const room = mgr.getRoomBySocketId('host')!;
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('host', { contractId: room.board[0]!.contractId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_AT_CONTRACT_BOARD');
  });

  it('a not-ready party → PARTY_NOT_READY', () => {
    const { mgr } = setup();
    standAt(mgr, 'host', 'CONTRACT_BOARD');   // at the board, but host never toggled ready
    const room = mgr.getRoomBySocketId('host')!;
    const { fn: emit, calls } = makeEmit();
    handleSelectContract('host', { contractId: room.board[0]!.contractId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('PARTY_NOT_READY');
  });
});
