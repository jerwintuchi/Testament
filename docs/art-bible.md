# Veins — Art Bible

> **Status:** Mixed (canon Atrium visual rules + draft aesthetic direction)
> **Sources:** SYSTEM DESIGN DOC.md §5 (Atrium visual rules); LORE_DESIGN.md §11 (Room-gen aesthetics); GPT_CHAT_HISTORY.txt (draft, the bulk of the aesthetic vision)
> **See also:** [ui-style-guide.md](ui-style-guide.md) · [content/biomes.md](content/biomes.md) · [vision.md](vision.md)

## Canon — Atrium visual rules (v1 biome)

The Atrium is a **living cathedral-organism of flesh and bone**. Visual rules:

- pulsating walls
- vein-like corridors
- soft organic lighting
- no hard geometry repetition

Doctrine shapes room aesthetics (see [factions.md](factions.md)): Sanctum = geometric/symmetrical; Tumor = organic/asymmetric/evolving; Chorus = mirrored/synchronized; Penitent = sparse/oppressive.

> **Implementation note (current build):** rendering uses Phaser 3 primitive shapes (Graphics, Arc, Rectangle) — no sprite sheets yet. Real art is a drop-in swap for the primitive draw calls. See [technical/stack-and-deployment.md](technical/stack-and-deployment.md).

---

## Draft / Exploratory — Aesthetic & genre direction

> Mined from `GPT_CHAT_HISTORY.txt`. Captures the intended look/feel; not yet ratified into the canon docs.

### Genre pillars

**Cosmic Biopunk + Bloodborne organism horror.** Not gore horror, not zombies. Think: veins, nerves, pulsating architecture, living dungeons, parasitic relics, strange anatomy.

### Inspirations

- **Visual:** Scorn, Darkest Dungeon, Bloodborne, Hyper Light Drifter, Signalis, Moonscars, Blasphemous.
- **Mechanical:** Risk of Rain 2, FTL, Deep Rock Galactic, Monster Hunter, Escape from Tarkov (extraction tension).

### Art style

Not pixel art (crowded; browser games need readability). Target: **2D top-down hand-painted biopunk** — Hyper Light Drifter shapes, Darkest Dungeon colors, Diablo atmosphere, Dead Cells readability.

A stylized **PS1 / Signalis / Hyper Light Drifter hybrid** is also floated for browser-first delivery: low-poly sprites with bloom, optional CRT filter, blood-cell particles, soft shadows — tiny asset sizes, easy web deployment, distinctive identity.

### Color palette

- **Flesh:** reds, crimson, burgundy, rust.
- **Bone:** ivory, beige.
- **Organ:** blues, cyan, teal.
- **Corruption:** purple.

### Motion — everything feels alive

- Walls breathe.
- Roots pulse.
- Doors contract open.
- Particles drift like blood cells.

Rooms aren't "stone rooms" — they're **anatomy** (heartroom, vein tunnel, abscess hall). See [content/biomes.md](content/biomes.md) for the biome list.

### Audio direction

**Dark ambient + organic synth.** Study: Disasterpeace (Hyper Light Drifter), Atrium Carceri, Darkest Dungeon OST, Signalis OST. Not orchestral, no epic fantasy. Low drones, heartbeat percussion, breathing sounds, pulses.

> When the Bleed Clock rises, music BPM rises too — players should feel stress physically.
