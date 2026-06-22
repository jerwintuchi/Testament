import { describe, it, expect } from 'vitest';
import type {
  EnemySpawnedEvent,
  EnemyDamagedEvent,
  EnemyDiedEvent,
  PlayerDamagedEvent,
  PlayerDownedEvent,
  PlayerRevivedEvent,
  PlayerMovedEvent,
  PhaseChangedEvent,
  PlayerAimChangedEvent,
  ProjectileFiredEvent,
  ProjectileRemovedEvent,
  EnemyMovedEvent,
} from './events.js';

// Compile-time type checks — if these assignments fail the spec is violated.
describe('Combat event types (T2, R10)', () => {
  it('EnemySpawnedEvent carries enemyId, typeId, x, y, hp', () => {
    const e: EnemySpawnedEvent = { enemyId: 'e1', typeId: 'shambler', x: 10, y: 20, hp: 60 };
    expect(e.enemyId).toBe('e1');
    expect(e.typeId).toBe('shambler');
    expect(e.hp).toBe(60);
  });

  it('EnemyDamagedEvent carries enemyId and hp', () => {
    const e: EnemyDamagedEvent = { enemyId: 'e1', hp: 45 };
    expect(e.hp).toBe(45);
  });

  it('EnemyDiedEvent carries enemyId', () => {
    const e: EnemyDiedEvent = { enemyId: 'e1' };
    expect(e.enemyId).toBe('e1');
  });

  it('PlayerDamagedEvent carries playerId and hp', () => {
    const e: PlayerDamagedEvent = { playerId: 'p1', hp: 85 };
    expect(e.playerId).toBe('p1');
    expect(e.hp).toBe(85);
  });

  it('PlayerDownedEvent carries playerId', () => {
    const e: PlayerDownedEvent = { playerId: 'p1' };
    expect(e.playerId).toBe('p1');
  });

  it('PlayerRevivedEvent carries playerId and hp', () => {
    const e: PlayerRevivedEvent = { playerId: 'p1', hp: 100 };
    expect(e.hp).toBe(100);
  });

  it('PlayerMovedEvent carries playerId, x, y', () => {
    const e: PlayerMovedEvent = { playerId: 'p1', x: 5, y: 10 };
    expect(e.x).toBe(5);
    expect(e.y).toBe(10);
  });

  it('PhaseChangedEvent carries phase typed as GamePhase', () => {
    const e: PhaseChangedEvent = { phase: 'loot' };
    expect(e.phase).toBe('loot');
    const e2: PhaseChangedEvent = { phase: 'combat' };
    expect(e2.phase).toBe('combat');
  });
});

describe('Weapon events (T1, R2)', () => {
  it('ProjectileFiredEvent compiles with all fields', () => {
    const e: ProjectileFiredEvent = { projectileId: 'proj-0', playerId: 'p1', x: 100, y: 200, dx: 1, dy: 0 };
    expect(e.projectileId).toBe('proj-0');
    expect(e.dx).toBe(1);
  });

  it('ProjectileRemovedEvent reason is hit or range', () => {
    const hit: ProjectileRemovedEvent  = { projectileId: 'proj-0', reason: 'hit' };
    const range: ProjectileRemovedEvent = { projectileId: 'proj-1', reason: 'range' };
    expect(hit.reason).toBe('hit');
    expect(range.reason).toBe('range');
  });

  it('EnemyMovedEvent carries enemyId, x, y', () => {
    const e: EnemyMovedEvent = { enemyId: 'e1', x: 50, y: 75 };
    expect(e.enemyId).toBe('e1');
  });
});

describe('PlayerAimChangedEvent (T2, R7)', () => {
  it('auto variant compiles with playerId, mode, targetId', () => {
    const e: PlayerAimChangedEvent = { playerId: 'p1', mode: 'auto', targetId: 'enemy-1' };
    expect(e.mode).toBe('auto');
    expect(e.targetId).toBe('enemy-1');
  });

  it('auto variant allows null targetId (no enemy in range)', () => {
    const e: PlayerAimChangedEvent = { playerId: 'p1', mode: 'auto', targetId: null };
    expect(e.targetId).toBeNull();
  });

  it('manual variant compiles with playerId, mode, dx, dy', () => {
    const e: PlayerAimChangedEvent = { playerId: 'p1', mode: 'manual', dx: 1, dy: 0 };
    expect(e.mode).toBe('manual');
    expect(e.dx).toBe(1);
    expect(e.dy).toBe(0);
  });
});
