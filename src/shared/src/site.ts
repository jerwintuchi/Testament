// Field-space geometry: the wire contract for the site a party deploys into.
// Types and constants only (invariant I4). Generation and collision logic live
// server-side in src/server/src/site/. Geometry is the canonical grid (TD-033):
// 16x16 px tiles, positions are px floats, collision is a feet AABB against
// solid tiles — matching the Seeker's feet-anchor render convention so the
// server collider and the client sprite agree on where a Seeker "is".

// px per tile — the render + collision contract both sides honor.
export const TILE_SIZE = 16;

// Authoritative movement integration rate (Hz). Positions change only on this
// tick, never directly from client input (I1).
export const FIELD_TICK_HZ = 20;

// Seeker movement speed in px/s. Two registers: the default is a run at
// SEEKER_SPEED (~5 tiles/s: deliberate, readable, not twitchy — the register
// combat is designed for, docs/systems/combat.md); holding the walk modifier
// halves it to WALK_SPEED, a precision pace for lining up on stations, edges,
// and extraction. Which register a Seeker is in is a client *intent* (MOVE's
// `walk` flag); the speed itself is applied server-side (I1) — the client never
// decides how fast it moves, only whether it is asking to walk.
export const SEEKER_SPEED = 80;
export const WALK_SPEED = 40;

// The Seeker's collider is a small AABB at the feet (not the whole sprite), so a
// Seeker's head can overlap a wall tile visually while the body stays out. Half
// the collider width, and its height measured up from the feet line, in px.
export const SEEKER_FEET_HALF_WIDTH = 5;
export const SEEKER_FEET_HEIGHT = 6;

// How close (px, Euclidean) a Seeker's feet must be to the Extraction node's
// tile center to leave the field (TD-018: extraction is a place, not a button).
export const EXTRACTION_RADIUS = 32;

// The TD-018 spatial vocabulary, v1 subset. Probe-features and Caches are
// deferred until probing/items are themselves spatial.
export const SITE_NODE_KINDS = ['APPROACH', 'SIGN_SOURCE', 'LAIR', 'EXTRACTION'] as const;
export type SiteNodeKind = (typeof SITE_NODE_KINDS)[number];

// The tile grid. Each row is a string of '#' (solid) and '.' (floor). Compact on
// the wire and trivially parsed by GDScript (row[x] char compare). Invariant:
// rows.length === height and every row's length === width.
export type SiteGrid = {
  width: number;
  height: number;
  rows: string[];
};

// A point of interest, positioned in tile coordinates (not px).
export type SiteNode = {
  kind: SiteNodeKind;
  x: number;
  y: number;
};

// The full field-space layout delivered to clients on deploy and reconnect.
export type SiteLayout = {
  grid: SiteGrid;
  nodes: SiteNode[];
};

// Tile-grid char legend, shared so server generation and any client parser agree.
export const TILE_SOLID = '#';
export const TILE_FLOOR = '.';
