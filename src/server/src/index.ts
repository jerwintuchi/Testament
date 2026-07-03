// Authoritative game server entry point. Boots the Testament protocol: raw
// WebSocket + JSON envelope (TD-002) wired to the unit-tested message router
// via attachTestamentServer ([bootstrap.ts]). Every inbound message is
// validated by its handler; only the server mutates room state (I1, I2).
import { fileURLToPath } from 'node:url';
import { attachTestamentServer } from './bootstrap.js';

// Handle returned to callers (tests boot on port 0 and need the real port).
export type RunningServer = { port: number; close: () => void };

// Production bootstrap. `ws` is imported lazily so importing this module never
// opens a port; resolves once the server is actually listening.
export async function startServer(port: number): Promise<RunningServer> {
  const { WebSocketServer } = await import('ws');
  const wss = new WebSocketServer({ port });
  attachTestamentServer(wss);
  await new Promise<void>((resolve) => wss.on('listening', () => resolve()));
  const actualPort = (wss.address() as { port: number }).port;
  // eslint-disable-next-line no-console
  console.log(`Testament server listening on :${actualPort}`);
  return {
    port: actualPort,
    close: () => {
      wss.clients.forEach((c) => c.terminate());
      wss.close();
    },
  };
}

const isMain = process.argv[1] !== undefined && process.argv[1] === fileURLToPath(import.meta.url);
if (isMain) {
  void startServer(Number(process.env.PORT) || 3001);
}
