// Guard (protocol-contract R5, reconciled T86): every wire message the server
// emits or routes references the shared registry — no bare wire-name literal in
// an emit/broadcast/case position anywhere in the server source. This is what
// makes the registry (and the GDScript contract generated from it) load-bearing:
// a handler cannot invent or misspell a message name without failing here.
import { describe, it, expect } from 'vitest';
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { CLIENT_MESSAGES, SERVER_MESSAGES } from '@testament/shared';

const SRC_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

function sourceFiles(dir: string): string[] {
  const out: string[] = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) out.push(...sourceFiles(full));
    else if (entry.endsWith('.ts') && !entry.includes('.test.')) out.push(full);
  }
  return out;
}

const WIRE_NAMES = [
  ...Object.values(CLIENT_MESSAGES),
  ...Object.values(SERVER_MESSAGES),
] as string[];

// The wire-speaking positions: emit('X', emitTo(id, 'X', broadcast(code, 'X', case 'X':
function barePositions(source: string, name: string): string[] {
  const hits: string[] = [];
  const patterns = [
    new RegExp(String.raw`emit\(\s*['"]${name}['"]`),
    new RegExp(String.raw`emitTo\([^)]*?['"]${name}['"]`),
    new RegExp(String.raw`broadcast\([^)]*?['"]${name}['"]`),
    new RegExp(String.raw`case\s+['"]${name}['"]\s*:`),
  ];
  for (const p of patterns) {
    const m = source.match(p);
    if (m) hits.push(m[0]);
  }
  return hits;
}

describe('server wire-name literals reference the registry', () => {
  const files = sourceFiles(SRC_ROOT);

  it('scans a plausible surface (router, handlers, bootstrap all present)', () => {
    const names = files.map(f => f.replace(SRC_ROOT, ''));
    expect(names.some(n => n.includes('messageRouter'))).toBe(true);
    expect(names.some(n => n.includes('bootstrap'))).toBe(true);
    expect(names.filter(n => n.includes('handlers')).length).toBeGreaterThan(10);
  });

  it('no emit/emitTo/broadcast/case uses a bare wire-name literal', () => {
    const offenders: string[] = [];
    for (const file of files) {
      const src = readFileSync(file, 'utf8');
      for (const name of WIRE_NAMES) {
        for (const hit of barePositions(src, name)) {
          offenders.push(`${file.replace(SRC_ROOT, 'src')}: ${hit}`);
        }
      }
    }
    expect(offenders, offenders.join('\n')).toEqual([]);
  });

  it('the router and handlers reference the registry constants', () => {
    const router = readFileSync(join(SRC_ROOT, 'rooms', 'messageRouter.ts'), 'utf8');
    expect(router).toContain('CLIENT_MESSAGES.CREATE_ROOM');
    expect(router).toContain('CLIENT_MESSAGES.PROBE');
    const probe = readFileSync(join(SRC_ROOT, 'rooms', 'handlers', 'probe.ts'), 'utf8');
    expect(probe).toContain('SERVER_MESSAGES.PROBE_RESULT');
  });
});
