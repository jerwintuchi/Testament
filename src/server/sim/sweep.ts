// Expedition sweep — the statistical half of the design harness. NOT game code.
// Same placement rationale as expedition.ts: outside rootDir, never shipped.
//
//   pnpm exec tsx sim/sweep.ts [--runs=5000]
//
// Answers, with numbers instead of argument:
//   1. how often is each question answerable, by party size x tier?
//   2. what does `ward !== frailty` (R326, shipped) actually buy?
//   3. at each tier/size, is there a packing DECISION, or one dominant bag?
//   4. what party-wide instrument bound makes full coverage impossible everywhere?
//
// TD-092 / specs/preparation R336.

import { GEAR_CATALOG, BAG_SLOTS } from '@testament/shared';
import type { Channel, ItemId, Stimulus, Tier } from '@testament/shared';
import { generateContract } from '../src/incarnate/generateContract.js';
import { deriveAmbientSigns } from '../src/incarnate/deriveSigns.js';
import { deriveReaction } from '../src/incarnate/deriveReaction.js';
import { perceivedChannelsFor, channelsForTier, hasProbeKit } from '../src/rooms/perception.js';
import { AMBIENT_AXES, ACTIVE_AXES } from '../src/incarnate/types.js';
import { createRng, hashSeed } from '../src/rng/seeded.js';

const RUNS = Number(process.argv.find(a => a.startsWith('--runs='))?.split('=')[1] ?? '5000');
const TIERS: Tier[] = ['VIGIL', 'INTERDICT', 'ANATHEMA'];
const SIZES = [1, 2, 3, 4];
const STIMULI: Stimulus[] = ['FLAME', 'COLD', 'SALT', 'LIGHT'];
const AXIS_CHANNEL: Record<string, Channel> = {
  ASPECT: 'RESIDUE', FRAILTY: 'STRESS_MARK', WARD: 'REACTION',
  DISPOSITION: 'SPOOR', RITE_KEY: 'LITURGY', TELL: 'OMEN',
};
const pct = (n: number, d: number) => d === 0 ? '  — ' : `${((100 * n) / d).toFixed(0).padStart(3)}%`;
const f1 = (x: number) => x.toFixed(2);

// The same "sensible party" policy the transcript uses: cover the ambient channels
// that pay every hunt, then the Witness Prism (without it no probe can be read),
// then probe kits with whatever is left.
function pack(tier: Tier, party: number): { bags: ItemId[][]; cut: ItemId[] } {
  const chans = channelsForTier(tier);
  const lenses = GEAR_CATALOG.filter(g => g.kind === 'PERCEPTION' && chans.includes(g.channel));
  const kits = GEAR_CATALOG.filter(g => g.kind === 'PROBE');
  const wardLive = ACTIVE_AXES[tier].includes('WARD');
  const wish: ItemId[] = [];
  if (party > 1) {
    for (const ax of AMBIENT_AXES[tier]) {
      const l = lenses.find(g => g.kind === 'PERCEPTION' && g.channel === AXIS_CHANNEL[ax]);
      if (l) wish.push(l.id);
    }
    const prism = lenses.find(g => g.kind === 'PERCEPTION' && g.channel === 'REACTION');
    if (wardLive && prism) wish.push(prism.id);
  }
  if (wardLive) for (const k of kits) wish.push(k.id);
  const slots = BAG_SLOTS * party;
  const taken = wish.slice(0, slots);
  const bags: ItemId[][] = Array.from({ length: party }, () => []);
  taken.forEach((id, i) => bags[i % party]!.push(id));
  return { bags, cut: wish.slice(slots) };
}

// ── 1 + 2. Coverage and the cost of the Ward ────────────────────────────────
console.log(`\n${'═'.repeat(78)}`);
console.log(`  SWEEP — ${RUNS} expeditions per cell, real trait rolls on real seeded RNG`);
console.log(`${'═'.repeat(78)}`);

console.log(`\n── QUESTIONS ANSWERED, and what the Ward costs ${'─'.repeat(31)}\n`);
console.log(`  tier        party   questions   ward found   probes(law)  probes(none)  saved`);
console.log(`  ${'─'.repeat(76)}`);

for (const tier of TIERS) {
  const live = ACTIVE_AXES[tier];
  const wardLive = live.includes('WARD');
  for (const party of SIZES) {
    const { bags } = pack(tier, party);
    const solo = party === 1;
    const perceived = bags.map(b => perceivedChannelsFor(b, solo, tier));
    let answered = 0, wardFound = 0, wardFoundNoLaw = 0, byElimination = 0;
    let probesLaw = 0, probesNone = 0, wardRuns = 0;

    for (let i = 0; i < RUNS; i++) {
      // Seed off the tier's INDEX, never its name: seeding on the name made this
      // harness's own output shift under TD-094's rename, which briefly looked like a
      // rebalance (P159). The sample must depend on the game, not on spelling.
      const seed = `sweep-${TIERS.indexOf(tier)}-${party}-${i}`;
      const c = generateContract(createRng(hashSeed(seed)), tier, 'c', seed);
      const t = c.traitRoll;
      const ambient = deriveAmbientSigns(t, tier);
      for (const s of ambient) if (perceived.some(p => p.includes(s.channel))) answered++;

      if (!wardLive) continue;
      wardRuns++;
      const canRead = perceived.some(p => p.includes('REACTION'));
      const rng = createRng(hashSeed(`${seed}:order`));
      const order = [...STIMULI].sort(() => rng.float() - 0.5);
      const run = (skip: Stimulus | null) => {
        // Candidates the party still entertains. The law (R326) removes the frailty
        // for free, before anything is spent.
        const candidates = STIMULI.filter(s => s !== skip);
        let n = 0;
        for (const st of order) {
          if (!candidates.includes(st)) continue;
          if (!bags.some(b => hasProbeKit(b, st))) continue;   // no kit — cannot test
          n++;
          if (deriveReaction(t, tier, st).token !== 'no-reaction') return { n, hit: true, byElim: false };
          candidates.splice(candidates.indexOf(st), 1);        // tested, missed
        }
        // Deduction by elimination: everything else is ruled out and exactly one
        // candidate remains, so the ward is known WITHOUT ever testing it.
        if (candidates.length === 1) return { n, hit: true, byElim: true };
        return { n, hit: false, byElim: false };
      };
      const withLaw = run(t.frailty as Stimulus);
      const without = run(null);
      if (canRead && withLaw.hit) wardFound++;
      if (canRead && without.hit) wardFoundNoLaw++;
      if (canRead && withLaw.byElim) byElimination++;
      probesLaw += withLaw.n;
      probesNone += without.n;
    }

    const ambientCount = AMBIENT_AXES[tier].length * RUNS;
    const q = `${pct(answered, ambientCount)} of ${AMBIENT_AXES[tier].length}`;
    const wf = wardLive ? pct(wardFound, wardRuns) : '  — ';
    const wn = wardLive ? pct(wardFoundNoLaw, wardRuns) : '  — ';
    const be = wardLive ? pct(byElimination, wardRuns) : '  — ';
    const pl = wardLive ? f1(probesLaw / wardRuns) : ' — ';
    const pn = wardLive ? f1(probesNone / wardRuns) : ' — ';
    console.log(`  ${tier.padEnd(11)} ${String(party).padEnd(6)} ${q.padEnd(10)} ${wf.padEnd(9)} ${wn.padEnd(10)} ${be.padEnd(9)} ${pl.padEnd(8)} ${pn}`);
  }
}

// ── 3. Is there a decision? ─────────────────────────────────────────────────
// The first version of this test was BROKEN and reported 210/210: it asked whether
// one bag DOMINATED another, but every legal bag holds exactly BAG_SLOTS items and
// so has the same capability COUNT — nothing could ever dominate. The honest
// question is whether the OPTIMUM is unique. If exactly one capability outcome is
// best, every bag reaching it is interchangeable and the choice is cosmetic.
console.log(`\n── IS THERE A PACKING DECISION? ${'─'.repeat(46)}\n`);
console.log(`  Capability = channels that can carry a sign this tier + stimuli testable.`);
console.log(`  A tie among IDENTICAL outcomes is not a choice; distinct optima are.\n`);
console.log(`  tier         seat    best capability  distinct optima  bags tying  verdict`);
console.log(`  ${'─'.repeat(76)}`);

function combos<T>(xs: T[], k: number): T[][] {
  if (k === 0) return [[]];
  if (xs.length < k) return [];
  const [h, ...t] = xs;
  return [...combos(t, k - 1).map(c => [h!, ...c]), ...combos(t, k)];
}

for (const tier of TIERS) {
  const wardLive = ACTIVE_AXES[tier].includes('WARD');
  for (const solo of [true, false]) {
    const bags = combos(GEAR_CATALOG.map(g => g.id), BAG_SLOTS);
    const scored = bags.map(b => {
      const liveCh = new Set<Channel>([
        ...AMBIENT_AXES[tier].map(a => AXIS_CHANNEL[a]!),
        ...(wardLive ? (['REACTION'] as Channel[]) : []),
      ]);
      const ch = perceivedChannelsFor(b, solo, tier).filter(c => liveCh.has(c));
      const st = wardLive ? STIMULI.filter(s => hasProbeKit(b, s)) : [];
      return { key: `${[...ch].sort().join('+')} | ${[...st].sort().join('+')}`, n: ch.length + st.length };
    });
    const best = Math.max(...scored.map(s => s.n));
    const optima = new Set(scored.filter(s => s.n === best).map(s => s.key));
    const tying = scored.filter(s => s.n === best).length;
    const verdict = optima.size === 1 ? 'NO DECISION — every best bag is the same bag'
                  : optima.size <= 4 ? 'thin'
                  : 'a real choice';
    console.log(`  ${tier.padEnd(12)} ${(solo ? 'solo' : 'party').padEnd(7)} ${String(best).padEnd(16)} ${String(optima.size).padEnd(16)} ${String(tying).padEnd(11)} ${verdict}`);
  }
}

// ── 4. The instrument allowance ─────────────────────────────────────────────
// R336: a party-wide bound on READING instruments (lenses + kits), set so that no
// party can ever read every channel. Blindness guaranteed; its location chosen.
console.log(`\n── THE INSTRUMENT ALLOWANCE (specs/preparation R336) ${'─'.repeat(25)}\n`);
console.log(`  At ANATHEMA: 6 questions live. Answering all six needs 5 lenses + prism + a kit.`);
console.log(`  "Max answerable" = best case over every way to split M instruments.\n`);
console.log(`  M    max questions answerable   party of 1   2    3    4    verdict`);
console.log(`  ${'─'.repeat(74)}`);

for (let M = 3; M <= 10; M++) {
  // best allocation: L lenses (each answers one ambient question), prism + >=1 kit for ward
  let best = 0;
  for (let lenses = 0; lenses <= Math.min(M, 5); lenses++) {
    const rest = M - lenses;
    const ward = rest >= 2 ? 1 : 0;            // prism + at least one kit
    best = Math.max(best, lenses + ward);
  }
  const perSize = SIZES.map(n => Math.min(M, BAG_SLOTS * n));   // the bound bites below slot capacity
  const binds = perSize.map(x => (x === M ? ' Y ' : ' n '));
  const verdict = best < 6 ? 'blindness guaranteed' : 'full coverage possible';
  console.log(`  ${String(M).padEnd(4)} ${String(best).padEnd(26)} ${binds.join('   ')}  ${verdict}`);
}
console.log(`\n  "Y" = the allowance is what limits the party, not their bag slots.`);
console.log(`  The DESIGN is the inequality (M < 6). The number is the author's.\n`);
