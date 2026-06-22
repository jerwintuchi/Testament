import { describe, it, expect } from 'vitest';
import {
  ENEMY_TYPES,
  SHAMBLER_DEF,
  SPITTER_DEF,
  PLAYER_MAX_HP,
  WEAPON_COOLDOWN_MS,
  PROJECTILE_SPEED,
  PROJECTILE_DAMAGE,
  PROJECTILE_HIT_RADIUS,
  PROJECTILE_MAX_RANGE,
  type EnemyTypeDef,
  type PlayerState,
  type AimState,
  type ProjectileState,
} from './combat.js';

describe('ENEMY_TYPES (R1)', () => {
  it('contains entries for shambler and spitter', () => {
    expect(ENEMY_TYPES).toHaveProperty('shambler');
    expect(ENEMY_TYPES).toHaveProperty('spitter');
  });

  it('Shambler speed is strictly less than Spitter speed', () => {
    expect(SHAMBLER_DEF.speed).toBeLessThan(SPITTER_DEF.speed);
  });

  it('Spitter attackRange is strictly greater than Shambler attackRange', () => {
    expect(SPITTER_DEF.attackRange).toBeGreaterThan(SHAMBLER_DEF.attackRange);
  });

  it('all stat fields are positive numbers', () => {
    const check = (def: EnemyTypeDef) => {
      expect(def.baseHp).toBeGreaterThan(0);
      expect(def.damage).toBeGreaterThan(0);
      expect(def.speed).toBeGreaterThan(0);
      expect(def.detectionRange).toBeGreaterThan(0);
      expect(def.attackRange).toBeGreaterThan(0);
      expect(def.attackCooldown).toBeGreaterThan(0);
    };
    check(SHAMBLER_DEF);
    check(SPITTER_DEF);
  });

  it('Shambler attackRange < Spitter detectionRange (melee vs ranged distinction)', () => {
    expect(SHAMBLER_DEF.attackRange).toBeLessThan(SPITTER_DEF.detectionRange);
  });
});

describe('PlayerState type (R2)', () => {
  it('PlayerState compiles with all required fields', () => {
    const ps: PlayerState = { hp: 100, maxHp: 100, downed: false, x: 0, y: 0 };
    expect(ps.hp).toBe(100);
    expect(ps.maxHp).toBe(100);
    expect(ps.downed).toBe(false);
    expect(ps.x).toBe(0);
    expect(ps.y).toBe(0);
  });

  it('PLAYER_MAX_HP is a positive number', () => {
    expect(PLAYER_MAX_HP).toBeGreaterThan(0);
  });
});

describe('Weapon constants (T1, R1)', () => {
  it('WEAPON_COOLDOWN_MS is a positive number', () => expect(WEAPON_COOLDOWN_MS).toBeGreaterThan(0));
  it('PROJECTILE_SPEED is a positive number',    () => expect(PROJECTILE_SPEED).toBeGreaterThan(0));
  it('PROJECTILE_DAMAGE is a positive number',   () => expect(PROJECTILE_DAMAGE).toBeGreaterThan(0));
  it('PROJECTILE_HIT_RADIUS is positive',        () => expect(PROJECTILE_HIT_RADIUS).toBeGreaterThan(0));
  it('PROJECTILE_MAX_RANGE > HIT_RADIUS',        () => expect(PROJECTILE_MAX_RANGE).toBeGreaterThan(PROJECTILE_HIT_RADIUS));
});

describe('ProjectileState type (T1, R1)', () => {
  it('compiles with all required fields', () => {
    const p: ProjectileState = { id: 'proj-0', ownerId: 'p1', x: 0, y: 0, dx: 1, dy: 0, distanceTravelled: 0 };
    expect(p.id).toBe('proj-0');
    expect(p.ownerId).toBe('p1');
    expect(typeof p.distanceTravelled).toBe('number');
  });
});

describe('AimState type (T1, R4)', () => {
  it('auto variant compiles with targetId: string | null', () => {
    const a: AimState = { mode: 'auto', targetId: null };
    expect(a.mode).toBe('auto');
    const b: AimState = { mode: 'auto', targetId: 'enemy-1' };
    expect(b.mode).toBe('auto');
  });

  it('manual variant compiles with dx and dy numbers', () => {
    const m: AimState = { mode: 'manual', dx: 1, dy: 0 };
    expect(m.mode).toBe('manual');
    if (m.mode === 'manual') {
      expect(typeof m.dx).toBe('number');
      expect(typeof m.dy).toBe('number');
    }
  });
});
