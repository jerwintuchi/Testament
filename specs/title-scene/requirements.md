# Requirements — The title screen: a matte-painted Collegium, animated in layers (TD-073)

> **Revised on the author's art direction.** Two approaches are now withdrawn: TD-072's single
> procedurally-generated plate (hit a structural ceiling), and this spec's own first draft, which
> proposed *reconstructing the architecture* from modular generated assets. The author's ruling:
>
> > "The goal is not to procedurally recreate the concept art. The goal is to faithfully reproduce
> > its atmosphere and composition while keeping the implementation maintainable inside Godot… Do
> > not spend development time reconstructing every stone block or arch. Reserve modular
> > architecture for procedural expedition environments where replayability matters."
>
> So: **the concept art IS the background.** Engineering effort goes into animation, lighting and
> atmosphere — not into painting architecture through code.
>
> The screen must communicate: *an ancient institution, centuries of sacrifice, the last bastion
> against the Incarnates, sacred and enduring.* Motion is almost imperceptible — Elden Ring / Dark
> Souls / Blasphemous, never an animated wallpaper.
>
> **R241+**, **P127+**, **T255+**. Logged **TD-073**.

---

## R241 — The matte is the architecture, and it never moves
- AC: the concept art is imported as a **static** environment plate. No camera move, no zoom, no
  pan, and no procedural reconstruction of any architectural element.
- AC: it is **source art** under `art/src/` (the author's own, generated via ChatGPT, rights held),
  processed into the client asset by a generator — the same pipeline `collegium_logo_src.png` uses.
- AC: cropped to 16:9 **without distorting** the composition; the crop keeps the vault above and the
  runner below, since both carry the "ancient institution" read.

## R242 — The register exception is explicit, not accidental
- AC: this asset is a **painted environment matte**, recorded as a deliberate exception to TD-055,
  which rejected hi-res painted art **for UI surfaces** (9-slices, frames, devices that must stay
  crisp pixel art). Measured with TD-055's own test: the concept art's colour boundaries fall at
  chance for every scale factor, so it is genuinely painted at native resolution, not pixel art
  upscaled.
- AC: written into the DECISION_LOG so a later session does not "fix" the matte by quantizing it to
  the Ash & Ember ramps — that would destroy the atmosphere this spec exists to preserve.
- AC: **board and HUD surfaces keep the pixel register unchanged** (P127).

## R243 — Independent animated layers over the matte

| Layer | Contents | Motion |
|---|---|---|
| 0 Matte | the concept art | **none** |
| 1 Cloth | Collegium banners, torn cloth, ribbons | slow sway only |
| 2 Hanging props | censers, lanterns, chandeliers, chains | slight pendulum, randomized phase |
| 3 Fire | candles, braziers, wall torches | independent flicker; the environment takes it |
| 4 Atmosphere | dust, ash, incense smoke, embers | very slow, large, low-opacity particles |
| 5 Light | volumetric rays, subtle bloom, warm glow, vignette | "breathes" slowly; no dramatic swings |
| 6 UI | emblem, title, options | fully independent of environmental animation |

- AC: each layer is its own node subtree and can be disabled without touching the others.
- AC: fire lights are **`Light2D`**, so the matte is genuinely lit by them (bible rule 2, TD-043).
- AC: flicker phases are **seeded per light and non-synchronised** — synchronised flicker is the
  tell that reads as fake.

## R244 — Motion is almost imperceptible
- AC: no element's motion is noticeable in isolation; the screen reads as *still, with life in it*.
- AC: **F9 reduced-motion freezes every layer** to a fully-lit static frame that loses no
  information — the existing lever keeps working (heritage L5).

## R245 — It remains a backdrop
- AC: emblem, title and options stay legible; the composition's centre stays quiet enough for them.
- AC: holds at the integer scales `PixelScale` produces, with no visible layer seam.

## R246 — Parallax is conditional
- AC: parallax ships **only if it does not reveal the matte is a flat plate** (author ruling). Since
  Layer 0 is one painted image, any camera-linked offset against animated foreground layers risks
  exactly that. Default is **no parallax**.

## R247 (containment): client render + generated art only
- AC: no `src/**` change, no wire change; asset-map regenerated; suites green; no board asset.

---

## Deferred, and honestly flagged

**Ambient audio** (looping wind / candles / fire / chains / cathedral room tone) is specified by the
author but **cannot be delivered yet**. The project has no audio assets, no audio source pipeline,
and no sanctioned audio tool — the toolchain is a CLOSED LIST (Godot, Aseprite, Python generators)
and `docs/art/audio-direction.md` is a placeholder. Adding one needs explicit approval per CLAUDE.md.
Tracked as **T262**, blocked on that decision; everything else here ships without it.

## Correctness Properties

- **P128 (the matte is inert):** Layer 0 never moves, scales or animates. Every impression of life
  comes from the layers above it — which is what keeps the flat plate from being revealed.
- **P127 (register propagates one way, standing):** the matte is an environment exception; no board
  or HUD asset changes, and the pixel register there is untouched.

## Verification

- **V1 (R241/R242):** `--title-preview` shows the matte, correctly cropped, undistorted.
- **V2 (R243):** each layer toggles independently; fire lights are `Light2D` and `--lights-off`
  visibly removes their contribution.
- **V3 (R244):** captures with motion and with F9; the frozen frame is fully lit and loses nothing.
- **V4 (R245):** title/emblem/options legible; re-captured at a second integer scale.
- **V5 (R247):** diff scoped `client/ specs/ docs/`; asset-map `--selftest` + `--check`; suites green.
