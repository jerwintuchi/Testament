# VEINS — System Design Doc v1 (Playable Vertical Slice)

## 0. Scope of v1

This version defines:

- 1 full playable dungeon run loop
- 1 biome set (initial “Atrium”)
- 10–15 relics
- 1 boss (Doctrine Test Boss)
- Circulatory Board system (core mechanic)
- Basic doctrine tracking (hidden)
- Extraction + Bleed Clock loop

NOT included:
- full faction roster
- full mutation system
- multiple biomes
- full meta progression system

---

# 1. CORE GAME LOOP

## Run Structure

1. Lobby (room code join, 2–4 players)
2. Spawn in Atrium
3. Repeat loop:
   - Combat room
   - Loot room (relic choice)
   - Board placement phase
   - Bleed Clock updates
4. Mid-boss encounter
5. Final boss encounter
6. Extraction OR wipe
7. Reward + persistence update

---

## Session Length Target

- 20–30 minutes per run
- 5–8 rooms before boss
- 1 boss per run (v1)

---

# 2. CORE SYSTEMS

---

# 2.1 CIRCULATORY BOARD SYSTEM (CORE MECHANIC)

## Structure

- Each player has a **shared 2D hex board**
- Board size: 5x5 shared grid (or equivalent hex layout)
- Each relic occupies 1 slot

## Rules

- Adjacent relics create “links”
- Links activate conditional synergy effects
- Some effects only trigger across players

---

## Link Types (v1)

### Direct adjacency
- Horizontal / vertical / hex neighbors

### Cross-player adjacency
- Adjacent relics owned by different players

---

## Synergy Trigger Rule

A synergy triggers when:


2+ relics are adjacent AND condition is met


Example conditions:
- same doctrine alignment
- cross-player connection
- mutation state present
- sacrifice event occurred

---

## Design Principle

> Placement is decision. Not inventory.

---

# 2.2 BLEED CLOCK SYSTEM

## Definition

Global pressure meter representing:

> Reality instability under conflicting doctrines

---

## Behavior

- Starts at 0%
- Increases over time + room progression
- Increases faster deeper in dungeon

---

## Effects

| Stage | Effect |
|------|--------|
| 0–30% | normal |
| 30–60% | enemy aggression increases |
| 60–80% | room modifiers begin |
| 80–100% | forced extraction pressure |

---

## Fail Condition

At 100%:
- dungeon collapses
- forced wipe OR emergency extraction event

---

# 2.3 DOCTRINE SYSTEM (HIDDEN)

## Axes

Each run tracks 4 hidden values:

- Sanctum (stability)
- Tumor (mutation volatility)
- Chorus (sync strength)
- Penitent (sacrifice tendency)

---

## Rule

> The system does NOT show these values.

Only effects are visible.

---

## Influence Sources

| Action | Effect |
|------|--------|
| stable adjacency usage | Sanctum + |
| mutation relic usage | Tumor + |
| coordinated timing | Chorus + |
| sacrificing relics | Penitent + |

---

# 2.4 RELIC SYSTEM (V1)

## Definition

Relics are:

> modular rule modifiers applied to board slots

---

## Relic Types

- Passive
- Conditional
- Synergy-triggered

---

## Slot Rules

- 1 relic = 1 board node
- adjacency modifies effect
- cross-player adjacency = amplified effects

---

# 3. INITIAL RELIC SET (V1)

---

## SANCTUM RELICS

### 1. Lumen Seal
- +10% damage if no mutation relic adjacent
- adjacency bonus suppressed randomness

### 2. Ivory Node
- non-adjacent relics gain +5% effect

### 3. Static Plate
- prevents negative mutation effects on owner

---

## CHORUS RELICS

### 4. Resonant Coil
- adjacent relic effects are shared with nearest ally

### 5. Dual Pulse
- synced ability usage increases damage (stacking buff)

### 6. Neural Bridge
- 1 relic effect mirrored to teammate slot

---

## TUMOR RELICS

### 7. Growth Sac
- random effect mutation every 2 rooms

### 8. Fractal Cell
- adjacency effects increase over time

### 9. Hematic Bloom
- kills spawn temporary buff spores

---

## PENITENT RELICS

### 10. Ash Reliquary
- sacrifice relic = permanent +15% scaling

### 11. Quiet Coil
- stationary = damage reduction + scaling

### 12. Burden Chain
- carry “lost relics” for stacking buffs

---

# 4. COMBAT SYSTEM (V1)

## Core Format

- top-down action combat
- light / heavy attack OR ability-based system
- dodge / dash required

---

## Design Rule

> Combat is readable, but modified by doctrine systems.

---

## Enemy Behavior Principles

Enemies are simple individually but complex in groups.

---

# 5. ATRIUM BIOME (V1 ONLY BIOME)

## Theme

> Living cathedral-organism of flesh and bone

---

## Visual Rules

- pulsating walls
- vein-like corridors
- soft organic lighting
- no hard geometry repetition

---

## Room Types

### Combat Room
- enemies + environmental hazard

### Relic Room
- choose 1 of 3 relics

### Pressure Room
- high Bleed Clock gain, high reward

---

# 6. BOSS SYSTEM (V1 ONLY BOSS)

---

# 6.1 BOSS: “THE PULSING INTERPRETER”

## Identity

A semi-organic construct inside the Veins that:

> enforces coherence in player doctrine

---

## Behavior

Boss adapts based on dominant doctrine of party:

---

### If Sanctum dominant:
- reduces randomness
- predictable attack patterns
- punishes overconfidence

---

### If Tumor dominant:
- evolves mid-fight
- changes attack patterns frequently

---

### If Chorus dominant:
- mirrors player actions
- punishes desync

---

### If Penitent dominant:
- punishes hesitation
- punishes inactivity windows

---

## Phase Design

### Phase 1
- neutral interpretation
- tests baseline mechanics

### Phase 2
- reacts to doctrine pattern
- introduces counter-pattern

### Phase 3
- full interpretation conflict
- hybrid mechanics

---

## Win Condition

Boss does not “die.”

It:

> collapses into unstable interpretation fragments

These fragments become relic rewards.

---

# 7. EXTRACT / FAILURE SYSTEM

---

## Extraction Types

- Normal extraction (successful run)
- Forced extraction (Bleed Clock maxed)
- Sacrificial extraction (one player left behind)
- Total wipe

---

## Reward Logic

Rewards depend on:

- depth reached
- doctrine alignment strength
- boss interpretation outcome

---

# 8. CORE DESIGN PRINCIPLES (NON-NEGOTIABLE)

---

## 8.1 No explicit doctrine UI

Players never see:
- “Sanctum +12”

Only effects.

---

## 8.2 Delayed consequence system

World reacts AFTER behavior is established.

---

## 8.3 Build = belief consistency

Not optimization.

Consistency matters more than raw power.

---

## 8.4 Co-op is structural, not optional

Game assumes multiple players.

Solo is degraded experience by design.

---

# 9. V1 SUCCESS CRITERIA

If successful, players should say:

- “Our build felt like a philosophy”
- “The boss reacted to how we played”
- “We accidentally built synergy that felt intentional”
- “The game felt like it was watching us”

---

# END OF V1