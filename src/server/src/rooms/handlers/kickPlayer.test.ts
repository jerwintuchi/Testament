// T91 (R79, P39): KICK_PLAYER — leader frees a seat held by a disconnected
// player; never a connected one; never in FIELD.
import { describe, it, expect } from 'vitest';
import { handleCreateRoom } from './createRoom.js';
import { handleJoinRoom } from './joinRoom.js';
import { handleKickPlayer } from './kickPlayer.js';
import { handleReconnect } from './reconnect.js';
import { RoomManager } from '../RoomManager.js';
import { ReconnectTokenStore } from '../ReconnectTokenStore.js';
import { SessionArchive } from '../SessionArchive.js';
import type { EmitFn, BroadcastFn } from '../types.js';

function makeEmit() {
  const calls: Array<[string, unknown]> = [];
  const fn: EmitFn = (t, p) => calls.push([t, p]);
  return { fn, calls };
}
function makeBroadcast() {
  const calls: Array<[string, string, unknown]> = [];
  const fn: BroadcastFn = (code, t, p) => calls.push([code, t, p]);
  return { fn, calls };
}

// Host ('host-sock') + joiner ('ghost-sock', named Ghost) in one room; returns
// the joiner's playerId and reconnect token.
function setup() {
  const mgr = new RoomManager();
  const store = new ReconnectTokenStore();
  let code = '';
  handleCreateRoom('host-sock', { displayName: 'Host' }, mgr, store, (t, p) => {
    if (t === 'ROOM_CREATED') code = (p as { snapshot: { roomCode: string } }).snapshot.roomCode;
  });
  let ghostId = '';
  let ghostToken = '';
  handleJoinRoom('ghost-sock', { code, displayName: 'Ghost' }, mgr, store, (t, p) => {
    if (t === 'RECONNECT_TOKEN') {
      const pay = p as { reconnectToken: string; playerId: string };
      ghostId = pay.playerId;
      ghostToken = pay.reconnectToken;
    }
  }, () => {});
  return { mgr, store, code, ghostId, ghostToken };
}

function disconnectGhost(mgr: RoomManager, code: string, ghostId: string): void {
  const player = mgr.getRoom(code)!.players.find(p => p.playerId === ghostId)!;
  player.disconnectedAt = Date.now();
  player.socketId = '';
}

describe('handleKickPlayer', () => {
  it('leader kicks a disconnected player: seat removed, LOBBY_UPDATED broadcast', () => {
    const { mgr, code, ghostId } = setup();
    disconnectGhost(mgr, code, ghostId);
    const { fn: emit, calls: emitCalls } = makeEmit();
    const { fn: broadcast, calls: bcastCalls } = makeBroadcast();

    handleKickPlayer('host-sock', { playerId: ghostId }, mgr, emit, broadcast);

    expect(emitCalls).toHaveLength(0);
    expect(bcastCalls[0]?.[1]).toBe('LOBBY_UPDATED');
    const snap = (bcastCalls[0]?.[2] as { snapshot: { players: Array<{ playerId: string }> } }).snapshot;
    expect(snap.players).toHaveLength(1);
    expect(snap.players.some(p => p.playerId === ghostId)).toBe(false);
  });

  it('CANNOT_KICK for a connected target (P39) and for an unknown target — same code for both', () => {
    const { mgr, code, ghostId } = setup();
    const { fn: emit, calls } = makeEmit();
    const { fn: broadcast, calls: bcastCalls } = makeBroadcast();

    handleKickPlayer('host-sock', { playerId: ghostId }, mgr, emit, broadcast); // still connected
    handleKickPlayer('host-sock', { playerId: 'no-such-player' }, mgr, emit, broadcast);

    expect(calls).toHaveLength(2);
    expect(calls.every(([t, p]) => t === 'LOBBY_ERROR' && (p as { code: string }).code === 'CANNOT_KICK')).toBe(true);
    expect(bcastCalls).toHaveLength(0);
    expect(mgr.getRoom(code)!.players).toHaveLength(2); // nobody removed
  });

  it('NOT_LEADER when a non-leader kicks', () => {
    const { mgr, code, ghostId } = setup();
    disconnectGhost(mgr, code, ghostId);
    // Re-attach the ghost's old socket id to a third connected player to have a non-leader sender.
    const { fn: emit, calls } = makeEmit();
    handleJoinRoom('third-sock', { code, displayName: 'Third' }, mgr, new ReconnectTokenStore(), () => {}, () => {});
    handleKickPlayer('third-sock', { playerId: ghostId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('NOT_LEADER');
  });

  it('WRONG_PHASE in FIELD: mid-expedition seats are sacred', () => {
    const { mgr, code, ghostId } = setup();
    disconnectGhost(mgr, code, ghostId);
    mgr.getRoom(code)!.phase = 'FIELD';
    const { fn: emit, calls } = makeEmit();
    handleKickPlayer('host-sock', { playerId: ghostId }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('WRONG_PHASE');
    expect(mgr.getRoom(code)!.players).toHaveLength(2);
  });

  it('INVALID_PAYLOAD for a malformed payload; NOT_IN_ROOM for an unknown socket', () => {
    const { mgr, ghostId } = setup();
    const { fn: emit, calls } = makeEmit();
    handleKickPlayer('host-sock', { playerId: 42 }, mgr, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('INVALID_PAYLOAD');
    handleKickPlayer('stranger-sock', { playerId: ghostId }, mgr, emit, () => {});
    expect((calls[1]?.[1] as { code: string }).code).toBe('NOT_IN_ROOM');
  });

  it('a kicked player\'s RECONNECT fails: the seat is gone', () => {
    const { mgr, store, code, ghostId, ghostToken } = setup();
    disconnectGhost(mgr, code, ghostId);
    handleKickPlayer('host-sock', { playerId: ghostId }, mgr, () => {}, () => {});

    const { fn: emit, calls } = makeEmit();
    handleReconnect('ghost-new-sock', { token: ghostToken }, mgr, store, new SessionArchive(), emit, () => {});
    expect(calls[0]?.[0]).toBe('LOBBY_ERROR');
    expect((calls[0]?.[1] as { code: string }).code).toBe('ROOM_NOT_FOUND');
  });

  it('the freed seat can be re-joined (the ROOM_FULL ghost-block is gone)', () => {
    const { mgr, store, code, ghostId } = setup();
    // Fill to 4, then ghost one seat.
    handleJoinRoom('s3', { code, displayName: 'P3' }, mgr, store, () => {}, () => {});
    handleJoinRoom('s4', { code, displayName: 'P4' }, mgr, store, () => {}, () => {});
    disconnectGhost(mgr, code, ghostId);

    const { fn: emit, calls } = makeEmit();
    handleJoinRoom('s5', { code, displayName: 'Blocked' }, mgr, store, emit, () => {});
    expect((calls[0]?.[1] as { code: string }).code).toBe('ROOM_FULL');

    handleKickPlayer('host-sock', { playerId: ghostId }, mgr, () => {}, () => {});
    const { fn: emit2, calls: calls2 } = makeEmit();
    handleJoinRoom('s5', { code, displayName: 'Replacement' }, mgr, store, emit2, () => {});
    expect(calls2.some(([t]) => t === 'RECONNECT_TOKEN')).toBe(true);
    expect(mgr.getRoom(code)!.players).toHaveLength(4);
  });
});
