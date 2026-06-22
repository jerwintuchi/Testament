import { describe, it, expect } from 'vitest';
import { STARTER_RELICS, STARTER_RELIC_IDS } from './relics.js';

describe('STARTER_RELICS (T1, R1)', () => {
  it('has exactly 10 entries', () => {
    expect(STARTER_RELICS).toHaveLength(10);
  });

  it('all ids are unique', () => {
    const ids = STARTER_RELICS.map(r => r.id);
    expect(new Set(ids).size).toBe(10);
  });

  it('every entry has a non-empty name', () => {
    for (const r of STARTER_RELICS) {
      expect(r.name.length).toBeGreaterThan(0);
    }
  });

  it('every entry has at least one tag', () => {
    for (const r of STARTER_RELICS) {
      expect(r.tags.length).toBeGreaterThan(0);
    }
  });

  it('every entry has non-empty base and synergy effect descriptions', () => {
    for (const r of STARTER_RELICS) {
      expect(r.baseEffect.description.length).toBeGreaterThan(0);
      expect(r.synergyEffect.description.length).toBeGreaterThan(0);
    }
  });

  it('contains at least 2 relics with the tumor doctrine tag', () => {
    const tumor = STARTER_RELICS.filter(r => r.tags.includes('tumor'));
    expect(tumor.length).toBeGreaterThanOrEqual(2);
  });

  it('contains at least 3 relics with the chain tag', () => {
    const chain = STARTER_RELICS.filter(r => r.tags.includes('chain'));
    expect(chain.length).toBeGreaterThanOrEqual(3);
  });

  it('contains at least 3 relics with the shield tag', () => {
    const shield = STARTER_RELICS.filter(r => r.tags.includes('shield'));
    expect(shield.length).toBeGreaterThanOrEqual(3);
  });
});

describe('STARTER_RELIC_IDS (T1, R1)', () => {
  it('matches STARTER_RELICS.map(r => r.id)', () => {
    expect(STARTER_RELIC_IDS).toEqual(STARTER_RELICS.map(r => r.id));
  });
});
