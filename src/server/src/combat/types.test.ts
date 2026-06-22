import { describe, it, expect } from 'vitest';
import type { EnemyState, CombatEvent, EnemyId } from './types.js';

describe('Server combat types (T3, R9)', () => {
  it('EnemyState has all required fields', () => {
    const e: EnemyState = {
      id: 'e1',
      typeId: 'shambler',
      x: 100,
      y: 200,
      hp: 60,
      maxHp: 60,
      damage: 15,
      alive: true,
      attackCooldownRemaining: 0,
    };
    expect(e.id).toBe('e1');
    expect(e.typeId).toBe('shambler');
    expect(e.alive).toBe(true);
    expect(e.attackCooldownRemaining).toBe(0);
  });

  it('CombatEvent has kind: attack, enemyId, targetId, damage', () => {
    const ev: CombatEvent = { kind: 'attack', enemyId: 'e1', targetId: 'p1', damage: 15 };
    expect(ev.kind).toBe('attack');
    expect(ev.damage).toBe(15);
  });

  it('EnemyId is assignable from string', () => {
    const id: EnemyId = 'run-1-1-room0-0';
    expect(typeof id).toBe('string');
  });
});
