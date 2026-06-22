// Web Audio API sound manager. All sounds are synthesized — no audio files needed.
// The AudioContext is created lazily on first user interaction (browser autoplay policy).

let ctx: AudioContext | null = null;

function getCtx(): AudioContext {
  if (!ctx) ctx = new AudioContext();
  // Resume if suspended (browser may suspend after inactivity).
  if (ctx.state === 'suspended') ctx.resume().catch(() => {});
  return ctx;
}

// Plays a short envelope using an OscillatorNode + GainNode.
function tone(
  frequency: number,
  type: OscillatorType,
  gainPeak: number,
  attackS: number,
  decayS: number,
  sustainGain: number,
  releaseS: number,
): void {
  try {
    const ac = getCtx();
    const osc = ac.createOscillator();
    const gain = ac.createGain();
    osc.connect(gain);
    gain.connect(ac.destination);

    osc.type = type;
    osc.frequency.setValueAtTime(frequency, ac.currentTime);

    const t = ac.currentTime;
    gain.gain.setValueAtTime(0, t);
    gain.gain.linearRampToValueAtTime(gainPeak, t + attackS);
    gain.gain.linearRampToValueAtTime(sustainGain, t + attackS + decayS);
    gain.gain.setValueAtTime(sustainGain, t + attackS + decayS);
    gain.gain.linearRampToValueAtTime(0, t + attackS + decayS + releaseS);

    osc.start(t);
    osc.stop(t + attackS + decayS + releaseS);
  } catch {
    // AudioContext unavailable (e.g., test environment) — silently skip.
  }
}

// Burst of noise for hit/death effects.
function noise(gainPeak: number, durationS: number): void {
  try {
    const ac = getCtx();
    const bufferSize = Math.floor(ac.sampleRate * durationS);
    const buffer = ac.createBuffer(1, bufferSize, ac.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) data[i] = Math.random() * 2 - 1;

    const src = ac.createBufferSource();
    src.buffer = buffer;

    const gain = ac.createGain();
    src.connect(gain);
    gain.connect(ac.destination);

    const t = ac.currentTime;
    gain.gain.setValueAtTime(gainPeak, t);
    gain.gain.exponentialRampToValueAtTime(0.001, t + durationS);

    src.start(t);
    src.stop(t + durationS);
  } catch {
    // Silently skip.
  }
}

export const SoundManager = {
  // Pew — short high-pitched blip when a projectile is fired.
  projectileFired(): void {
    tone(880, 'square', 0.08, 0.005, 0.03, 0.02, 0.05);
  },

  // Thud — low impact when a projectile hits an enemy.
  projectileHit(): void {
    tone(120, 'sawtooth', 0.15, 0.003, 0.04, 0.0, 0.06);
    noise(0.08, 0.06);
  },

  // Crunch — short noise burst when a player takes damage.
  playerHit(): void {
    tone(220, 'sawtooth', 0.2, 0.002, 0.05, 0.0, 0.08);
    noise(0.12, 0.08);
  },

  // Thump — enemy death pop.
  enemyDied(): void {
    tone(80, 'sine', 0.2, 0.005, 0.08, 0.0, 0.12);
  },

  // Descending two-tone — bleed clock critically low (≤ 10%).
  bleedWarning(): void {
    tone(440, 'sine', 0.15, 0.01, 0.05, 0.08, 0.1);
    setTimeout(() => tone(330, 'sine', 0.12, 0.01, 0.05, 0.0, 0.15), 180);
  },

  // Ascending arpeggio — floor cleared.
  floorCleared(): void {
    [523, 659, 784].forEach((f, i) => {
      setTimeout(() => tone(f, 'sine', 0.15, 0.01, 0.05, 0.05, 0.12), i * 100);
    });
  },
};
