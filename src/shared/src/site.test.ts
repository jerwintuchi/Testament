// T95: field-space wire types + constants (R81). Values are the wire contract
// both the TypeScript server and the GDScript client honor.
import { describe, it, expect } from 'vitest';
import {
  TILE_SIZE,
  FIELD_TICK_HZ,
  SEEKER_SPEED,
  SEEKER_FEET_HALF_WIDTH,
  SEEKER_FEET_HEIGHT,
  EXTRACTION_RADIUS,
  SITE_NODE_KINDS,
  TILE_SOLID,
  TILE_FLOOR,
} from './site.js';
import type { SiteNodeKind, SiteLayout } from './site.js';

describe('field-space constants (R81)', () => {
  it('pins the canonical-grid values both sides depend on', () => {
    expect(TILE_SIZE).toBe(16);
    expect(FIELD_TICK_HZ).toBe(20);
    expect(SEEKER_SPEED).toBe(80);
    expect(SEEKER_FEET_HALF_WIDTH).toBe(5);
    expect(SEEKER_FEET_HEIGHT).toBe(6);
    expect(EXTRACTION_RADIUS).toBe(32);
  });

  it('uses distinct single-char tile glyphs', () => {
    expect(TILE_SOLID).toBe('#');
    expect(TILE_FLOOR).toBe('.');
    expect(TILE_SOLID).not.toBe(TILE_FLOOR);
  });
});

describe('SITE_NODE_KINDS (R81)', () => {
  it('is the TD-018 v1 node vocabulary', () => {
    expect([...SITE_NODE_KINDS]).toEqual(['APPROACH', 'SIGN_SOURCE', 'LAIR', 'EXTRACTION']);
  });

  it('is a runtime array whose members are assignable to SiteNodeKind', () => {
    // Compile-time: every literal in the array is a SiteNodeKind (no drift
    // between the const array the codegen reads and the derived type).
    const kinds: SiteNodeKind[] = [...SITE_NODE_KINDS];
    expect(new Set(kinds).size).toBe(kinds.length);
  });
});

describe('SiteLayout shape (R81)', () => {
  it('accepts a well-formed layout (structural sanity)', () => {
    const layout: SiteLayout = {
      grid: { width: 3, height: 2, rows: ['###', '#.#'] },
      nodes: [{ kind: 'APPROACH', x: 1, y: 1 }],
    };
    expect(layout.grid.rows).toHaveLength(layout.grid.height);
    expect(layout.grid.rows.every(r => r.length === layout.grid.width)).toBe(true);
  });
});
