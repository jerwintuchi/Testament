// Enemy system shared types and constants. Types + constants only (invariant I4).

export type EnemyTypeId = 'shambler' | 'spitter';

export type EnemyTypeDef = {
  typeId: EnemyTypeId;
  baseHp: number;
  damage: number;
  speed: number;          // world units per second
  detectionRange: number; // radius within which enemy notices a player
  attackRange: number;    // radius within which enemy can attack
  attackCooldown: number; // seconds between attacks
};

export type PlayerState = {
  hp: number;
  maxHp: number;
  downed: boolean;
  x: number;
  y: number;
};

export const PLAYER_MAX_HP = 100;
export const PLAYER_SPEED = 120; // world units per second

export const SHAMBLER_DEF: EnemyTypeDef = {
  typeId: 'shambler',
  baseHp: 60,
  damage: 15,
  speed: 60,
  detectionRange: 200,
  attackRange: 40,
  attackCooldown: 1.2,
};

export const SPITTER_DEF: EnemyTypeDef = {
  typeId: 'spitter',
  baseHp: 30,
  damage: 10,
  speed: 90,
  detectionRange: 300,
  attackRange: 150,
  attackCooldown: 0.9,
};

export const ENEMY_TYPES: Record<EnemyTypeId, EnemyTypeDef> = {
  shambler: SHAMBLER_DEF,
  spitter: SPITTER_DEF,
};

// Aim state per player. 'auto' = server selects nearest enemy; 'manual' = client
// is actively pointing the aim stick (or mouse), direction stored as a unit vector.
export type AimState =
  | { mode: 'auto';   targetId: string | null }
  | { mode: 'manual'; dx: number; dy: number };

// Weapon constants (single source of truth for server logic and client rendering).
export const WEAPON_COOLDOWN_MS    = 500;  // ms between shots per player
export const PROJECTILE_SPEED      = 400;  // world units / second
export const PROJECTILE_DAMAGE     = 20;
export const PROJECTILE_HIT_RADIUS = 20;   // radius around projectile centre
export const PROJECTILE_MAX_RANGE  = 600;  // units before projectile expires

// In-flight projectile. Owned by the server; clients track for rendering only.
export type ProjectileState = {
  id:               string;
  ownerId:          string; // PlayerId
  x:                number;
  y:                number;
  dx:               number; // unit vector
  dy:               number;
  distanceTravelled: number;
};
