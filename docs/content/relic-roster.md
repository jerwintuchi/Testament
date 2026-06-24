# Content — Relic Roster

> **Status:** Mixed (canon paper roster + implemented starter set + draft organ-relics)
> **Sources:** SYSTEM DESIGN DOC.md §3 (12 designed relics); DECISION_LOG.md (board-ui STARTER_RELICS, relic-effects); GPT_CHAT_HISTORY.txt (draft, organ-relics)
> **See also:** [systems/relics.md](../systems/relics.md) · [doctrines.md](../doctrines.md) · [content/mutations.md](mutations.md)

For the relic *system* (base/synergy effects, tags, slot rules), see [systems/relics.md](../systems/relics.md).

## Paper design — the 12 v1 relics (by doctrine)

### Sanctum
1. **Lumen Seal** — +10% damage if no mutation relic adjacent; adjacency bonus suppresses randomness.
2. **Ivory Node** — non-adjacent relics gain +5% effect.
3. **Static Plate** — prevents negative mutation effects on owner.

### Chorus
4. **Resonant Coil** — adjacent relic effects are shared with nearest ally.
5. **Dual Pulse** — synced ability usage increases damage (stacking buff).
6. **Neural Bridge** — 1 relic effect mirrored to teammate slot.

### Tumor
7. **Growth Sac** — random effect mutation every 2 rooms.
8. **Fractal Cell** — adjacency effects increase over time.
9. **Hematic Bloom** — kills spawn temporary buff spores.

### Penitent
10. **Ash Reliquary** — sacrifice relic = permanent +15% scaling.
11. **Quiet Coil** — stationary = damage reduction + scaling.
12. **Burden Chain** — carry "lost relics" for stacking buffs.

## Implemented — STARTER_RELICS (current build)

The shipped prototype hard-codes 10 starter relics in `@veins/shared` (3 tag-pairs for synergy). Combat-resolving effects currently wired (see [systems/combat.md](../systems/combat.md)):

- **ember-core** — bonus damage + splash.
- **torch-brand** — fire DoT.
- **arc-bolt** — chain lightning.
- **iron-skin** — incoming damage reduction.
- **void-lens** — intentionally left **doctrine-neutral** (no doctrine tag).

All 10 carry doctrine tags (`sanctum`/`tumor`/`chorus`/`penitent`) except `void-lens`. Doctrine scoring keys off these tags — see [systems/doctrine-tracking.md](../systems/doctrine-tracking.md).

> The paper 12 and the implemented 10 are not yet reconciled into one canonical list. Treat the implemented set as the source of truth for *current behavior* and the paper set as design intent.

---

## Draft / Exploratory — Relics as organs

> Mined from `GPT_CHAT_HISTORY.txt`. Flavor direction: relics are **organs**, not items. Not yet ratified.

- **Left Ventricle** — +15% attack speed; adjacent to **Right Ventricle** → synchronized attacks.
- **Optic Nerve** — crits reveal weak spots; adjacent to another player's **Cerebellum** → shared vision.
- **Spleen** — revives stronger; adjacent to **Bone Marrow** → sacrifice consumes only half effect.
- **Tumor** — huge buffs, random mutations, can spread to adjacent relics; high-risk archetype (see [content/mutations.md](mutations.md)).
