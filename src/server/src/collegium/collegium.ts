// The Collegium — the party's fixed preparation hall (R94). Unlike the
// per-expedition site (generateSite), this is hand-authored and never seeded:
// home is stable and recognizable. Server-side content (like GEAR_CATALOG); the
// server sends it over the wire so the client stays a render copy (I1). Only the
// *types* are shared (@testament/shared/collegium).
//
// A single open hall with a central spawn atrium and three prep stations placed
// well apart, so a Seeker must walk to each — the Contract Board (north), the
// Quartermaster (west), and the Deploy Gate (south). Border is solid; every
// station and the spawn anchor sit on floor; the whole floor is one connected
// region (invariant test: collegium.test.ts). The client decorates the tileset;
// the server only needs the wal/floor + station grid.

import type { CollegiumLayout } from '@testament/shared';

// 24×16 tiles (384×256 px). Interior floor is cols 1..22, rows 1..14.
const ROWS: string[] = [
  '########################',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '#......................#',
  '########################',
];

export const COLLEGIUM: CollegiumLayout = {
  grid: { width: 24, height: 16, rows: ROWS },
  spawn: { x: 12, y: 8 },  // central atrium
  stations: [
    { kind: 'CONTRACT_BOARD', x: 12, y: 2 },   // north wall — 6 tiles from spawn
    { kind: 'QUARTERMASTER',  x: 3,  y: 8 },   // west — 9 tiles from spawn
    { kind: 'DEPLOY_GATE',    x: 12, y: 13 },  // south — 5 tiles from spawn
  ],
};
