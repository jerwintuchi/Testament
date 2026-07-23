# Requirements — The nave re-authored as High Gothic (TD-072)

> **Revised before implementation, on the author's clarification.** The reference (Chartres, nave
> looking east) supplies the **angle and the structure only**. The *look* — palette, light, mood — is
> governed by the design bible, not by the photograph. A previous draft of this spec derived a
> "limestone" palette from the image and proposed pushing it into the Contract Board's wall; that
> inverted the hierarchy twice over and is withdrawn (see design.md § Withdrawn).
>
> `docs/art.md` is explicit about the direction of travel: *"the Notice Board is the canonical worked
> example … the board's register **propagates to** field tiles, Seeker sprites, HUD, and menus."* So
> the nave **inherits the board's register**. It does not set one.
>
> What is still true, and what this spec is for: the TD-071 nave is **structurally the wrong
> building**. Round arches, a flat dark vault, plain rectangular piers, an eye-level camera — that is
> Romanesque: heavy, low, enclosing. The reference is **High Gothic**: pointed, ribbed, shafted, and
> above all *tall*. The awe lives in the bones, and the bones are what we are taking.
>
> Client render + generated art only. **R235+**, **P127+**, **T249+**. Logged **TD-072**.

---

## What the awe is made of (criteria, not vibes)

Read off the reference's *geometry*, deliberately not its colour:

1. **Verticality.** The vault owns the top ~half of the frame; the eye is pulled up before it is
   pulled in. Shafts run unbroken from floor to springing — the reference's piers are *bundles of
   thin colonnettes*, which is what makes stone look drawn upward rather than stacked.
2. **A low camera looking up.** The horizon sits low and the vault is seen from beneath, so its ribs
   splay overhead. An eye-level shot of the same building is merely a corridor.
3. **Storeys.** Arcade → triforium → clerestory: three tiers of diminishing openings give the wall a
   measurable height. A blank wall gives it none.
4. **Ribs that converge.** A quadripartite vault's ribs meet at a boss per bay, drawing a receding
   chain of Xs along the ceiling — the strongest depth cue in the image.
5. **A far end that reads as far.** Depth is carried by *contrast against the near*, not by size alone.

## Phase A — The register is the board's

**R235**: the nave is authored in the **existing** Ash & Ember vocabulary, per the bible.
- AC: it uses the shipped ramps (`stone`, `black`, `flame`, `gold`, `wax`, `wood`, `parchment`,
  `ink`) — the same ones the Contract Board is built from. **No new palette is introduced**, and in
  particular no palette is transcribed from the reference photograph.
- AC: stained glass is rendered from ramps already in hand — cool `stone` for the blues, `wax`
  (oxblood) for the rubies, `gold`/`flame` for the ambers — so the glass reads as jewelled without
  importing a foreign colour scheme.
- AC: `assert_on_palette` passes with no ramp additions.

**R236**: the nave is **dramatically torch-lit**, not daylit (`docs/art.md`, TD-043).
- AC: fire is the **key**: braziers/candles in the space, warm and local, with falloff. The room is
  *lit, not evenly bright*; deep shadow is the default state and light is the exception.
- AC: a **cold** counter-light (a pale shaft through a high lancet) exists only as the warm/cool
  counterpoint TD-043 calls for — it is the accent, not the source. The current plate has this
  inverted: pale daylight is doing all the work and there is no fire at all.
- AC: **one light direction per scene** — every cast shadow traces to a source that is in the image
  (bible rule 4: a shadow with no source is a bug).
- AC: warm/cool separation is *visible*: warm light lands on cool-shadowed stone, which is the same
  contrast that makes the board's torch halos read.

## Phase B — The bones

**R237**: the nave is High Gothic, not Romanesque.
- AC: **pointed** arches throughout (arcade, triforium, clerestory, apse lancets) — the current
  semicircular heads are the single most Romanesque thing in the image and must go.
- AC: a **ribbed quadripartite vault**: diagonal ribs crossing at a boss per bay, transverse ribs at
  each bay division, lighter infill webs between, and a ridge rib tying the bosses into a chain.
- AC: **compound piers** — a core with engaged colonnettes, so each pier reads as a bundle of
  vertical shafts, with capitals at the springing.
- AC: **three storeys** — main arcade, a shallow triforium band, a clerestory of pointed windows —
  each tier's openings smaller than the one below.

**R238**: the camera creates the height.
- AC: the vanishing point sits **low** (≈0.62–0.70 of frame height) so the viewer looks **up** the
  vault, and the vault occupies roughly the upper half of the frame.
- AC: bays recede with perspective spacing toward a far end that reads as distant by contrast.
- AC: the image stays **empty** — no character, creature, weapon, effect, or furniture. (The
  reference's chairs are deliberately not reproduced: clutter, and they date the space.)
- AC: the plate stays a **backdrop** — the gilt title and its options remain legible over it, so the
  centre of the frame stays comparatively quiet.

## Cross-cutting

**R239**: the Contract Board is **not** touched.
- AC: no change to `stone_tile`, the board's shader tuning, or any board asset. The propagation runs
  board → menu (`docs/art.md`); because the nave adopts the board's existing ramps, the two spaces
  already share a palette and no re-tone is needed (P127).
- AC: a board capture after this spec is unchanged.

**R240** (containment): client render + generated art only.
- AC: no `src/**` change; no wire change; dependency map regenerated; server + shared suites green.

---

## Correctness Properties

- **P127 (the register propagates one way):** the menu inherits the board's palette and lighting
  language; nothing in the menu's making alters a board asset. Any future proposal to re-tone the
  board is its own spec with its own measured legibility check — not a side effect of a backdrop.

## Verification

- **V1 (R235/R236):** the nave passes `assert_on_palette` with **no ramp additions**; a capture shows
  fire as the key light with a cold accent, deep shadow dominant, and one consistent light direction.
- **V2 (R237/R238):** a `--title-preview` capture shows pointed arches, a ribbed vault with bosses,
  compound piers, three storeys, and a low camera with the vault owning the upper half; re-captured
  at 1920×1080 for the integer-scale centring.
- **V3 (R238):** the gilt title and all four options stay legible over the plate.
- **V4 (R239):** a board capture is unchanged; `git diff` touches no board asset.
- **V5 (R240):** diff scoped `client/ specs/ docs/`; asset-map `--selftest` + `--check`; suites green.
