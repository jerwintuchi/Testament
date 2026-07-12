# Testament - Art Direction (Overview)

> **Status:** Canon (register set by DECISION_LOG TD-046, 2026-07-12).
> **Spine:** Observe -> Hypothesize -> Test -> Record  ·  **Index:** [README.md](README.md)

## Purpose

The gothic ecclesiastical dark-fantasy direction (Blasphemous, Castlevania, Dante's Inferno, Witcher): cathedrals, pilgrimage, reliquaries, sacred decay. Avoid generic Lovecraftian tentacle horror. See [art/style-guide.md](art/style-guide.md) and [art/audio-direction.md](art/audio-direction.md) for the detailed guides.

## Design Philosophy

**One register: hand-painted raster 2D pixel art** (TD-046). Warm, weathered, aged,
and **dramatically torch-lit**, in the **Prototype v1** idiom. The world is *lit, not
evenly bright*: every surface reads as a real, aged object under a real light source, so
the player's eye trusts what it sees and can *read* it (the spine — Observe). Flat
greybox and evenly-lit UI are the failure state.

## Non-negotiable Rules

1. **Raster PNG, imported Nearest.** Every UI/world surface is an authored raster PNG —
   never runtime vector primitives standing in for art. Claude authors them with the
   Python generators and imports new files headlessly (`godot --headless --import`).
2. **In-engine lighting is mandatory** (TD-043): per-source Light2D, particle flames,
   shaders; AO and drop shadows where objects overlap. Nothing is pasted-on.
3. **No palette-lock** (TD-046): 24-bit painted ramps, gradients, bevel shading are the
   norm; the old 15-colour lock is retired.
4. **Shadows share one light direction per scene.** A shadow with no source is a bug.
5. **Trait-free** (game-truth): no Incarnate art, no threat/reward on the wall (I3/I5).
6. Tool purge stands (TD-033): no 3D, no `.blend`/`.fbx`/`.gltf`/`.obj`, no MediBang.

## Implementation Notes

Client-only (render). 640×360 internal (TD-042), integer-scaled by the `PixelScale`
autoload, Nearest. UI is Godot Control nodes skinned with raster 9-slices + textures;
the Notice Board (`client/scripts/ui/`) is the canonical worked example — carved gilded
frame, aged parchment notices, wax seals, banner torches with Light2D. Generators live in
`client/assets/ui/*.py` (`ashember.py` toolkit + `gen_*.py`).

## Future Expansion

The board's register propagates to field tiles, Seeker sprites, HUD, and menus. As
content scales, the generators grow authored variation (parchment ages, seal Origins,
frame wear) rather than one-off handmade sheets.
