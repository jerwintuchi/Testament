import { TILE_SIZE, STATION_RADIUS } from '@testament/shared';
import type { StationKind } from '@testament/shared';
import { COLLEGIUM } from '../collegium/collegium.js';

// Spatial gating shared by field extraction (R90) and the Collegium prep
// stations (R99–R101): an action is legal only when the sender's feet are within
// a radius of a place — a node's or station's tile center.

type Pos = { x: number; y: number } | null;

function tileCenterPx(tx: number, ty: number): { x: number; y: number } {
  return { x: tx * TILE_SIZE + TILE_SIZE / 2, y: ty * TILE_SIZE + TILE_SIZE / 2 };
}

// The feet-px center of a Collegium station's tile — where a Seeker must stand to
// use it. Exported so tests can place a player on a station.
export function stationCenterPx(kind: StationKind): { x: number; y: number } {
  const station = COLLEGIUM.stations.find(s => s.kind === kind)!;
  return tileCenterPx(station.x, station.y);
}

// Are `pos` feet within `radiusPx` (Euclidean) of the tile (tx, ty) center? A
// null position (no body) is never within radius.
export function withinRadius(pos: Pos, tx: number, ty: number, radiusPx: number): boolean {
  if (pos === null) return false;
  const c = tileCenterPx(tx, ty);
  return Math.hypot(pos.x - c.x, pos.y - c.y) <= radiusPx;
}

// Is the player standing at the given Collegium station (within STATION_RADIUS)?
export function atStation(pos: Pos, kind: StationKind): boolean {
  const station = COLLEGIUM.stations.find(s => s.kind === kind);
  if (station === undefined) return false;
  return withinRadius(pos, station.x, station.y, STATION_RADIUS);
}
