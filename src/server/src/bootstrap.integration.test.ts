// T76 (R69, P35, P36): the PRODUCTION bootstrap — attachTestamentServer — walked
// over real WebSockets through the exact sequence the Godot client emits:
// create → join → ready → accept → requisition → deploy → probe → extract.
// Delivery-scope properties (P35 isolation, P36 no-send-after-close) are proven
// against in-memory fake sockets, where per-socket delivery is exactly recordable.
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { WebSocketServer, WebSocket } from 'ws';
import type { AddressInfo } from 'node:net';
import { attachTestamentServer, type BootServer, type BootSocket, type TestamentServer } from './bootstrap.js';

type Msg = { type: string; payload: unknown };

// ── Real-WebSocket harness (the full walk) ────────────────────────────────────

class TestClient {
  private queue: Msg[] = [];
  private waiters: Array<(msg: Msg) => void> = [];

  constructor(private ws: WebSocket) {
    ws.on('message', (raw) => {
      const msg = JSON.parse(raw.toString()) as Msg;
      const waiter = this.waiters.shift();
      if (waiter) waiter(msg);
      else this.queue.push(msg);
    });
  }

  send(type: string, payload: unknown = {}): void {
    this.ws.send(JSON.stringify({ type, payload }));
  }

  next(): Promise<Msg> {
    return new Promise((resolve) => {
      const queued = this.queue.shift();
      if (queued) resolve(queued);
      else this.waiters.push(resolve);
    });
  }

  close(): void { this.ws.close(); }
}

function connect(port: number): Promise<TestClient> {
  return new Promise((resolve) => {
    const ws = new WebSocket(`ws://localhost:${port}`);
    ws.on('open', () => resolve(new TestClient(ws)));
  });
}

describe('T76: production bootstrap — full protocol walk over real WebSockets (R69)', () => {
  let wss: WebSocketServer;
  let port: number;
  let testament: TestamentServer;

  beforeEach(async () => {
    wss = new WebSocketServer({ port: 0 });
    testament = attachTestamentServer(wss);
    await new Promise<void>((resolve) => wss.on('listening', () => resolve()));
    port = (wss.address() as AddressInfo).port;
  });

  // Extraction is position-gated (R90); stand the player on the Extraction tile
  // so EXTRACT is legal in this end-to-end walk.
  function standAtExtraction(code: string): void {
    const room = testament.roomManager.getRoom(code)!;
    const node = room.site!.nodes.find(n => n.kind === 'EXTRACTION')!;
    const center = { x: node.x * 16 + 8, y: node.y * 16 + 8 };
    for (const p of room.players) p.pos = { ...center };
  }

  afterEach(() => {
    wss.clients.forEach(c => c.terminate());
    wss.close();
  });

  it('create → join → ready → accept → requisition → deploy → probe → extract', async () => {
    // ── Create ──
    const host = await connect(port);
    host.send('CREATE_ROOM', { displayName: 'Host' });
    const created = await host.next();
    expect(created.type).toBe('ROOM_CREATED');
    const createdPayload = created.payload as {
      snapshot: { roomCode: string; players: Array<{ playerId: string }> };
      reconnectToken: string;
    };
    const roomCode = createdPayload.snapshot.roomCode;
    const hostId = createdPayload.snapshot.players[0]!.playerId;
    expect(typeof createdPayload.reconnectToken).toBe('string');

    // ── Join ──
    const p2 = await connect(port);
    p2.send('JOIN_ROOM', { code: roomCode, displayName: 'Scout' });
    expect((await host.next()).type).toBe('LOBBY_UPDATED');
    const p2Lobby = await p2.next();
    expect(p2Lobby.type).toBe('LOBBY_UPDATED');
    const p2Token = await p2.next();
    expect(p2Token.type).toBe('RECONNECT_TOKEN');
    const p2TokenPayload = p2Token.payload as { reconnectToken: string; playerId: string };
    expect(typeof p2TokenPayload.reconnectToken).toBe('string');
    const p2Id = p2TokenPayload.playerId;
    expect(p2Id).not.toBe(hostId); // R71: the joiner knows which entry is itself

    // ── Ready ──
    host.send('TOGGLE_READY');
    await host.next(); await p2.next();
    p2.send('TOGGLE_READY');
    await host.next();
    const afterReady = await p2.next();
    const readySnap = (afterReady.payload as { snapshot: { players: Array<{ readyState: boolean }> } }).snapshot;
    expect(readySnap.players.every(p => p.readyState)).toBe(true);

    // ── Accept contract ──
    host.send('ACCEPT_CONTRACT');
    const deploying = await host.next();
    expect(deploying.type).toBe('ROOM_DEPLOYING');
    const intel = (deploying.payload as { contract: Record<string, unknown> }).contract;
    expect(intel['targetName']).toBeDefined();
    expect(intel['siteName']).toBeDefined();
    expect(Object.keys(intel)).not.toContain('traitRoll');
    expect((await p2.next()).type).toBe('ROOM_DEPLOYING');

    // ── Requisition (host reads REACTION + carries the FLAME kit; p2 reads RESIDUE) ──
    host.send('REQUISITION', { itemIds: ['witness-prism', 'censer-of-embers'] });
    await host.next(); await p2.next();
    p2.send('REQUISITION', { itemIds: ['ashen-lens'] });
    await host.next();
    const bagsSnap = ((await p2.next()).payload as {
      snapshot: { players: Array<{ playerId: string; bag: string[] }> };
    }).snapshot;
    expect(bagsSnap.players.find(p => p.playerId === hostId)?.bag)
      .toEqual(['witness-prism', 'censer-of-embers']);
    expect(bagsSnap.players.find(p => p.playerId === p2Id)?.bag).toEqual(['ashen-lens']);

    // ── Deploy: FIELD_STARTED is per-player (own channels, own token) ──
    host.send('DEPLOY');
    const hostField = await host.next();
    const p2Field = await p2.next();
    expect(hostField.type).toBe('FIELD_STARTED');
    expect(p2Field.type).toBe('FIELD_STARTED');
    const hf = hostField.payload as {
      fieldData: Record<string, unknown>; reconnectToken: string;
      signs: Array<{ channel: string }>; perceivedChannels: string[];
    };
    const pf = p2Field.payload as typeof hf;
    expect(hf.perceivedChannels).toEqual(['REACTION']);
    expect(pf.perceivedChannels).toEqual(['RESIDUE']);
    expect(hf.signs.every(s => hf.perceivedChannels.includes(s.channel))).toBe(true);
    expect(pf.signs.every(s => pf.perceivedChannels.includes(s.channel))).toBe(true);

    // ── Probe: host presents FLAME; only the REACTION perceiver reads the sign ──
    host.send('PROBE', { stimulus: 'FLAME' });
    const hostResult = await host.next();
    const p2Result = await p2.next();
    expect(hostResult.type).toBe('PROBE_RESULT');
    expect(p2Result.type).toBe('PROBE_RESULT');
    const hr = hostResult.payload as { playerId: string; stimulus: string; sign: unknown; exposure: number };
    const pr = p2Result.payload as typeof hr;
    expect(hr.playerId).toBe(hostId);
    expect(hr.stimulus).toBe('FLAME');
    expect(hr.sign).not.toBeNull();      // host carries the Witness Prism
    expect(pr.sign).toBeNull();          // p2 cannot read REACTION
    expect(hr.exposure).toBeGreaterThan(0);

    // ── Extract ──
    standAtExtraction(roomCode);
    host.send('EXTRACT');
    const testament = await host.next();
    expect(testament.type).toBe('FIELD_TESTAMENT');
    expect((testament.payload as { testament: { outcome: string } }).testament.outcome).toBe('success');
    const archive = await host.next();
    expect(archive.type).toBe('ARCHIVE_UPDATED');
    expect((archive.payload as { entries: unknown[] }).entries.length).toBeGreaterThan(0);
    expect((await p2.next()).type).toBe('FIELD_TESTAMENT');
    expect((await p2.next()).type).toBe('ARCHIVE_UPDATED');

    host.close();
    p2.close();
  });
});

// ── Fake-socket harness (delivery-scope properties) ───────────────────────────

class FakeSocket implements BootSocket {
  sent: Msg[] = [];
  private listeners = new Map<string, Array<(data: { toString(): string }) => void>>();

  send(data: string): void { this.sent.push(JSON.parse(data) as Msg); }

  on(event: string, cb: (data: { toString(): string }) => void): void {
    const arr = this.listeners.get(event);
    if (arr) arr.push(cb);
    else this.listeners.set(event, [cb]);
  }

  message(type: string, payload: unknown = {}): void {
    for (const cb of this.listeners.get('message') ?? []) cb(JSON.stringify({ type, payload }));
  }

  close(): void {
    for (const cb of this.listeners.get('close') ?? []) cb('');
  }

  types(): string[] { return this.sent.map(m => m.type); }
}

class FakeServer implements BootServer {
  private connCb?: (socket: BootSocket) => void;
  on(_event: 'connection', cb: (socket: BootSocket) => void): void { this.connCb = cb; }
  connect(): FakeSocket {
    const s = new FakeSocket();
    this.connCb?.(s);
    return s;
  }
}

describe('T76: delivery scope (P35, P36)', () => {
  let server: FakeServer;
  let testament: TestamentServer;

  beforeEach(() => {
    server = new FakeServer();
    testament = attachTestamentServer(server);
  });

  it('P35: broadcasts in one room never reach sockets in another room', () => {
    const a = server.connect();
    a.message('CREATE_ROOM', { displayName: 'Alpha' });
    const b = server.connect();
    b.message('CREATE_ROOM', { displayName: 'Beta' });
    const bBefore = b.sent.length;

    a.message('TOGGLE_READY'); // broadcasts LOBBY_UPDATED in room A only
    expect(a.types().at(-1)).toBe('LOBBY_UPDATED');
    expect(b.sent.length).toBe(bBefore);
  });

  it('P35: emit reaches only the sender (errors are never broadcast)', () => {
    const a = server.connect();
    a.message('CREATE_ROOM', { displayName: 'Alpha' });
    const code = (a.sent[0]!.payload as { snapshot: { roomCode: string } }).snapshot.roomCode;
    const b = server.connect();
    b.message('JOIN_ROOM', { code, displayName: 'Joiner' });
    const aBefore = a.sent.length;

    b.message('ACCEPT_CONTRACT'); // NOT_LEADER error, to b only
    expect(b.types().at(-1)).toBe('LOBBY_ERROR');
    expect(a.sent.length).toBe(aBefore);
  });

  it('P36: a closed socket never receives another message, and its player is marked disconnected', () => {
    const a = server.connect();
    a.message('CREATE_ROOM', { displayName: 'Alpha' });
    const code = (a.sent[0]!.payload as { snapshot: { roomCode: string } }).snapshot.roomCode;
    const b = server.connect();
    b.message('JOIN_ROOM', { code, displayName: 'Joiner' });

    const bBefore = b.sent.length;
    b.close();
    // The disconnect broadcast reaches the surviving player, not the closed socket.
    expect(a.types().at(-1)).toBe('LOBBY_UPDATED');
    expect(b.sent.length).toBe(bBefore);

    // Later broadcasts still skip the closed socket.
    a.message('TOGGLE_READY');
    expect(a.types().at(-1)).toBe('LOBBY_UPDATED');
    expect(b.sent.length).toBe(bBefore);

    const room = testament.roomManager.getRoom(code)!;
    expect(room.players.find(p => p.displayName === 'Joiner')?.disconnectedAt).not.toBeNull();
  });
});

// ── T92 (R78, R79): lobby resilience over the wire ────────────────────────────

describe('T92: ghost-proof acceptance and KICK_PLAYER over real WebSockets', () => {
  let wss: WebSocketServer;
  let port: number;

  beforeEach(async () => {
    wss = new WebSocketServer({ port: 0 });
    attachTestamentServer(wss);
    await new Promise<void>((resolve) => wss.on('listening', () => resolve()));
    port = (wss.address() as AddressInfo).port;
  });

  afterEach(() => {
    wss.clients.forEach(c => c.terminate());
    wss.close();
  });

  async function hostAndGhost() {
    const host = await connect(port);
    host.send('CREATE_ROOM', { displayName: 'Host' });
    const created = await host.next();
    const roomCode = (created.payload as { snapshot: { roomCode: string } }).snapshot.roomCode;

    const p2 = await connect(port);
    p2.send('JOIN_ROOM', { code: roomCode, displayName: 'Ghost' });
    await host.next();                    // LOBBY_UPDATED (join)
    await p2.next();                      // LOBBY_UPDATED (join)
    const tokenMsg = await p2.next();     // RECONNECT_TOKEN
    const { reconnectToken, playerId } = tokenMsg.payload as { reconnectToken: string; playerId: string };

    // Drop WITHOUT readying; the disconnect broadcast is the sync point.
    p2.close();
    const afterDrop = await host.next();
    expect(afterDrop.type).toBe('LOBBY_UPDATED');
    const ghostRow = (afterDrop.payload as {
      snapshot: { players: Array<{ playerId: string; connected: boolean }> };
    }).snapshot.players.find(pl => pl.playerId === playerId);
    expect(ghostRow?.connected).toBe(false);   // R77 visible on the wire

    return { host, roomCode, ghostId: playerId, ghostToken: reconnectToken };
  }

  it('R78: a not-ready ghost does not block ACCEPT_CONTRACT', async () => {
    const { host } = await hostAndGhost();
    host.send('TOGGLE_READY');
    await host.next();                    // LOBBY_UPDATED (ready)
    host.send('ACCEPT_CONTRACT');
    const deploying = await host.next();
    expect(deploying.type).toBe('ROOM_DEPLOYING');
    host.close();
  });

  it('R79: kick frees the seat, a replacement joins, the kicked token is dead', async () => {
    const { host, roomCode, ghostId, ghostToken } = await hostAndGhost();

    host.send('KICK_PLAYER', { playerId: ghostId });
    const afterKick = await host.next();
    expect(afterKick.type).toBe('LOBBY_UPDATED');
    expect((afterKick.payload as { snapshot: { players: unknown[] } }).snapshot.players).toHaveLength(1);

    const p3 = await connect(port);
    p3.send('JOIN_ROOM', { code: roomCode, displayName: 'Replacement' });
    await host.next();                    // LOBBY_UPDATED (join)
    await p3.next();                      // LOBBY_UPDATED
    expect((await p3.next()).type).toBe('RECONNECT_TOKEN');

    const ghostReturn = await connect(port);
    ghostReturn.send('RECONNECT', { token: ghostToken });
    const denied = await ghostReturn.next();
    expect(denied.type).toBe('LOBBY_ERROR');
    expect((denied.payload as { code: string }).code).toBe('ROOM_NOT_FOUND');

    host.close(); p3.close(); ghostReturn.close();
  });
});
