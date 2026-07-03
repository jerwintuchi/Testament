// T68: gear catalog — completeness, uniqueness, trait containment (R64, P30)
import { describe, it, expect } from 'vitest';
import { GEAR_CATALOG, BAG_SLOTS } from './gear.js';
import { CHANNELS, STIMULI } from './signs.js';

describe('GEAR_CATALOG (P30)', () => {
  it('has exactly one PERCEPTION item per channel', () => {
    const perception = GEAR_CATALOG.filter(g => g.kind === 'PERCEPTION');
    expect(perception).toHaveLength(CHANNELS.length);
    expect(perception.map(g => g.channel).sort()).toEqual([...CHANNELS].sort());
  });

  it('has exactly one PROBE item per stimulus', () => {
    const probes = GEAR_CATALOG.filter(g => g.kind === 'PROBE');
    expect(probes).toHaveLength(STIMULI.length);
    expect(probes.map(g => g.stimulus).sort()).toEqual([...STIMULI].sort());
  });

  it('all ids are unique', () => {
    const ids = GEAR_CATALOG.map(g => g.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it('every item has an id and a display name', () => {
    for (const item of GEAR_CATALOG) {
      expect(item.id.length).toBeGreaterThan(0);
      expect(item.name.length).toBeGreaterThan(0);
    }
  });

  it('carries no axis value literal (trait containment)', () => {
    const json = JSON.stringify(GEAR_CATALOG);
    for (const lit of ['EMBER', 'FROST', 'ROT', 'MIRE', 'STALKER', 'AMBUSHER',
                       'TERRITORIAL', 'FRENZIED', 'PENANCE', 'IMMOLATION',
                       'INTERMENT', 'LUNGE', 'SWEEP', 'RECOIL', 'SHUDDER']) {
      expect(json).not.toContain(`"${lit}"`);
    }
    expect(json).not.toContain('traitRoll');
  });
});

describe('BAG_SLOTS', () => {
  it('is 4 (bounded bag — scarcity is the point)', () => {
    expect(BAG_SLOTS).toBe(4);
  });
});
