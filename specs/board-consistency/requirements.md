# Requirements — Contract Board Scene Consistency (crest, title, layout, style, banners, surfaces)

> Phase 5, visual polish. A consolidation pass over the Contract Board scene after the heraldry
> header (TD-049): make the whole scene read as **one consistent hand-painted raster register**,
> fix the header's knock-on layout problems, shorten the banners off the sconces, and bring the
> backing + wall back to *visible* (the TD-048 dungeon-dark grade over-sank them). Client render
> only (I1/I2). **Standing constraint (user, 2026-07-13): DON'T deviate the styling** — stay in
> the established hand-painted raster canon (TD-046); the **carved frame is the reference register**
> to match (the user likes it) — never a new look.
>
> **User rulings (2026-07-13), do not re-litigate:**
> - Notices **keep the organic scatter** (TD-040); the spacing problem is the **oversized crest
>   crowding** the top row, not the scatter itself — fixing the crest fixes the spacing.
> - Style consistency = fix **both sharpness AND detail**: crisp edges where art is soft/blurry
>   (the crest above all), and level **down** any prop that reads busier/higher-detail than the
>   frame register. The crest DESIGN stays (sword + laurel), just crisp + smaller.
> - Backing + wall = **visible but still moody**: lift so the wood grain + masonry read clearly,
>   but keep them darker than the parchments/frame (a partial walk-back of TD-048, not a full one).
>
> Numbering continues global: **R152+**, correctness **P86+**, tasks **T167+**. Trust boundary
> unchanged — no server/shared change, no wire, no game state, no board-behaviour change (R158).

---

## Crest

**R152** (client): the heraldic crest is **smaller** and **crisp** — the sword and laurel read as
defined forms, no downscale blur.
- AC: the crest no longer softens/mushes under LINEAR downscale — it is authored at (or very near)
  its display resolution and filtered so the sword blade, crossguard, laurel leaves, ring, and
  filigree read as **hard, defined shapes** (the user's "make the laurel and sword crisp").
- AC: it is **sized down** from the current 82×72 display so it stops crowding the top notice row;
  the emblem still crowns the nameplate (overlay, R-carryover from TD-049) but occupies less height.
- AC: the crest **design is unchanged** (upright sword + ring + laurel wreath + filigree; Origin-
  neutral) and stays in the hand-painted register (DON'T deviate) — only its scale + crispness change.

## Title

**R153** (client): the nameplate title is **"CONTRACT BOARD"** only.
- AC: the two-line "THE COLLEGIUM / CONTRACT BOARD" collapses to a **single gilt line** reading
  **"CONTRACT BOARD"** (the "THE COLLEGIUM" headline is dropped); centred, drop-shadowed, unlit ink
  on top (contrast floor preserved, ≥ 4.5:1).
- AC: the nameplate is **re-proportioned for one line** (shorter height), and the header recovers the
  vertical space the second line used (feeds R154).

## Layout

**R154** (client): the contract notices are **de-crowded** — the organic scatter is **kept**, but the
header no longer pushes/crowds the top row.
- AC: with the smaller crest (R152) + single-line nameplate (R153), the top-band reserve
  (`TOP_RESERVE_FRAC`) is brought back so notices sit clear of the header with even breathing room;
  no live notice is pushed under the plate, clipped, or crowded against its neighbour.
- AC: the seeded scatter (sizes, rotation, jitter — TD-040) is **unchanged in kind**; only the
  crest-induced crowding is removed. `keepout ... ok=true` still logs; every live notice shows its
  full headline/target/site lines.

## Style consistency

**R155** (client): the whole scene reads as **one consistent register** — crisp where it was soft,
detail levelled to the frame — without deviating the styling.
- AC (sharpness): elements that read soft/blurry from LINEAR downscaling or oversized source are made
  crisp/defined (the crest first; audit the crest, nameplate, seals, badges, tacks) so edges are sharp
  and consistent with the frame's crispness — within the hand-painted look (no flat-vector deviation).
- AC (detail): any prop that reads **busier / higher-detail than the frame register** (candidates:
  parchment foxing/stains, cobweb, votive, wax-seal sigils, tack clutter) is **levelled down** to a
  uniform detail density, so no element is a stylistic outlier. The **carved frame is the anchor** and
  is **left as-is** (the user likes it).
- AC: nothing here changes an element's *identity/behaviour* — it is a render/asset consistency pass
  (P89); the canonical register (TD-046 hand-painted raster) is preserved, not replaced.

## Banners

**R156** (client): the flanking crimson banners are **shorter** and **clear of the sconces**.
- AC: each banner hangs in the upper/mid gutter and **stops above the sconce** with a visible gap —
  it no longer overlaps or drapes onto the torch sconce/flame.
- AC: the banner keeps its mount (rod + nails + contact shadow) and its clean crimson render (T157);
  only its length + vertical placement change so cloth and fixture read as two separate things.

## Surfaces

**R157** (client): the plank **backing** and the stone **wall** are **visible** again — readable
material, kept moodier than the foreground.
- AC: the backing's wood grain and the wall's masonry **read clearly** at rest (lifted from the
  near-black TD-048 key), so the board reads as a wooden board on a stone wall — not a black void.
- AC: they stay **darker than the parchments + frame** (a low, moody key — "visible but still moody"),
  so the notices still pop and the torch pools still register; this is a **partial** walk-back of the
  TD-048 dungeon-dark grade (the surfaces only), documented as such.
- AC: torch/sconce lighting, the frame, and the parchment floor are unaffected (only the backing +
  wall base key rises).

## Cross-cutting

**R158** (containment, standing I1/I2): nothing here crosses the trust boundary — no server/shared
change, no new wire message, no game-state read/write. Board behaviour (select/deselect/deploy,
notice legibility) is untouched.

---

## Verification

No GDScript unit harness (client-spec convention). Each requirement is verified by the **DebugCapture**
pipeline (`--board-preview`) + a headless parse:
- **V1 (R152):** capture shows a smaller crest whose sword + laurel read as crisp defined forms (a
  zoom shows hard edges, no mush); it still crowns the nameplate.
- **V2 (R153):** capture shows a single gilt "CONTRACT BOARD" line, centred, ≥ 4.5:1; no "THE COLLEGIUM".
- **V3 (R154):** capture shows the scatter with even breathing room — no notice crowded/clipped/under
  the plate; `keepout ok=true` logs; every live notice shows all its lines.
- **V4 (R155):** capture (and zooms) show a consistent register — the previously-soft crest is crisp,
  and no prop reads as a detail outlier against the frame; the frame is unchanged.
- **V5 (R156):** capture shows each banner stopping above its sconce with a clear gap (no cloth-on-fixture
  overlap).
- **V6 (R157):** capture shows the backing's grain + the wall's masonry reading clearly, yet still
  darker than the parchments/frame; the notices still pop.
- **V7 (R158):** `git diff --name-only` shows client/docs/specs only; `--headless` parses clean; server +
  shared Vitest suites remain green (untouched).
