// Collegium (staging site) wire types: the party's preparation map. Types and
// constants only (invariant I4). The fixed layout data lives server-side
// (src/server/src/collegium/); this file is the language-neutral contract the
// server sends and the GDScript client renders. Geometry reuses the field-space
// grid (site.ts): 16x16 px tiles, feet-px positions, the same SEEKER_* collider.

import type { SiteGrid } from './site.js';

// How close (px, Euclidean) a Seeker's feet must be to a station's tile center
// to use it — the mirror of EXTRACTION_RADIUS for prep actions. 1.5 tiles.
export const STATION_RADIUS = 24;

// The prep stations. Authored as a runtime array so the GDScript codegen can
// read it; StationKind is derived from it (one declaration site).
export const STATION_KINDS = ['CONTRACT_BOARD', 'QUARTERMASTER', 'DEPLOY_GATE'] as const;
export type StationKind = (typeof STATION_KINDS)[number];

// A prep station, positioned in tile coordinates (not px) — like SiteNode, but
// the Collegium has *stations*, not field nodes; the vocabularies stay separate.
export type Station = {
  kind: StationKind;
  x: number;
  y: number;
};

// The full Collegium layout delivered to clients in the lobby snapshot. Reuses
// the field-space SiteGrid (generic tile geometry). `spawn` is a tile-coord
// anchor the party fans out from on join.
export type CollegiumLayout = {
  grid: SiteGrid;
  stations: Station[];
  spawn: { x: number; y: number };
};
