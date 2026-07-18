# Requirements — Contract Board blend pass (banner relight + header tone)

> Phase 5, Contract Board polish. A client render-only pass on the user's review of the TD-058
> board: the header + flanking banners **don't read as belonging in the scene** — the sign is too
> light, and the banners are too bright, mis-placed (spilling off the screen edge), smooth (not
> pixel art), and unlit (a flat baked sprite the torchlight never touches). Make both **recede into
> the dungeon-dark, torch-lit Collegium HQ** while staying legible.
>
> **User rulings (do not re-litigate):** keep the Collegium **emblem** on the banner but **subdued**
> (re-authored pixel-clean, dim, faint through the weave — never the brightest thing on screen); the
> banner's worn bottom is **heavily tattered** (ragged uneven hem, a few worn-through holes near the
> foot, loose dangling threads — not a clean geometric swallowtail); the banner sits **fully within
> the stone gutter** beside the board (narrower, completely visible, nothing clipped); the banner
> **interacts with the dynamic torch lighting** like the other surfaces; the header is **darker but
> not so much** — still readable.
>
> Client render + generated art only (I1/I2): NO server/shared change, no game logic. Numbering
> continues global: **R177+**, correctness **P102+**, tasks **T188+**. Logged **TD-059**. Verified by
> `--board-preview` captures (client-spec convention — no GDScript unit harness).

---

## The banner

**R177** (generator/client): the banner is re-authored as **crisp pixel art** with a **heavily
tattered** worn bottom.
- AC: the banner renders **NEAREST** (not LINEAR), authored at ~its on-screen size so it reads as
  crisp pixels — no non-integer downscale mush (TD-050 lesson; the internal resolution is a fixed
  640×360 so the display size is deterministic).
- AC: the clean geometric **swallowtail is replaced** by a heavily tattered silhouette — a ragged,
  uneven hem with a few **worn-through holes** near the foot and **loose dangling threads**, reading
  as centuries-old and threadbare.

**R178** (generator/client): the banner is **dimmed + desaturated** so it blends into the scene.
- AC: the banner recedes into the dungeon-dark key — **no board element is out-glowed by it**; it is
  no longer the brightest thing on screen.
- AC: the Collegium **emblem imprint is subdued** (dim, desaturated, faint through the weave) — it
  reads only as a printed device, never a bright white sigil.

**R179** (generator/client): the banner **interacts with the dynamic torch lighting**.
- AC: the banner is lit by the **same torch rig** as the surround via `board_surface.gdshader` + a
  generated **normal map** (`banner_v1_n.png`) — warm near the foot sconce, dark up top — instead of
  a flat baked-value sprite.
- AC: `--lights-off` makes the banner read flat/dim (its relief + warmth vanish), proving the shader
  lights it, not a baked hotspot (V-lever heritage). It reads the one `BoardDecor.torch_rig`; no
  second light source; `GUTTER_CX` stays the single banner/torch coupling (P95, TD-052).

**R180** (client): the banner hangs at the **outer gutter, clear of the board frame**.
- AC: the banner's **inner edge clears the carved board frame** with a visible gutter gap (it never
  overlaps the board), and the Collegium **emblem stays fully on-screen**. The banner is wider than
  the narrow stone gutter, so its **outer edge may spill off-screen** (viewport clips — author OK'd);
  the point is the emblem is aligned/visible and nothing intrudes on the board. Mirrored on both
  flanks (`GUTTER_CX` symmetric).

## The header

**R181** (generator/client): the header **wood is darkened** so the sign recedes into the scene,
while the **engraved gilt title stays readable**.
- AC: the header wood value is pulled down (blends toward the near-black board) — "darker but not so
  much"; the gilt **THE COLLEGIUM** / **Contract Board** stays clearly legible against it.

## Cross-cutting

**R182** (containment / register, standing I1/I2): client render + generated art only.
- AC: no `src/server` / `src/shared` change, no game logic; both header + banner render static asset
  data and emit nothing. Materials/light stay in register (aged wood / crimson cloth / bone / iron /
  bronze; candlelit; **no bloom, no gloss**). Dependency map regenerated for the changed asset edges.

---

## Verification (capture-based, client-spec convention)

No Vitest. Verified via `--board-preview` captures read back + the preview artifact:
- **V1 (R177):** a board capture shows the banner as crisp pixel art with a heavily tattered hem
  (ragged edge, worn holes, loose threads); it is NEAREST, not smooth.
- **V2 (R178):** the banner reads dim + desaturated, blended into the dark scene; the emblem is a
  faint printed device, not a bright sigil; nothing on the board is out-glowed by it.
- **V3 (R179):** a normal capture shows the banner warm at its foot (near the sconce) and dark up
  top; a `--lights-off` capture shows it flat/dim — the torch rig, not a baked hotspot, lights it.
- **V4 (R180):** a board capture shows both banners entirely on-screen inside their gutters, clear
  of the screen edge and the board frame, hanging straight — no clipping.
- **V5 (R181):** the header wood reads darker/receded while the gilt title stays clearly readable.
- **V6 (R182):** `git diff --name-only` touches only `client/ art/ specs/ docs/ CLAUDE.md`; server +
  shared Vitest suites remain green (untouched); `asset-map.md --check` passes.
