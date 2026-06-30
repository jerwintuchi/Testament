// Build-time codegen: reads the canonical wire-protocol registry from
// @testament/shared and emits a GDScript constants file the Godot client consumes,
// so the TypeScript server and the GDScript client reference one source and cannot
// drift. Pure plumbing: imports only @testament/shared and the standard library,
// nothing from the server game modules (invariant I4 / trust boundary).
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { mkdirSync, writeFileSync } from 'node:fs';
import {
  CLIENT_MESSAGES,
  SERVER_MESSAGES,
  LOBBY_ERROR_CODES,
  ROOM_STATUSES,
  PROTOCOL_SCALARS,
} from '@testament/shared';

// The runtime values the generator reads. Plain data, so the generator is pure and
// unit-testable without touching @testament/shared directly.
export interface ProtocolInput {
  clientMessages: Record<string, string>;
  serverMessages: Record<string, string>;
  lobbyErrorCodes: readonly string[];
  roomStatuses: readonly string[];
  scalars: Record<string, number>;
}

// Snapshot the live shared registry into a plain ProtocolInput.
export function protocolInputFromShared(): ProtocolInput {
  return {
    clientMessages: { ...CLIENT_MESSAGES },
    serverMessages: { ...SERVER_MESSAGES },
    lobbyErrorCodes: LOBBY_ERROR_CODES,
    roomStatuses: ROOM_STATUSES,
    scalars: { ...PROTOCOL_SCALARS },
  };
}

// The checked-in output path: client/protocol/protocol.gd, relative to this file
// (tools/src/generate.ts -> repo root -> client/protocol/protocol.gd).
export const PROTOCOL_GD_PATH = join(
  dirname(fileURLToPath(import.meta.url)),
  '..',
  '..',
  'client',
  'protocol',
  'protocol.gd',
);

// Turn a wire value into a valid GDScript identifier (UPPER_SNAKE). Used for the
// enum members, whose values may contain characters (a hyphen in 'in-progress')
// that are not legal in an identifier.
function gdIdentifier(value: string): string {
  return value.toUpperCase().replace(/[^A-Z0-9]+/g, '_');
}

function stringConst(name: string, value: string): string {
  return `const ${name} := "${value}"`;
}

function intConst(name: string, value: number): string {
  return `const ${name} := ${value}`;
}

// Pure: same input -> same string. No clock, no randomness, no I/O. Ordering is the
// insertion order of the source objects/arrays, so the output is byte-stable.
export function generateProtocolGd(input: ProtocolInput): string {
  const lines: string[] = [
    '# GENERATED FILE - do not edit by hand.',
    '# Source: src/shared/src/messages.ts',
    '# Regenerate: pnpm gen:protocol',
    '#',
    '# The wire-protocol contract shared with the authoritative server: message-type',
    '# names, lobby error codes, room statuses, and shared scalars. The server reads the',
    '# same names from src/shared, so the two sides cannot drift.',
    '#',
    '# Consume via preload, not a global class_name, so it resolves in a headless run',
    '# and on a fresh checkout without an editor reimport:',
    '#   const Protocol = preload("res://protocol/protocol.gd")',
    '',
    '# Client -> Server message types.',
  ];

  for (const [key, value] of Object.entries(input.clientMessages)) {
    lines.push(stringConst(key, value));
  }

  lines.push('', '# Server -> Client message types.');
  for (const [key, value] of Object.entries(input.serverMessages)) {
    lines.push(stringConst(key, value));
  }

  lines.push('', '# Lobby error codes (LobbyErrorEvent.code).');
  for (const code of input.lobbyErrorCodes) {
    lines.push(stringConst(`ERR_${gdIdentifier(code)}`, code));
  }

  lines.push('', '# Room lifecycle statuses (RoomSummary.status).');
  for (const status of input.roomStatuses) {
    lines.push(stringConst(`STATUS_${gdIdentifier(status)}`, status));
  }

  lines.push('', '# Shared scalars.');
  for (const [key, value] of Object.entries(input.scalars)) {
    lines.push(intConst(key, value));
  }

  return lines.join('\n') + '\n';
}

// The only side-effecting entry: generate and write the file (LF newlines).
export function writeProtocolGd(): string {
  const text = generateProtocolGd(protocolInputFromShared());
  mkdirSync(dirname(PROTOCOL_GD_PATH), { recursive: true });
  writeFileSync(PROTOCOL_GD_PATH, text, { encoding: 'utf8' });
  return PROTOCOL_GD_PATH;
}

// CLI entry (run via `pnpm gen:protocol`). Imported lazily nowhere; only runs when
// this module is the entrypoint.
const isMain =
  process.argv[1] !== undefined && process.argv[1] === fileURLToPath(import.meta.url);
if (isMain) {
  const path = writeProtocolGd();
  // eslint-disable-next-line no-console
  console.log(`Wrote ${path}`);
}
