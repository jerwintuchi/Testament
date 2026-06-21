import type {
  RelicBoard,
  Relic,
  RelicId,
  PlayerId,
  GamePhase,
  RoomCode,
  RoomStatus,
  BleedClockState,
  RunOutcome,
} from '@veins/shared';

// In-memory game state for one room. Never persisted (netcode invariant I7).
export type Room = {
  id: string;
  code: RoomCode;
  hostId: PlayerId;
  status: RoomStatus;
  runId: string;
  players: PlayerId[];
  board: RelicBoard;
  registry: Map<RelicId, Relic>;
  phase: GamePhase;
  floor: number;
  bleedClock: BleedClockState;
  outcome: RunOutcome | null;
};

// Placeholder tuning — moves to the Bleed Clock spec when that work begins.
const BASE_DRAIN_PER_SECOND = 1;
const DRAIN_INCREASE_PER_FLOOR = 0.5;

// Deeper floors drain the Bleed Clock faster (DESIGN.md).
export function drainRateForFloor(floor: number): number {
  return BASE_DRAIN_PER_SECOND + (floor - 1) * DRAIN_INCREASE_PER_FLOOR;
}

// Descending a floor must NOT touch the Circulatory Board (Circulatory Board
// spec R5) and must NOT reset the Bleed Clock's current value (Bleed Clock spec
// R6). Only the floor counter and the drain rate change; the board carries over
// intact and tension compounds across floors.
export function advanceFloor(room: Room): Room {
  const nextFloor = room.floor + 1;
  return {
    ...room,
    floor: nextFloor,
    bleedClock: {
      ...room.bleedClock,
      drainPerSecond: drainRateForFloor(nextFloor),
    },
    // board is intentionally carried over by reference — never reset.
  };
}
