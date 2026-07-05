import type { SiteLayout, SiteNode, SiteNodeKind } from '@testament/shared';
import { TILE_SOLID, TILE_FLOOR } from '@testament/shared';
import type { Rng } from '../rng/seeded.js';

// Field-space generation (invariants I3/I5): pure and seeded — the same Rng
// state produces an identical SiteLayout, always. The site is a fixed-size tile
// grid of rectangular rooms joined by 2-wide L-corridors, with the TD-018 node
// vocabulary (Approach / Sign-source / Lair / Extraction) placed on room
// centers. All carving stays inside the border, so the border is always solid,
// and rooms are connected in a chain, so every floor tile is reachable from the
// Approach (the property test in generateSite.test.ts verifies both).

const GRID_W = 48;
const GRID_H = 32;
const ROOM_MIN = 5;
const ROOM_MAX = 9;
const MIN_ROOMS = 6;
const MAX_ROOMS = 8;
const PLACEMENT_ATTEMPTS = 300;

type Room = { x: number; y: number; w: number; h: number };

function roomCenter(r: Room): { x: number; y: number } {
  return { x: r.x + (r.w >> 1), y: r.y + (r.h >> 1) };
}

// Two rooms conflict if their 1-tile-buffered rects intersect — keeps rooms
// visually distinct so node placement lands each node in its own room.
function conflicts(a: Room, b: Room): boolean {
  return (
    a.x - 1 < b.x + b.w &&
    b.x - 1 < a.x + a.w &&
    a.y - 1 < b.y + b.h &&
    b.y - 1 < a.y + a.h
  );
}

function manhattan(a: { x: number; y: number }, b: { x: number; y: number }): number {
  return Math.abs(a.x - b.x) + Math.abs(a.y - b.y);
}

export function generateSite(rng: Rng): SiteLayout {
  // Grid of chars, all solid; carving flips tiles to floor.
  const cells: string[][] = Array.from({ length: GRID_H }, () =>
    Array.from({ length: GRID_W }, () => TILE_SOLID),
  );

  const inBounds = (x: number, y: number): boolean =>
    x >= 1 && x <= GRID_W - 2 && y >= 1 && y <= GRID_H - 2;

  const carve = (x: number, y: number): void => {
    if (inBounds(x, y)) cells[y]![x] = TILE_FLOOR;
  };

  // ── Rooms: rejection placement with a 1-tile buffer ──────────────────────
  const targetRooms = rng.int(MIN_ROOMS, MAX_ROOMS);
  const rooms: Room[] = [];
  for (let attempt = 0; attempt < PLACEMENT_ATTEMPTS && rooms.length < targetRooms; attempt++) {
    const w = rng.int(ROOM_MIN, ROOM_MAX);
    const h = rng.int(ROOM_MIN, ROOM_MAX);
    const x = rng.int(1, GRID_W - 1 - w);
    const y = rng.int(1, GRID_H - 1 - h);
    const room: Room = { x, y, w, h };
    if (rooms.some(r => conflicts(room, r))) continue;
    rooms.push(room);
    for (let ry = y; ry < y + h; ry++) {
      for (let rx = x; rx < x + w; rx++) carve(rx, ry);
    }
  }

  // ── Corridors: chain each room to the previous via a 2-wide L ────────────
  // A center-to-center L (horizontal run, then vertical run) makes the room set
  // a connected tree; 2-wide keeps corridors navigable.
  const carveH = (yRow: number, x0: number, x1: number): void => {
    const [lo, hi] = x0 <= x1 ? [x0, x1] : [x1, x0];
    const y2 = yRow + 1 <= GRID_H - 2 ? yRow + 1 : yRow - 1;
    for (let x = lo; x <= hi; x++) {
      carve(x, yRow);
      carve(x, y2);
    }
  };
  const carveV = (xCol: number, y0: number, y1: number): void => {
    const [lo, hi] = y0 <= y1 ? [y0, y1] : [y1, y0];
    const x2 = xCol + 1 <= GRID_W - 2 ? xCol + 1 : xCol - 1;
    for (let y = lo; y <= hi; y++) {
      carve(xCol, y);
      carve(x2, y);
    }
  };

  for (let i = 1; i < rooms.length; i++) {
    const a = roomCenter(rooms[i - 1]!);
    const b = roomCenter(rooms[i]!);
    // Elbow direction chosen by rng, purely cosmetic (both reach b).
    if (rng.int(0, 1) === 0) {
      carveH(a.y, a.x, b.x);
      carveV(b.x, a.y, b.y);
    } else {
      carveV(a.x, a.y, b.y);
      carveH(b.y, a.x, b.x);
    }
  }

  // ── Nodes: Approach / Lair / Extraction / Sign-sources ───────────────────
  const centers = rooms.map(roomCenter);
  const approachIdx = 0;
  const approach = centers[approachIdx]!;

  // Lair: room whose center is farthest (Manhattan) from the Approach.
  let lairIdx = 1;
  for (let i = 1; i < rooms.length; i++) {
    if (manhattan(approach, centers[i]!) > manhattan(approach, centers[lairIdx]!)) lairIdx = i;
  }

  // Extraction: farthest remaining room that is neither Approach nor Lair.
  let extractIdx = -1;
  for (let i = 0; i < rooms.length; i++) {
    if (i === approachIdx || i === lairIdx) continue;
    if (extractIdx === -1 || manhattan(approach, centers[i]!) > manhattan(approach, centers[extractIdx]!)) {
      extractIdx = i;
    }
  }

  // Sign-sources: two distinct remaining rooms (rng-picked from what's left).
  const remaining = rooms
    .map((_, i) => i)
    .filter(i => i !== approachIdx && i !== lairIdx && i !== extractIdx);
  const signIdxs: number[] = [];
  for (let k = 0; k < 2 && remaining.length > 0; k++) {
    const pick = rng.int(0, remaining.length - 1);
    signIdxs.push(remaining.splice(pick, 1)[0]!);
  }

  const nodeAt = (idx: number, kind: SiteNodeKind): SiteNode => ({
    kind,
    x: centers[idx]!.x,
    y: centers[idx]!.y,
  });

  const nodes: SiteNode[] = [
    nodeAt(approachIdx, 'APPROACH'),
    nodeAt(lairIdx, 'LAIR'),
    nodeAt(extractIdx, 'EXTRACTION'),
    ...signIdxs.map(i => nodeAt(i, 'SIGN_SOURCE')),
  ];

  return {
    grid: { width: GRID_W, height: GRID_H, rows: cells.map(row => row.join('')) },
    nodes,
  };
}
