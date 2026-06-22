// @vitest-environment node
// SoundManager must silently degrade when AudioContext is unavailable (test env, old browsers).
import { describe, it, expect } from 'vitest';
import { SoundManager } from './SoundManager.js';

describe('SoundManager (graceful degradation)', () => {
  it('projectileFired does not throw when AudioContext is absent', () => {
    expect(() => SoundManager.projectileFired()).not.toThrow();
  });

  it('projectileHit does not throw', () => {
    expect(() => SoundManager.projectileHit()).not.toThrow();
  });

  it('playerHit does not throw', () => {
    expect(() => SoundManager.playerHit()).not.toThrow();
  });

  it('enemyDied does not throw', () => {
    expect(() => SoundManager.enemyDied()).not.toThrow();
  });

  it('bleedWarning does not throw', () => {
    expect(() => SoundManager.bleedWarning()).not.toThrow();
  });

  it('floorCleared does not throw', () => {
    expect(() => SoundManager.floorCleared()).not.toThrow();
  });
});
