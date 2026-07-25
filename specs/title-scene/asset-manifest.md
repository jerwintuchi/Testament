# Title Scene — Asset Manifest (TD-073 → TD-075 → **TD-076, current**)

> **CURRENT: the hall is the author's PIXEL-ART base** (`art/src/title/hall_base_src.jpeg`), which
> supersedes the painting below. Measured: native at 1536×1024 (no upscale factor detected), 3:2,
> greyscale. Processed by `gen_title_matte.py` — cropped to 16:9 (110px off the top, 50 off the
> bottom: the vault has headroom, the floor and altar steps do not), scaled once to 1280×720, and
> graded warm along the navestone ramp because Testament is not grey.
>
> **It is architecture only, and that is why it wins.** No banners, censers, candle stands or
> braziers in the image, so every one of those layers ANIMATES again — `PROPS_IN_PLATE = false`.
> The painting had its furniture frozen into it.
>
> *(superseded)* **the hall is the author's painting.** After four procedural rebuilds the author ruled:
> *"disregard the constraints and make the great hall almost 1:1 to the reference image."* The only
> thing 1:1 with a painting is that painting, so `gen_title_matte.py` processes it into the client at
> **1280×720**, drawn 1:1 on device pixels at a 720p window through NEAREST — no filtering anywhere.
>
> **The prop layers stand down.** The painting contains its own banners, censers, candle stands and
> braziers, so drawing ours would double every one. `PROPS_IN_PLATE` in `title_scene.gd` turns them
> off; the files and the asset contract are untouched, one flag away.
>
> **What still animates:** the fire pools (moved onto the painting's own lights), the dust, the
> smoke and the god-ray. They are art-independent, which is why they survived the change of route.
>
> **The board's register no longer governs the title screen** — a deliberate reversal, recorded in
> DECISION_LOG TD-076 along with the measured evidence for it. Every other surface in the game keeps
> the pixel register untouched.
>
> **This file and the rig are checked against each other:** `python3 tools/title_assets.py --check`
> derives the slot list from `title_scene.gd` and fails if the two disagree. The rig loads by exact
> filename and silently skips what it does not know, so drift here produces art that never appears.

## How to land a piece

```bash
mkdir -p art/src/title && cp <your>.png art/src/title/<exact name>.png
python3 tools/title_assets.py --import   # validate, install, and import into Godot
```

Or regenerate, from `client/assets/ui/`:

```bash
python3 gen_title_matte.py --fidelity   # the hall: the author's painting at 1280x720  [SHIPPED]
python3 gen_title_matte.py --register   # the same painting down to the board's grain  [see below]
python3 gen_title_overlays.py           # dust, smoke, the god ray
python3 gen_title_furniture.py          # the pixel props — built, not currently drawn
```

Then look at it: `"$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=4 --title-preview`.

---

## The hall

| File | Size | Alpha | Source |
|---|---|---|---|
| `hall_plate.png` | 1280×720 | opaque | `art/src/title/hall_plate_src.jpeg` via `gen_title_matte.py` |

**Both treatments were built and captured rather than argued about**, and the losing one is kept
because the evidence is the point:

| | Result |
|---|---|
| `--register` | 640×360, on-palette, median + two mode passes: **31 colours, 523 single-pixel islands** against a naive downscale's 5876. A technical success and an artistic failure — the architecture dissolves, because the painting's structure lives at a frequency 640×360 cannot hold |
| `--fidelity` | 1280×720, LANCZOS, drawn **1:1 on device pixels** at 720p. Reads as the painting itself. **Shipped** |

The 1:1 mapping is what keeps it crisp without filtering: at a 720p window `PixelScale` gives a
640×360 logical viewport rendered at 1280×720 device pixels, so a 1280×720 texture drawn into the
full-frame rect lands one art pixel per device pixel under NEAREST.

**Retired with the procedural route:** `gen_title_hall.py`'s ray-cast plate and the seven per-surface
architecture slices. `hall_geometry.py` is *kept* — its curved vault and cylindrical piers fixed a
real flat-plane defect and carry tests a painted surface cannot pass, and it may serve an in-game
Collegium screen where a generated environment is worth more than a painted one (TD-076).

## Cloth

*Drawn and animated again: the pixel-art base has no furniture of its own. Authored at **twice** the
old pixel count at the same display size, so they sit on the hall's grain rather than reading as
2×2 blocks against it.*

| File | Size | Alpha | Notes |
|---|---|---|---|
| `banner_left.png` | 132×336 | yes | hangs on the left pier, crest in bone dye |
| `banner_right.png` | 132×324 | yes | its own weave and wear — not a mirror |
| `banner_center.png` | 52×124 | yes | small, deep, hung from the frame's top edge |

## Hanging props

| File | Size | Alpha | Notes |
|---|---|---|---|
| `censer.png` | 40×124 | yes | the chain runs to the **top edge**; hung twice |
| `chandelier.png` | 88×60 | yes | an iron corona on three chains |

## Fire vessels

| File | Size | Alpha | Notes |
|---|---|---|---|
| `candle_rack.png` | 192×110 | yes | tapers at varying heights; stands left |
| `candle_rack_b.png` | 176×102 | yes | its own rack; stands right, further off |
| `brazier.png` | 90×84 | yes | standing iron bowl, **no flame**; stands left |
| `brazier_b.png` | 84×78 | yes | a different bowl; stands right, further off |

**Nothing burns in the art.** Cold wicks, dead coals. Every flame in this scene is an in-engine
additive pool that flickers out of step (TD-043); a baked hotspot would fight it.

## Atmosphere overlays

| File | Size | Alpha | Notes |
|---|---|---|---|
| `dust_overlay.png` | 640×360 | yes | motes as **whole pixels**, 1px and the odd 2×2 |
| `smoke_overlay.png` | 640×360 | yes | incense off the censers, in four alpha steps |
| `light_shaft.png` | 300×360 | yes | one god ray, **three flat bands** |

Greyscale-white with the whole image in the **alpha channel**, so under the rig's additive blend the
sheet's contribution is exactly its alpha. Banded, never smooth: a continuous falloff needs dithering
to survive, and dithering is what the brief rules out. The frame's centre is thinned — the menu is
read there (R245).

---

## Naming, and why it matters

The rig loads by exact filename and skips what is absent — no log line, no missing-resource error,
just a layer that never appears. That failure mode is why `tools/title_assets.py` exists: it reads
the slot list out of `title_scene.gd`, so a name that would vanish is a hard failure at the command
line instead of a mystery in a capture. Run it after every drop:

```bash
python3 tools/title_assets.py --check     # slots filled, contract intact
python3 tools/title_assets.py --selftest  # the rules themselves
```

## What happens to the concept art

**It ships.** `art/src/title/hall_plate_src.jpeg` is the hall. That reverses TD-073, which forbade
using the PNG as the main menu after the author's "uncanny" verdict on an *earlier, different* image
that had UI baked into it — and it reverses TD-075's ruling that the title screen keep the board's
pixel language. Both reversals were explicit, and both are recorded in DECISION_LOG TD-076 with the
captures that decided them.

`art/src/collegium_hall_src.png` (the older piece) remains a composition reference only.

Author art still replaces any slot by name via `art/src/title/` + `tools/title_assets.py --import`.
For the **hall** the size is now free — it is a painting, and the fidelity path does not quantise it.
For the **props**, if they are ever drawn again, the sizes in the tables above still apply.
