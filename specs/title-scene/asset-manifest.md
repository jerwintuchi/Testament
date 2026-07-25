# Title Scene — Asset Manifest (TD-073, overhauled TD-075)

> **The Contract Board is the visual authority.** Where the concept art (Reference A) and the board
> (Reference B) disagree, the board wins — the author's ruling. Reference A gives composition,
> camera, scale, mood and lighting; the board gives pixel density, palette, shading, readability and
> craftsmanship. Nothing here is a matte painting.
>
> **Every asset is authored at the size it is displayed**, on the canonical 640×360 internal
> resolution, and drawn 1:1 through NEAREST. That is the whole register decision: art authored at
> 1920×1080 and squeezed into a 640×360 viewport through a LINEAR filter cannot match the board no
> matter how it is shaded. The pipeline decides the register, not the brushwork.
>
> **Every pixel is an Ash & Ember ramp entry.** Each generator ends in `A.assert_on_palette`, the
> same check the board's own art passes — which is what "matches the Contract Board" means in a form
> a machine can verify.
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
python3 gen_title_hall.py        # the hall
python3 gen_title_furniture.py   # banners, censer, chandelier, racks, braziers
python3 gen_title_overlays.py    # dust, smoke, the god ray
```

Then look at it: `"$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=4 --title-preview`.

---

## The hall

| File | Size | Alpha |
|---|---|---|
| `hall_plate.png` | 1280×720 | opaque |

One **bespoke** plate. The brief is explicit: *"Do not attempt to convert the cathedral into
reusable gameplay architecture."* The seven per-surface slices that used to layer over it are
**retired** — only decorative foreground elements stay separate, and they stay separate because they
**animate**, not because they might be reused.

`gen_title_hall.py` ray-casts the hall through the camera TD-072 measured (hfov 105°), pitched up
**21°** so the vault crowds the top and the sanctuary sits low, as Reference A composes it. The nave
closes at 58m so the altar reads as a place you could walk to. Then it renders in pixel discipline:
ramp indices only, light in **flat steps**, depth banded **per bay** so a change of tone lands on a
pier edge, masonry joints gated by distance so large stone stays quiet, and no per-pixel noise
anywhere.

## Cloth

| File | Size | Alpha | Notes |
|---|---|---|---|
| `banner_left.png` | 66×168 | yes | hangs on the left pier, crest in bone dye |
| `banner_right.png` | 66×162 | yes | its own weave and wear — not a mirror |
| `banner_center.png` | 26×62 | yes | small, deep, hung from the frame's top edge |

## Hanging props

| File | Size | Alpha | Notes |
|---|---|---|---|
| `censer.png` | 20×62 | yes | the chain runs to the **top edge**; hung twice |
| `chandelier.png` | 44×30 | yes | an iron corona on three chains |

## Fire vessels

| File | Size | Alpha | Notes |
|---|---|---|---|
| `candle_rack.png` | 96×55 | yes | tapers at varying heights; stands left |
| `candle_rack_b.png` | 88×51 | yes | its own rack; stands right, further off |
| `brazier.png` | 45×42 | yes | standing iron bowl, **no flame**; stands left |
| `brazier_b.png` | 42×39 | yes | a different bowl; stands right, further off |

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

`art/src/collegium_hall_src.png` stays a **composition reference only** — never shipped, never
displayed (TD-073, after it was tried as the background three times). The painted-register exception
R242 granted the title screen is **withdrawn** by TD-075: the title screen is pixel art, like the
board. Author-painted art can still replace any slot by name via `art/src/title/`, but it should be
authored at the size in the table above, or it will not sit beside the board.
