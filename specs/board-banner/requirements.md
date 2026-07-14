# Requirements — Board Banner, Crest & Placard pass (imprinted standards)

> Phase 5, Contract Board scene polish. A client render-only pass on the user's review of the
> heraldry/emblem work: the crest is too large, the flanking banners read as ragged greybox cloth
> with ugly mount hardware (not proper banners), and the "CONTRACT BOARD" placard wants re-cutting.
> The user also wants the Collegium emblem **imprinted** on the banners like a printed device (a
> tonal color change, not the gilt object), and the banners **widened + centered in the wall
> gutters** (overflow past the screen edge is fine).
>
> **User rulings (do not re-litigate):** two matching banners (one centered in each gutter, the logo
> imprinted on BOTH); the placard re-cut as **refined carved wood**; the imprint is a **pale
> bone-dye** print (high-contrast on crimson, reads as printed, not metallic).
>
> Client render-only (I1/I2): NO server/shared change, no game logic, pure presentation over the
> existing snapshot. Numbering continues global: **R165+**, correctness **P95+**, tasks **T178+**.
> Logged **TD-052**. Verified by `--board-preview` captures (client-spec convention — no GDScript
> unit harness; measured/eyeballed frames, mirrors board-heraldry/board-consistency).

---

## Crest sizing

**R165** (client): the Collegium crest crowning the board is **reduced** so it no longer dominates
the header.
- AC: `board_decor.board_crest()` displays the emblem smaller than the current 51×84 while keeping
  aspect 0.60 (no stretch) and clear of the frame/viewport top (base still pinned at the nameplate).
- AC: the smaller crest still reads as the blade-and-laurel mark (legible at the reduced size),
  LINEAR-filtered, over its offset shadow.

## Banner cloth + mount

**R166** (client/generator): the flanking banners are re-authored as **proper hanging banners**, not
ragged greybox cloth.
- AC: `gen_banner.py` emits a banner with a **clean woven crimson cloth** (baked vertical fold value +
  soft AO), a **defined banner bottom** (a swallowtail / pointed hem — not a torn deckle edge), and a
  **clean top hem/pole** baked into the cloth.
- AC: the ugly separate **iron mount rod + nail-head `Panel`s** ("wooden stand/lock") are **retired**
  from `add_torches`; the banner hangs from its baked hem (optionally a single slim dark pole),
  reading as a fixed standard, not a floating scrap.

## Logo imprint

**R167** (generator): the **Collegium emblem is imprinted** on the banner as a **pale bone-dye**
printed device.
- AC: `gen_banner.py` reads `collegium_logo.png`, recolors it to a **bone/off-white monochrome**
  (using the emblem's alpha as the device mask + its luminance for internal shading), and composites
  it into the upper cloth at reduced opacity so the crimson weave reads through — a **printed** look
  (color-shifted from the source gold), **baked into `banner_v1.png`** so it lights and drapes with
  the cloth (P97).
- AC: the imprint sits within the cloth (not over the swallowtail notch), centered horizontally,
  legible as the blade-and-laurel at banner scale.

## Placement + lighting coherence

**R168** (client): two matching banners, **centered in each wall gutter** and **wider**.
- AC: each banner's centre is the **gutter midpoint** (between the board frame edge and the screen
  edge), computed from `BoardGeo.inner_size` (not a hard-coded 0.06/0.94), widened so it fills the
  gutter; **overflow past the screen edge is allowed** (clipped by the viewport).
- AC: the **torch light rig stays coherent** — the sconce/flame/glow and the `board_surface.gdshader`
  torch uniforms (`torch_rig`) remain aligned under/with the banner; moving the banner never desyncs
  the wall lighting (P95). Any shared gutter-centre constant is read by BOTH `torch_rig` and
  `add_torches`.

## Placard

**R169** (client/generator): the "CONTRACT BOARD" placard is re-cut as **refined carved wood**.
- AC: the nameplate reads as a cleanly carved wooden sign — deeper routing, a crisper bevel, and
  better gilt on the letters — replacing the current greybox-ish plate, while keeping the single
  "CONTRACT BOARD" gilt line and its placement (the crest still crowns it).

## Cross-cutting

**R170** (containment, standing I1/I2): every change is **client render / generated art only**.
- AC: no file under `src/server` or `src/shared` changes; no game logic added; the banners/placard/
  crest render existing snapshot/asset data and emit nothing (P96). The dependency map is regenerated
  for the new/changed asset edges.

---

## Verification (capture-based, client-spec convention)

No Vitest (client render). Verified via `--board-preview` captures read back + the preview artifact:
- **V1 (R165):** a board capture shows the crest visibly smaller, still legible, not crowding the top row.
- **V2 (R166):** a capture shows proper banners — clean cloth, swallowtail hem, no floating rod/nails.
- **V3 (R167):** the bone-dye emblem reads as printed on each banner (color-shifted, crimson through).
- **V4 (R168):** both banners are centered in their gutters and wider (overflow off-screen ok); a
  before/after lighting capture (torch lit) shows the wall light still aligned under the banners.
- **V5 (R169):** a capture shows the refined carved-wood placard with the gilt "CONTRACT BOARD" line.
- **V6 (R170):** `git diff --name-only` touches only `client/`, `art/`, `specs/`, `docs/`, `CLAUDE.md`;
  server + shared Vitest suites remain green (untouched); `asset-map.md --check` passes.
