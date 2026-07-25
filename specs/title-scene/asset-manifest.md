# Title Scene — Asset Manifest (TD-073)

> The list to generate, with the technical constraints that make the pieces **composite correctly
> the first time**. Each entry has a ready-to-paste prompt. Author art lands in `art/src/title/`,
> and `tools/title_assets.py` validates it and installs it to `client/assets/ui/title/`.
>
> **The scene rig treats every asset as optional.** A missing file simply skips its layer, so these
> can arrive one at a time and the screen keeps running.
>
> **This file and the rig are checked against each other.** `title_scene.gd` loads by exact
> filename and never errors on a name it does not know, so a manifest that drifts from the rig
> produces art that silently never appears — which is precisely what happened: this document asked
> for a `hall_plate.png` the rig had no slot for, listed a `chain.png` nothing loads, and omitted
> the seven architecture pieces the rig does load. `python3 tools/title_assets.py --check` now
> derives the slot list from the rig and fails if the two disagree.

## How to land a piece

```bash
mkdir -p art/src/title && cp <your>.png art/src/title/<exact name>.png
python3 tools/title_assets.py --import   # validate, install, and import into Godot
```

Then look at it: `"$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=3 --title-preview`.
No code change is needed for any asset below — the layer is already built and animated.

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

## Layer 1 — the architecture

The architecture can arrive **either way**, and the rig takes both. Start with the plate.

### The plate (the recommended path)

| File | Size | Alpha |
|---|---|---|
| `hall_plate.png` | 1920×1080 | opaque |

> **Shipped, and generated:** `client/assets/ui/gen_title_plate.py` emits this plate by ray-casting
> the hall through the camera TD-072 measured (imported from `gen_nave.py`, not re-derived). It is a
> deliberate retry of what TD-072 recorded as a failure, narrowed where that failed: the plate holds
> **no props** (the class of thing that failed at small scale) and **no baked fire** (the light is
> in-engine), so what is left is architecture — which the ray-caster was always good at. Regenerate
> with `python3 gen_title_plate.py` from `client/assets/ui/`. Author-painted art still replaces it
> by dropping a file of the same name into `art/src/title/`; the rig neither knows nor cares which
> produced it.

> A vast ancient Gothic cathedral interior, seen from floor level looking up the nave toward a
> distant lit altar. Towering compound piers, ribbed vaults, stained glass high on both walls, worn
> flagstone floor with a faded red carpet runner, weathered stone, centuries of soot and candle
> smoke. Deep shadow, warm amber ambient light. **Empty: no banners, no censers, no candles, no
> braziers, no people, no text.** Dark, solemn, painterly, 16:9.

Everything removable is removed **on purpose** — those become the animated layers below, and a plate
without them needs no inpainting. One painted plate holds a single coherent camera; seven separately
generated cutouts have to be re-aligned to each other by hand, which is the work this avoids.

It is drawn full-frame, aspect-preserved (**never distorted**, R241), with a 1.2% overscan so the
camera's 2px drift cannot walk an edge into view, and it never moves (P128).

### The pieces (optional overrides)

Authored separately, each of these **layers over the plate** — and used without a plate, the seven
of them are the architecture. Any piece you do not author simply stays with the plate. Sizes are
what the rig's width fractions come to on a 1920-wide frame; the art's own aspect wins, so treat
them as targets, not constraints.

| File | Size | Alpha | Notes |
|---|---|---|---|
| `pier_left.png` | 600×1470 | yes | the near framing pier; runs past top and bottom on purpose |
| `pier_right.png` | 600×1470 | yes | not a mirror — asymmetry is what sells it |
| `arcade_left.png` | 360×936 | yes | the receding arcade behind the pier |
| `arcade_right.png` | 360×936 | yes | |
| `vault.png` | 760×532 | yes | ribbed vault, seen from below, crowding the top third |
| `apse.png` | 290×390 | yes | the distant lit altar — the brightest thing in the frame |
| `floor.png` | 1920×500 | yes | worn flagstones + faded runner, receding |

> One element of a Gothic cathedral interior — a towering compound pier of weathered stone, seen
> from floor level looking up so the verticals converge. Transparent background, evenly lit, no
> baked highlight, centuries of soot. Painterly dark fantasy.

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

> **Shipped, and generated:** `client/assets/ui/gen_title_banners.py` — `gen_banner.py`'s idiom
> re-cut for the hall in the **painted** register (these hang at 340px, so smooth drape shading is
> right where it would be wrong on the board's 64px cloth). Each banner is **seeded separately**, so
> the right one is "mirror-ish, not identical": fold phase, hem wear, holes and threads all come off
> its own seed. The **iron rod is in the image**, because the rig sways from top centre — cloth and
> rod swing as one object. The emblem is the same `board/collegium_logo.png`, printed as a bone dye
> the weave shows through. Nothing is lit: folds are form, not light (the fires are in-engine).

## Layer 2 — hanging props

| File | Size | Alpha | Notes |
|---|---|---|---|
| `censer.png` | 140×420 | yes | includes its chain; **pivot at the top centre**; hung twice |
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

> **Shipped, and generated:** `client/assets/ui/gen_title_props.py` emits all four props (censer,
> chandelier, candle rack, brazier) as anti-aliased signed-distance parts composited back to front.
> **These are Python and not Aseprite on purpose**, and it is not a contradiction of TD-057: that
> finding was measured at **17×22 px**, where a shape function cannot decide which pixel carries the
> crossguard. At 140–520px in the painted register the job is *form* — cylinders, spheres, drip,
> tarnish — and a hand-placed pixel would be resampled away. Nothing burns: the candles have cold
> wicks and the brazier holds dead coals.

## Layer 2 — atmosphere overlays

| File | Size | Alpha | Notes |
|---|---|---|---|
| `dust_overlay.png` | 1920×1080 | yes | sparse motes, **greyscale-white**, tinted at runtime |
| `smoke_overlay.png` | 1920×1080 | yes | slow incense drifts, greyscale-white |
| `light_shaft.png` | 900×1080 | yes | one god-ray wedge, greyscale-white, soft edges |

> Soft volumetric light shaft falling at an angle through dusty air, pure white to transparent, no
> colour, no background. Used as an additive overlay.

Greyscale-white because the runtime tints them to the candle ramp — one asset serves warm and cold.

> **Shipped, and generated:** `client/assets/ui/gen_title_overlays.py` emits all three. They are
> pure surfaces — falloffs, value noise, a wedge — which is Python's half of the TD-057 split, and
> nothing in them is a per-pixel design decision. RGB is flat white and the whole image lives in
> the **alpha channel**, so under the rig's additive blend the sheet's contribution is exactly its
> alpha and `modulate` stays an honest dimmer. The frame's centre is deliberately thinned: the menu
> is read there (R245). Regenerate with `python3 gen_title_overlays.py` from `client/assets/ui/`.

---

## Naming, and why it matters

The rig loads by exact filename and skips what is absent. Keep these names and the layers wire
themselves up; rename anything and it silently vanishes from the scene rather than erroring — no
log line, no missing-resource error, just a layer that never appears. That failure mode is why
`tools/title_assets.py` exists: it reads the slot list out of `title_scene.gd`, so a name that
would vanish is a hard failure at the command line instead of a mystery in a capture.

Run it after every drop:

```bash
python3 tools/title_assets.py --check     # slots filled, contract intact
python3 tools/title_assets.py --selftest  # the rules themselves
```

## What happens to the current composite

`art/src/collegium_hall_src.png` stays a **composition reference only** — never shipped, never
displayed (TD-073, the author's ruling after it was tried as the background three times). There is
no matte generator to retire: painted source art is copied byte-for-byte into the client, because
re-encoding a painted matte through a pixel-art generator is the register mistake TD-055 warns
about. The plate is the one deliberate painted-register exception (R242); board and HUD surfaces
keep the pixel register untouched (P127).
