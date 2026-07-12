# Visual Style Guide

> **Status:** Canon (register set by DECISION_LOG TD-046, 2026-07-12).
> **Spine:** Observe -> Hypothesize -> Test -> Record  ·  **Index:** [../README.md](../README.md)

## Purpose

Palette, lighting, silhouette, tilesets, character and Incarnate design language, and UI
styled as a torch-lit commission wall of illuminated parchment.

## Design Philosophy

**Hand-painted raster 2D pixel art** (TD-046) — the Prototype v1 idiom. Read every asset
as a physical, aged object under one warm light.

## Non-negotiable Rules

1. **Raster PNGs, Nearest, no palette-lock.** 24-bit painted ramps + gradients + AO.
2. **One light per scene.** All shadows cast from the same direction, same softness.
3. **Depth is earned, not faked:** overlapping objects get contact AO + a cast shadow;
   raised objects (crest, seals, tacks) get a bevel highlight on the light-facing edge.
4. **No competing focal points.** Warm gilt draws the eye to the headline/target first;
   decor (cobweb, votive, foxing) stays low-contrast ambience.

## Palette (Ash & Ember, reference ramps — not a lock)

- **Wood/frame:** warm red-brown, `#562F18`–`#8E4F19` gilt-edged.
- **Parchment:** `#CBB583` floor → `#E8D8A8` lit; aged/foxed variants darker & browner.
- **Ink:** `#2A2115` headline; `#3E3120` body. **Gilt:** `#D8B45A`. **Threat:** `#CC4A4A`.
- **Fire:** ember `#E8973C`, glow `#F0B25F`, light cast `#FFB86B`.

## Implementation Notes

Render-only client. Generators in `client/assets/ui/*.py` (`ashember.py` + `gen_*.py`);
new PNGs imported via `godot --headless --import`. Board render in
`client/scripts/ui/` (geometry, decor, notice card, reader, seal, badge, pips).

## Future Expansion

Extend the ramps and the generator variation as Incarnate Origins, sites, and Seeker
kits arrive; keep the one-light, raster, no-lock discipline.
