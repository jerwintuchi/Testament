# Design — Title screen polish (TD-077)

> Satisfies R263–R268. Client render + generated art only.

## Fog (R263)

`gen_title_fog.py` emits three alpha-only sheets at **1440×720** — wider than the 1280 frame, so a
bank drifting ±80px never walks an edge into view:

| sheet | body | drift period | opacity |
|---|---|---|---|
| `fog_far.png` | thin, high, small-scale; carries the **warm depth haze** at the sanctuary (R266) | ~90s | lowest |
| `fog_mid.png` | the working bank across the nave | ~55s | middle |
| `fog_near.png` | heavy, low, large-scale — ground fog over the flags | ~32s | highest |

Each is fBm banked into **four alpha steps** (the overlay convention: banded, never smooth, because
a continuous falloff needs dithering and dithering is out). The centre of the frame is thinned, as
the other overlays are, because the menu is read there.

Motion is one looping `position:x` tween per bank plus a slower vertical breath, phases seeded apart.
**Only the fog moves relative to the fog** — the plate is never touched (P132).

**The strength ceiling is set by contrast, not by how much fog reads.** The first pass was ~4× too
strong: additive white over a hall this dark lifts the black floor across the whole frame, so it read
as a milky film over the picture. Alongside the cut, a `nave(fx)` weight keeps fog off the **near
piers** — the closest thing in the frame, and the worst of the wash.

**Edge safety is a test, not a comment.** `title_assets --selftest` parses `FOG_OVERHANG` and each
bank's drift out of the rig and fails if a drift exceeds the half-overhang. The failure it guards is
invisible in a still and appears only as a hard seam sliding across the hall some seconds after load
— and "raise the drift so the parallax reads more" is exactly the future edit that would cause it.

## The register (R264)

**Built in the `.import`, not in `fonts.gd`** (a correction to this entry): `Cinzel.ttf.import` sets
`antialiasing=0` and `subpixel_positioning=0`, so every load of the face is affected and no call site
can opt back in by accident — where a runtime property on `Fonts.cinzel()` would only cover the four
call sites that happen to go through it. It is a change with a project-wide blast radius either way,
so the Contract Board is captured before and after and judged on the evidence (V2).

## The laurel (R265)

`gen_menu_sigil.py` is re-authored: a branch **rooted at the bottom inner corner**, arcing up and
**outward**, with five leaves stepping along it — small at the tip, larger at the base — plus two
berries at the root. 34×30 art (17×15 logical), roughly twice the lozenge it replaces. The right-hand
copy is the file; the UI mirrors it for the left, so the pair opens outward like the crest's wreath.

**Leaves are hand-authored ASCII stamps, not a shape function** — a correction to this entry, forced
by five failed analytic passes (thorns → pods → one fused gilt mass → a fishbone once spaced apart).
That is TD-057's finding arriving again at 34×30: a shape function samples a curve, it cannot decide
which pixel carries the leaf. Two stamps (one standing off the branch, one lying along it) are placed
along an authored stem; the **rim is derived** by dilating every empty pixel that touches gold, since
at four pixels across only a dark edge separates two overlapping leaves — and a dilation cannot be
forgotten on one leaf and not another.

## The scene (R266)

- **Depth haze** — baked into `fog_far.png` rather than added as a layer: it is fog, and one fewer
  slot is one fewer thing to keep in sync.
- **Altar embers** — the existing `_embers` emitter, tuned up (count 7→16, life 4.2→5.6s): with the
  six vessel fires gone it is the only fire in frame and was throwing sparks into the brightest part
  of the picture, where they vanished. It also needed `damping`, because the altar sits directly below
  the menu column and a livelier undamped ember climbs straight through the last option.
- **Two more god-rays** — the same `light_shaft.png`, placed twice more with `flip_h` and different
  breathe periods. No new slot: the same sheet, three positions. The two additions are narrower and
  dimmer than the original, because a hall lit evenly from three directions has no direction at all.
- **Arrival** — `_show_title` fades and lifts the device and title over 0.6s, then staggers the
  options at 0.08s intervals. Guarded by `_reduced_motion` and by a "first show" flag, so returning
  to the title from a room does not replay it.
- **Hover polish** — the sigils tween their alpha over 0.12s; the selected option's font colour
  warms by a step.
- **Version** — a dim label bottom-right reading
  `ProjectSettings.get_setting("application/config/version")`.

## Files

**New:** `client/assets/ui/gen_title_fog.py`, `specs/title-polish/*`.
**Edited:** `gen_menu_sigil.py` (the laurel), `client/assets/fonts/Cinzel.ttf.import` (no AA) +
`client/scripts/ui/fonts.gd` (its stale AA-exception comment), `client/project.godot`
(`config/version`), `tools/title_assets.py` (the fog headroom assertion),
`client/scripts/ui/title_scene.gd` (fog layers, extra rays, altar embers),
`client/scripts/main.gd` (arrival, hover, version string), the asset manifest.
