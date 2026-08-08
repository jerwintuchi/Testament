// Expedition simulator — a design harness, NOT game code.
//
// Lives outside `src/` on purpose: tsconfig sets rootDir=./src and include=["src"],
// so nothing here is ever compiled into dist/ or shipped. It sits inside the server
// package only so it can import the real functions rather than a mock of them.
//
// Everything below the "THE REAL GAME" line is the actual server logic on the actual
// seeded RNG (I3): same seed, same hunt. Everything above the "PROPOSED" line is spec
// material previewed for a decision (TD-093's re-authored lexicon), clearly marked so
// nobody mistakes it for shipped behaviour.
//
//   pnpm exec tsx sim/expedition.ts [--seed=x] [--tier=JOURNEYMAN] [--party=2] [--prose]
//
// TD-092 / TD-093.

import { GEAR_CATALOG, BAG_SLOTS } from '@testament/shared';
import type { Channel, ItemId, Sign, Stimulus, Tier } from '@testament/shared';
import { generateContract } from '../src/incarnate/generateContract.js';
import { generateTraitRoll } from '../src/incarnate/generateTraitRoll.js';
import { deriveAmbientSigns } from '../src/incarnate/deriveSigns.js';
import { deriveReaction } from '../src/incarnate/deriveReaction.js';
import { perceivedChannelsFor, filterSigns, channelsForTier, hasProbeKit } from '../src/rooms/perception.js';
import { AMBIENT_AXES, ACTIVE_AXES } from '../src/incarnate/types.js';
import { createRng, hashSeed } from '../src/rng/seeded.js';

// ── PROPOSED (specs/sign-lexicon, TD-093 — NOT shipped) ─────────────────────
// Rendered only under --prose, so a reader can feel the difference between the
// token a player reads today and the field note R343 would render instead.
const PROPOSED: Record<string, { token: string; note: string }> = {
  'scorched-wax':          { token: 'run-wax',             note: 'Wax has run and pooled in the sconces. None of these candles were lit.' },
  'frost-rime':            { token: 'heaved-mortar',       note: 'The joints are split and pushed proud; mortar has crumbled out of the course.' },
  'rot-bloom':             { token: 'bloomed-iron',        note: 'Nails, hinges, the grille — all flowered with rust a century past their years.' },
  'weeping-clay':          { token: 'weeping-clay',        note: 'The floor gives up water it has no business holding.' },
  'flinch-from-flame':     { token: 'tallow-sweat',        note: 'The wound beads a fatty film that will not dry.' },
  'flinch-from-cold':      { token: 'runs-hot',            note: 'The wound runs hot. It steams in the still air.' },
  'flinch-from-salt':      { token: 'clear-weep',          note: 'It runs thin and colourless, and will not close.' },
  'flinch-from-light':     { token: 'shadow-bleed',        note: 'The wound smokes dark. A lamp will not reach the bottom of it.' },
  'drinks-flame':          { token: 'swallowed-the-brand', note: 'The flame lies down into it and does not come back.' },
  'drinks-cold':           { token: 'swallowed-the-rime',  note: 'The chill goes in. The air about it is warmer after.' },
  'drinks-salt':           { token: 'swallowed-the-grain', note: 'The salt darkens, damps, and is gone.' },
  'drinks-light':          { token: 'swallowed-the-lamp',  note: 'The lamp dims toward it and steadies wrong.' },
  'no-reaction':           { token: 'no-reaction',         note: 'Nothing. It does not answer.' },
  'trailing-spoor':        { token: 'prints-in-our-prints',note: 'Its tread lies inside our own, going the way we went.' },
  'still-spoor':           { token: 'still-spoor',         note: 'Sign of it here, and no track of travel at all.' },
  'boundary-marks':        { token: 'tracks-turn-back',    note: 'Every trail reaches the same reach and turns back.' },
  'erratic-spoor':         { token: 'broken-stride',       note: 'No two strides the same. It ran through what it could have gone around.' },
  'kneeling-sigil':        { token: 'worn-knee-stone',     note: 'Two ovals polished into the flags where it stops.' },
  'flame-rune':            { token: 'ash-offering',        note: 'What it takes is heaped and burnt — arranged, not scattered.' },
  'burial-mark':           { token: 'covered-dead',        note: 'Nothing it kills is left uncovered. Earth, cloth or stone laid over.' },
  'voided-glyph':          { token: 'voided-glyph',        note: 'Inscriptions scratched out. Names struck through.' },
  'drawn-breath-and-lean': { token: 'drawn-breath-and-lean', note: 'Weight forward. Air taken.' },
  'wide-shoulder-coil':    { token: 'wide-shoulder-coil',  note: 'The shoulder loads across the body.' },
  'backward-step-brace':   { token: 'backward-step-brace', note: 'It gathers backward before it gives.' },
  'full-body-tremor':      { token: 'full-body-tremor',    note: 'The whole frame goes.' },
};

// What each axis actually asks, in a hunter's words rather than the taxonomy.
const QUESTION: Record<string, string> = {
  ASPECT:      'what did it leave behind?',
  FRAILTY:     'what hurts it?',
  WARD:        'what does it shrug off?',
  DISPOSITION: 'how does it hunt?',
  RITE_KEY:    'how can it be ended without killing?',
  TELL:        'what does it do before it strikes?',
};
const AXIS_OF_CHANNEL: Record<Channel, string> = {
  RESIDUE: 'ASPECT', STRESS_MARK: 'FRAILTY', REACTION: 'WARD',
  SPOOR: 'DISPOSITION', LITURGY: 'RITE_KEY', OMEN: 'TELL',
};
const STIMULI: Stimulus[] = ['FLAME', 'COLD', 'SALT', 'LIGHT'];
const NAMES = ['Aldric', 'Wren', 'Hald', 'Bede'];

// ── THE REAL GAME ───────────────────────────────────────────────────────────

const arg = (k: string, d: string) =>
  (process.argv.find(a => a.startsWith(`--${k}=`))?.split('=')[1]) ?? d;
const SEED   = arg('seed', 'ashfen-1');
const TIER   = arg('tier', 'JOURNEYMAN') as Tier;
const PARTY  = Number(arg('party', '2'));
const PROSE  = process.argv.includes('--prose');

const show = (s: Sign) => {
  const p = PROSE ? PROPOSED[s.token] : undefined;
  return p ? `${p.note}` : `[${s.channel}] ${s.token}`;
};

const hr = (t = '') => console.log(`\n${t ? `── ${t} ` : ''}${'─'.repeat(Math.max(0, 74 - t.length))}`);
const wrap = (s: string, pad = '    ') =>
  s.replace(/(.{1,70})(\s|$)/g, (_, l) => `${pad}${l.trim()}\n`).trimEnd();

const contract = generateContract(createRng(hashSeed(SEED)), TIER, 'c-sim', SEED);
const truth = contract.traitRoll;

console.log(`\n${'═'.repeat(76)}`);
console.log(`  EXPEDITION — seed "${SEED}"  ·  ${TIER}  ·  ${PARTY} Seeker${PARTY > 1 ? 's' : ''}`);
console.log(`${'═'.repeat(76)}`);

// ── The writ ────────────────────────────────────────────────────────────────
hr('THE WRIT — everything the party knows before packing');
const r = contract.requester;
console.log(`
    ${contract.targetName}, at ${contract.siteName}
    Origin asserted: ${contract.origin}          Charge: ${contract.primaryVerb}
    Petitioner: ${r.name ? `${r.name}, ${r.role} of ${r.place}` : `a ${r.role} of ${r.place}`}
`);
console.log(wrap(
  `NOTE (TD-092): origin, target and site are each an independent seeded pick, and ` +
  `origin is read by nothing in src/server/. None of the above narrows the trait roll ` +
  `by a single value. The only real information here is the TIER.`));

// ── The counter ─────────────────────────────────────────────────────────────
hr('THE QUARTERMASTER — the squeeze');
const liveAxes    = ACTIVE_AXES[TIER];
const ambientAx   = AMBIENT_AXES[TIER];
const tierChans   = channelsForTier(TIER);
const wardLive    = liveAxes.includes('WARD');

console.log(`\n    Live this tier: ${liveAxes.join(', ')}`);
console.log(`    Questions the party could answer:`);
for (const ax of liveAxes) console.log(`      · ${QUESTION[ax]}`);

const lenses = GEAR_CATALOG.filter(g => g.kind === 'PERCEPTION' && tierChans.includes(g.channel));
const kits   = GEAR_CATALOG.filter(g => g.kind === 'PROBE');
const needed = lenses.length + (wardLive ? kits.length : 0);
const slots  = BAG_SLOTS * PARTY;

console.log(`\n    Instruments that could pay: ${needed}   (${lenses.length} lenses` +
            `${wardLive ? ` + ${kits.length} probe kits` : `, probe kits are a GUARANTEED NULL at this tier`})`);
console.log(`    Slots available:            ${slots}   (${BAG_SLOTS} x ${PARTY})`);
console.log(`    ${needed > slots ? `SHORT BY ${needed - slots} — something is left on the counter.`
                                  : needed === slots ? `EXACTLY ENOUGH — no choice to make.`
                                  : `${slots - needed} SLOTS SPARE — the bag does not bind.`}`);

// A sensible party: cover the ambient channels first (they pay every hunt), then the
// Witness Prism (without it nobody can read a probe at all), then kits with what is left.
const solo = PARTY === 1;
const wishlist: ItemId[] = [];
if (!solo) {
  for (const ax of ambientAx) {
    const ch = Object.entries(AXIS_OF_CHANNEL).find(([, a]) => a === ax)?.[0] as Channel;
    const lens = lenses.find(l => l.kind === 'PERCEPTION' && l.channel === ch);
    if (lens) wishlist.push(lens.id);
  }
  const prism = lenses.find(l => l.kind === 'PERCEPTION' && l.channel === 'REACTION');
  if (wardLive && prism) wishlist.push(prism.id);
}
if (wardLive) for (const k of kits) wishlist.push(k.id);

const taken = wishlist.slice(0, slots);
const cut   = wishlist.slice(slots);
const label = (id: ItemId) => GEAR_CATALOG.find(g => g.id === id)!.name;

const bags: ItemId[][] = Array.from({ length: PARTY }, () => []);
taken.forEach((id, i) => bags[i % PARTY]!.push(id));

console.log(`\n    Packed:`);
bags.forEach((b, i) => console.log(`      ${NAMES[i]}: ${b.length ? b.map(label).join(', ') : '(nothing — solo reads every channel unaided)'}`));
if (cut.length) {
  console.log(`\n    LEFT ON THE COUNTER: ${cut.map(label).join(', ')}`);
  if (cut.some(id => GEAR_CATALOG.find(g => g.id === id)?.kind === 'PROBE'))
    console.log(`      → one stimulus can never be tested this hunt.`);
  if (cut.some(id => { const g = GEAR_CATALOG.find(x => x.id === id); return g?.kind === 'PERCEPTION' && g.channel === 'REACTION'; }))
    console.log(`      → NOBODY can read a probe result. The Ward is unknowable, not merely untested.`);
}

// ── Arrival ─────────────────────────────────────────────────────────────────
hr('ARRIVAL — what each Seeker actually perceives');
const ambient = deriveAmbientSigns(truth, TIER);
const perceived = bags.map(b => perceivedChannelsFor(b, solo, TIER));

bags.forEach((_, i) => {
  const mine = filterSigns(ambient, perceived[i]!);
  console.log(`\n  ${NAMES[i]} — reads ${perceived[i]!.length ? perceived[i]!.join(', ') : 'nothing'}`);
  if (!mine.length) console.log(`      (nothing yet; observe, then probe)`);
  for (const s of mine) console.log(`      ${show(s)}`);
});

// ── The conversation ────────────────────────────────────────────────────────
hr('THE CONVERSATION — what must be said out loud');
const seenBy = new Map<string, number[]>();
ambient.forEach(s => {
  const who = perceived.map((p, i) => (p.includes(s.channel) ? i : -1)).filter(i => i >= 0);
  seenBy.set(s.channel, who);
});
let shared = 0, missed = 0;
for (const [ch, who] of seenBy) {
  const ax = AXIS_OF_CHANNEL[ch as Channel];
  if (!who.length) { missed++; console.log(`    ✗ ${QUESTION[ax]!.padEnd(42)} NOBODY can see this`); }
  else { if (who.length < PARTY) shared++;
    console.log(`    · ${QUESTION[ax]!.padEnd(42)} only ${who.map(i => NAMES[i]).join(' & ')} sees it`); }
}
console.log(`\n    ${shared} reading${shared === 1 ? '' : 's'} exist${shared === 1 ? 's' : ''} in one head and must be spoken.` +
            `${missed ? `  ${missed} question${missed === 1 ? '' : 's'} cannot be answered at all.` : ''}`);

// ── The probe ───────────────────────────────────────────────────────────────
hr('THE PROBE — testing the Ward');
if (!wardLive) {
  console.log(`\n    WARD is not live at ${TIER}. Every probe returns no-reaction, and nothing`);
  console.log(`    distinguishes "no ward" from "ward inactive at this rank" (TD-092 A-register).`);
} else if (!perceived.some(p => p.includes('REACTION'))) {
  console.log(`\n    No Witness Prism in the party — a probe can be presented but not read.`);
} else {
  const frailty = truth.frailty;
  console.log(`\n    Stress-mark gave: ${show(ambient.find(s => s.channel === 'STRESS_MARK')!)}`);
  console.log(`      → frail to ${frailty}.`);
  console.log(`      → LAW (R326, shipped): a thing is never warded against what it is frail to,`);
  console.log(`        so ${frailty} is eliminated without spending a probe.`);

  const order = STIMULI.filter(s => s !== frailty);
  let probes = 0, found: Stimulus | null = null;
  for (const st of order) {
    const carrier = bags.findIndex(b => hasProbeKit(b, st));
    if (carrier < 0) { console.log(`\n    ${st}: no kit — cannot test.`); continue; }
    probes++;
    const sign = deriveReaction(truth, TIER, st);
    // Only REACTION perceivers read the answer — INCLUDING the prober (probe.ts:52).
    const readers = perceived.map((p, i) => (p.includes('REACTION') ? i : -1)).filter(i => i >= 0);
    console.log(`\n    ${NAMES[carrier]} presents ${st}.`);
    console.log(`      ${show(sign)}`);
    if (!readers.includes(carrier)) {
      console.log(`      ↳ ${NAMES[carrier]} cannot see this. Only ${readers.map(i => NAMES[i]).join(' & ')} can —`);
      console.log(`        the one who acts is not the one who learns, so it must be spoken.`);
    }
    if (sign.token !== 'no-reaction') { found = st; break; }
  }
  console.log(`\n    Probes spent: ${probes}${found ? ` — ward is ${found}.` : ` — ward not determined.`}`);
  console.log(`    Without the law it would have taken up to ${STIMULI.length}.`);
}

// ── Verdict ─────────────────────────────────────────────────────────────────
hr('THE VERDICT — what the party knows vs. what is true');
const known = new Set<string>();
ambient.forEach(s => { if (perceived.some(p => p.includes(s.channel))) known.add(AXIS_OF_CHANNEL[s.channel]); });
if (wardLive && perceived.some(p => p.includes('REACTION')) && bags.some(b => STIMULI.some(s => hasProbeKit(b, s)))) known.add('WARD');
console.log('');
for (const ax of liveAxes) {
  const v = (truth as Record<string, string | undefined>)[ax.toLowerCase().replace('rite_key', 'riteKey')]
         ?? (truth as Record<string, string | undefined>)[ax === 'RITE_KEY' ? 'riteKey' : ax.toLowerCase()];
  console.log(`    ${known.has(ax) ? '✓' : '✗'} ${QUESTION[ax]!.padEnd(42)} ${known.has(ax) ? v : '— never learned —'}`);
}
console.log(`\n    ${known.size} of ${liveAxes.length} questions answered.`);
console.log(`\n    At extraction the Field Testament would show the answers beside the signs —`);
console.log(`    the answer key, after the bet is settled. It is a STUB today (outcome:'success').\n`);
