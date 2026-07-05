// T104: Collegium wire types + constants (R92). Values are the wire contract the
// TypeScript server and the GDScript client both honor.
import { describe, it, expect } from 'vitest';
import { STATION_RADIUS, STATION_KINDS } from './collegium.js';
import type { StationKind, Station, CollegiumLayout } from './collegium.js';
import type { SiteGrid } from './site.js';

describe('Collegium constants (R92)', () => {
  it('pins the station gating radius both sides depend on', () => {
    expect(STATION_RADIUS).toBe(24);
  });
});

describe('STATION_KINDS (R92)', () => {
  it('is the v1 prep-station vocabulary', () => {
    expect([...STATION_KINDS]).toEqual(['CONTRACT_BOARD', 'QUARTERMASTER', 'DEPLOY_GATE']);
  });

  it('is a runtime array whose members are assignable to StationKind', () => {
    // Compile-time: no drift between the const array the codegen reads and the
    // derived type.
    const kinds: StationKind[] = [...STATION_KINDS];
    expect(new Set(kinds).size).toBe(kinds.length);
  });
});

describe('CollegiumLayout shape (R92)', () => {
  it('reuses the field-space SiteGrid and carries stations + a spawn anchor', () => {
    const grid: SiteGrid = { width: 3, height: 3, rows: ['###', '#.#', '###'] };
    const station: Station = { kind: 'CONTRACT_BOARD', x: 1, y: 1 };
    const layout: CollegiumLayout = { grid, stations: [station], spawn: { x: 1, y: 1 } };
    expect(layout.grid.rows).toHaveLength(layout.grid.height);
    expect(layout.stations[0]!.kind).toBe('CONTRACT_BOARD');
    expect(layout.spawn).toEqual({ x: 1, y: 1 });
  });
});
