// T83 (R69): the production entrypoint itself — startServer — boots the
// Testament protocol. bootstrap.integration.test.ts covers attachTestamentServer;
// this covers the one layer above it that production actually runs.
import { describe, it, expect, afterAll } from 'vitest';
import { WebSocket } from 'ws';
import { startServer, type RunningServer } from './index.js';

type Msg = { type: string; payload: { snapshot: { roomCode: string; players: Array<{ displayName: string }> } } };

describe('T83: startServer', () => {
  let server: RunningServer | undefined;

  afterAll(() => server?.close());

  it('boots on an OS-assigned port and answers CREATE_ROOM with ROOM_CREATED', async () => {
    server = await startServer(0);
    expect(server.port).toBeGreaterThan(0);

    const ws = new WebSocket(`ws://localhost:${server.port}`);
    await new Promise<void>((resolve) => ws.on('open', () => resolve()));
    ws.send(JSON.stringify({ type: 'CREATE_ROOM', payload: { displayName: 'Smoke' } }));

    const msg = await new Promise<Msg>((resolve) =>
      ws.on('message', (raw) => resolve(JSON.parse(raw.toString()) as Msg)));
    expect(msg.type).toBe('ROOM_CREATED');
    expect(msg.payload.snapshot.players[0]?.displayName).toBe('Smoke');
    expect(msg.payload.snapshot.roomCode).toMatch(/^[A-Z2-9]{6}$/);
    ws.close();
  });
});
