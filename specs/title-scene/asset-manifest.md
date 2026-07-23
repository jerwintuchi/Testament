# Title Scene — Asset Manifest (TD-073)

> The list to generate, with the technical constraints that make the pieces **composite correctly
> the first time**. Each entry has a ready-to-paste prompt. Author art lands in `art/src/`, is
> processed by `gen_title_assets.py`, and ships to `client/assets/ui/title/`.
>
> **The scene rig treats every asset as optional.** A missing file simply skips its layer, so these
> can arrive one at a time and the screen keeps running.

## Rules that apply to everything

1. **One camera.** Every piece must be drawn in the *same* perspective as the plate — a low camera
   looking up a Gothic nave, verticals converging. If a prop is drawn straight-on it will not sit in
   the scene.
2. **16:9 for full-frame layers**, 1920×1080. Props are their own size, listed below.
3. **True alpha**, not a black or checkerboard background, on everything except the plate.
4. **No baked UI.** No title, no menu, no logo — those are rendered live. (The current plate has
   them painted in and needed inpainting; a clean plate removes that whole problem.)
5. **No characters, no creatures, no weapons in use.** Pillar 3: the title must never show an
   Incarnate.
6. **Unlit or evenly lit props.** Godot adds the flicker and glow (Layer 3). A prop with a baked
   hotspot will fight the real light.

---

## Layer 1 — the plate

| File | Size | Alpha |
|---|---|---|
| `hall_plate.png` | 1920×1080 | opaque |

> A vast ancient Gothic cathedral interior, seen from floor level looking up the nave toward a
> distant lit altar. Towering compound piers, ribbed vaults, stained glass high on both walls, worn
> flagstone floor with a faded red carpet runner, weathered stone, centuries of soot and candle
> smoke. Deep shadow, warm amber ambient light. **Empty: no banners, no censers, no candles, no
> braziers, no people, no text.** Dark, solemn, painterly, 16:9.

Everything removable is removed **on purpose** — those become the animated layers below, and a plate
without them needs no inpainting.

## Layer 2 — cloth

| File | Size | Alpha | Notes |
|---|---|---|---|
| `banner_left.png` | 340×760 | yes | hangs on the left pier, top-anchored |
| `banner_right.png` | 340×760 | yes | mirror-ish, not identical — asymmetry sells it |
| `banner_center.png` | 260×620 | yes | smaller, deeper in the nave |

> A long hanging medieval banner of faded crimson cloth, worn and dust-aged, with a pale bone-white
> emblem of an upright sword crossed with laurel wreaths. Frayed lower hem, soft vertical folds,
> hanging from a dark iron rod. **Transparent background.** Lit softly and evenly, no strong
> highlight. Painterly, dark fantasy.

## Layer 2 — hanging props

| File | Size | Alpha | Notes |
|---|---|---|---|
| `censer.png` | 140×420 | yes | includes its chain; **pivot at the top centre** |
| `chain.png` | 40×500 | yes | plain hanging chain, tileable vertically |
| `chandelier.png` | 420×300 | yes | optional, for the deep nave |

> An ornate hanging brass censer on a long chain, aged and tarnished, pierced metalwork, small ruby
> glass panels, gothic ecclesiastical. **The chain must run to the very top edge of the image** so it
> can hang from off-screen. Transparent background. Unlit — no glow baked in.

## Layer 2 — fire vessels

| File | Size | Alpha | Notes |
|---|---|---|---|
| `candle_rack.png` | 520×300 | yes | a rank of tapers at **varying heights** |
| `brazier.png` | 300×280 | yes | large standing iron brazier, **no flame** |

> A votive candle rack: an aged iron stand holding two dozen white wax candles of differing heights,
> heavy wax runs down the frame. **Unlit — draw the candles but NOT the flames**, transparent
> background. Godot adds the fire.

Flames are deliberately excluded: they are Layer 3, generated in-engine so each flickers
independently.

## Layer 2 — atmosphere overlays

| File | Size | Alpha | Notes |
|---|---|---|---|
| `dust_overlay.png` | 1920×1080 | yes | sparse motes, **greyscale-white**, tinted at runtime |
| `smoke_overlay.png` | 1920×1080 | yes | slow incense drifts, greyscale-white |
| `light_shaft.png` | 900×1080 | yes | one god-ray wedge, greyscale-white, soft edges |

> Soft volumetric light shaft falling at an angle through dusty air, pure white to transparent, no
> colour, no background. Used as an additive overlay.

Greyscale-white because the runtime tints them to the candle ramp — one asset serves warm and cold.

---

## Naming, and why it matters

The rig loads by exact filename and skips what is absent. Keep these names and the layers wire
themselves up; rename anything and it silently vanishes from the scene rather than erroring.

## What happens to the current composite

`art/src/collegium_hall_src.png` stays as the **reference** and as today's stand-in plate. Once
`hall_plate.png` lands, the inpainting in `gen_title_matte.py` is deleted outright — it only ever
existed to remove baked UI, and a clean plate makes it unnecessary.
