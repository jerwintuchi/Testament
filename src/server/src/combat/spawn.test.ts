import { describe, it, expect, vi } from 'vitest';
import { spawnEnemies } from './spawn.js';
import { generateDungeon, STANDARD_DUNGEON_CONFIG } from '../dungeon/bsp.js';
import { createRng, hashSeed } from '../rng/seeded.js';
import { SHAMBLER_DEF } from '@veins/shared';

const TEST_RUN = 'test-run-abc';
const TEST_DUNGEON = generateDungeon(TEST_RUN, STANDARD_DUNGEON_CONFIG, 1);

describe('spawnEnemies (T5, R3, P1)', () => {
  it('same inputs produce deeply-equal maps (determinism)', () => {
    const a = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    const b = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    expect(a.size).toBe(b.size);
    expect(a.size).toBeGreaterThan(0);
    for (const [id, e] of a) {
      expect(b.get(id)).toEqual(e);
    }
  });

  it('different floors of the same runId produce different maps', () => {
    const dungeon2 = generateDungeon(TEST_RUN, STANDARD_DUNGEON_CONFIG, 2);
    const a = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    const b = spawnEnemies(TEST_RUN, 2, dungeon2);
    // Enemy IDs embed the floor, so they are always distinct across floors.
    const idsA = [...a.keys()].sort().join(',');
    const idsB = [...b.keys()].sort().join(',');
    expect(idsA).not.toBe(idsB);
  });

  it('all spawned positions fall within dungeon bounds (not outside dungeon)', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    for (const enemy of enemies.values()) {
      expect(enemy.x).toBeGreaterThanOrEqual(0);
      expect(enemy.x).toBeLessThanOrEqual(TEST_DUNGEON.width);
      expect(enemy.y).toBeGreaterThanOrEqual(0);
      expect(enemy.y).toBeLessThanOrEqual(TEST_DUNGEON.height);
    }
  });

  it('all spawned positions fall inside a dungeon room rect', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    for (const enemy of enemies.values()) {
      const inSomeRoom = TEST_DUNGEON.rooms.some(r =>
        enemy.x >= r.rect.x &&
        enemy.x <= r.rect.x + r.rect.width &&
        enemy.y >= r.rect.y &&
        enemy.y <= r.rect.y + r.rect.height
      );
      expect(inSomeRoom).toBe(true);
    }
  });

  it('every spawned enemy starts alive with hp === maxHp', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    expect(enemies.size).toBeGreaterThan(0);
    for (const enemy of enemies.values()) {
      expect(enemy.alive).toBe(true);
      expect(enemy.hp).toBe(enemy.maxHp);
      expect(enemy.attackCooldownRemaining).toBe(0);
    }
  });

  it('does not call Math.random (uses seeded RNG only, I3)', () => {
    const spy = vi.spyOn(Math, 'random');
    spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    expect(spy).not.toHaveBeenCalled();
    spy.mockRestore();
  });

  it('skips the entry room (room-0): no enemy id references room-0', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    // Enemy id format: "${runId}-${floor}-${roomId}-${i}"
    // Room 0 id is "room-0", so the id contains "-room-0-"
    for (const id of enemies.keys()) {
      expect(id).not.toContain('-room-0-');
    }
  });

  it('at least one enemy per non-entry room', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    const spawnableRooms = TEST_DUNGEON.rooms.length - 1; // exclude room-0
    expect(enemies.size).toBeGreaterThanOrEqual(spawnableRooms);
  });

  it('accepts an injectable Rng for deterministic override', () => {
    const rng = createRng(hashSeed('custom-seed'));
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON, rng);
    for (const e of enemies.values()) {
      expect(e.alive).toBe(true);
      expect(e.hp).toBe(e.maxHp);
    }
  });

  it('floor 1 shamblers have base hp and damage (×1.0 multiplier)', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    const shamblers = [...enemies.values()].filter(e => e.typeId === 'shambler');
    expect(shamblers.length).toBeGreaterThan(0);
    for (const e of shamblers) {
      expect(e.maxHp).toBe(SHAMBLER_DEF.baseHp);
      expect(e.damage).toBe(SHAMBLER_DEF.damage);
    }
  });

  it('floor 3 enemies have strictly more hp and damage than floor 1', () => {
    const dungeon3 = generateDungeon(TEST_RUN, STANDARD_DUNGEON_CONFIG, 3);
    const f1 = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    const f3 = spawnEnemies(TEST_RUN, 3, dungeon3);
    const avgHp = (m: Map<string, { maxHp: number }>) =>
      [...m.values()].reduce((s, e) => s + e.maxHp, 0) / m.size;
    const avgDmg = (m: Map<string, { damage: number }>) =>
      [...m.values()].reduce((s, e) => s + e.damage, 0) / m.size;
    expect(avgHp(f3)).toBeGreaterThan(avgHp(f1));
    expect(avgDmg(f3)).toBeGreaterThan(avgDmg(f1));
  });

  it('all spawned enemies have a positive damage value', () => {
    const enemies = spawnEnemies(TEST_RUN, 1, TEST_DUNGEON);
    for (const e of enemies.values()) {
      expect(e.damage).toBeGreaterThan(0);
    }
  });
});
