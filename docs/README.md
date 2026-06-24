# Veins — Design Bible

The single navigable home for Veins design, lore, systems, and engineering docs. Start with [pitch.md](pitch.md), then [vision.md](vision.md).

## Map

### Core
| File | What's in it |
|------|--------------|
| [pitch.md](pitch.md) | The one-liner, the elevator pitch, the core innovation, design identity |
| [vision.md](vision.md) | Why it works, target experience, design principles, emotional identity |
| [prototype-v1.md](prototype-v1.md) | The v1 vertical-slice scope, game loop, success criteria, build status |

### World & narrative
| File | What's in it |
|------|--------------|
| [lore.md](lore.md) | The Vessels, the narrative problem, endings |
| [cosmology.md](cosmology.md) | The Veins, The Heart, the interpretation system |
| [doctrines.md](doctrines.md) | Doctrine as concept (build = belief, theology syntax) |
| [factions.md](factions.md) | The four doctrines personified (identity, boss, room aesthetic) |

### Presentation
| File | What's in it |
|------|--------------|
| [art-bible.md](art-bible.md) | Visual/genre direction, palette, motion, audio |
| [ui-style-guide.md](ui-style-guide.md) | Controls, auto-aim, HUD inventory, UI direction |
| [progression.md](progression.md) | Meta-progression, rewards, endings-as-milestones |

### [systems/](systems/) — game mechanics
[circulatory-board](systems/circulatory-board.md) · [bleed-clock](systems/bleed-clock.md) · [linked-fates](systems/linked-fates.md) · [relics](systems/relics.md) · [doctrine-tracking](systems/doctrine-tracking.md) · [combat](systems/combat.md) · [extraction](systems/extraction.md) · [solo-play](systems/solo-play.md)

### [content/](content/) — concrete game content
[relic-roster](content/relic-roster.md) · [enemies](content/enemies.md) · [bosses](content/bosses.md) · [biomes](content/biomes.md) · [mutations](content/mutations.md)

### [technical/](technical/) — engineering
[architecture](technical/architecture.md) · [netcode](technical/netcode.md) · [determinism-and-rng](technical/determinism-and-rng.md) · [stack-and-deployment](technical/stack-and-deployment.md)

### Reference (kept in place, not restructured)
| File | Role |
|------|------|
| [GLOSSARY.md](GLOSSARY.md) | Canonical terms — use exactly as written. Wired into `CLAUDE.md`. |
| [DECISION_LOG.md](DECISION_LOG.md) | **Append-only** dated build/architecture history. Never edit past entries. |
| `GPT_CHAT_HISTORY.txt` | Raw aesthetic brainstorm archive — the source for "Draft" material below. |

---

## Maintenance contract

### Where does new content go?
| If it's… | …it goes in |
|----------|-------------|
| a concept / belief / narrative idea | `doctrines.md`, `factions.md`, `lore.md`, `cosmology.md` |
| a game *mechanic* (rules, how a system behaves) | `systems/` |
| concrete game *content* (a relic, enemy, boss, biome) | `content/` |
| visual / audio / UI direction | `art-bible.md`, `ui-style-guide.md` |
| an engineering decision or how something is built | `technical/` |
| a new canonical *term* | `GLOSSARY.md` |
| a dated decision / why something changed | append to `DECISION_LOG.md` (never edit) |

### Canon vs Draft
- **Canon** = derived from the original design docs and the implemented build.
- **Draft (exploratory)** = mined from `GPT_CHAT_HISTORY.txt`. It always sits under a `## Draft / Exploratory` heading, and any conflict with canon (e.g. alternate faction names) is flagged inline. Promote draft → canon by ratifying it and removing the draft fence.

### Every file starts with a header
```
> **Status:** Canon | Draft (exploratory) | Mixed
> **Sources:** <original doc/section(s)>
> **See also:** <links to sibling files>
```

### Provenance
This bible was decomposed from five originals: `DESIGN.md`, `LORE_DESIGN.md`, and `SYSTEM DESIGN DOC.md` (migrated here and removed), plus `GLOSSARY.md` and `DECISION_LOG.md` (kept in place). `technical/` files are reader-facing summaries; the binding rules remain in `.claude/rules/` and the dated history in `DECISION_LOG.md`.
