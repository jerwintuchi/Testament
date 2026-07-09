# Playtest — The Notice Board (MCP-driven)

> Verifies the client requirements R120–R124, R126 (no GDScript unit harness —
> prior client-spec convention) and exercises the TD-041 server flow (R127/R128)
> end-to-end. Server/shared correctness is already covered by Vitest; this pass
> confirms the render + intent wiring against a live server.
>
> **Harness.** Node server up first (`pnpm dev:server`, `ws://localhost:3001`), then
> drive the Godot client with the `mcp__godot__*` tools: `run_project` on `client/`,
> read `get_debug_output` for the load-bearing `_log(...)` lines, `stop_project`
> when done. Items 4–5 need **two clients** (leader + one non-leader) — a second
> `run_project` instance, or a second machine — to observe the seal notification and
> the leader/non-leader split. MCP cannot screenshot, so where a check is visual it
> is called out as **(eyeball)** and confirmed by the human at the client window;
> everything else is confirmed from `get_debug_output`.
>
> A run is green only when every item's expected log line appears and no GDScript
> error is present in `get_debug_output`.

---

## Setup

1. `pnpm dev:server` (leave running).
2. `run_project` on `client/`; create a room, note the room code. This client is the
   **leader**.
3. In-Collegium, walk the leader onto the **Contract Board** station (proximity
   affordance shows) and press **E** to open the board popup.

Expected: no errors in `get_debug_output`; the board popup opens over the wood skin
with the carved **"PETITIONS BEFORE THE COLLEGIUM"** placard (eyeball).

## Item 1 — Procedural notice prose (T133 / R120, R121, P68)

For each of the four live contracts opened in turn (Item 3 covers the open action),
read the notice text and confirm:

- The **headline** matches the verb by the sacred register:
  `INVESTIGATE → INQUIRY`, `ELIMINATE → SANCTION`, `CAPTURE → CONTAINMENT ORDER`,
  `BANISH → RITE OF BANISHMENT` (eyeball).
- The **charge** names the contract's **site** and is **verb-faithful** — the
  imperative synonym still conveys the contract's `primaryVerb` (a CAPTURE contract
  never reads as "destroy") (eyeball).
- The **signature** renders `"— <name>, <role> of <place>"`, and for an anonymous
  petitioner the form `"— an unnamed <role> of <place>"` (at least one of the four
  should be anonymous given the seed; if not, note the seed) (eyeball).
- Reopening the **same** notice yields **identical** text (determinism) — close and
  reopen one notice, confirm no word changes (eyeball).

## Item 2 — Notice-board scatter (T134 / R122, P65)

With the board open:

- Expected log: **`board live=4 flavor=N`** (N = `FLAVOR_NOTICES.size()`).
- The board shows **4 live** notices plus the flavor scraps, scattered across the
  whole board at human angles and varied sizes, overlapping at corners — not a tidy
  row (eyeball). Live sizes vary but **do not** encode tier (equal-weight).
- Every live notice's **headline/target is readable** at rest (not occluded); a
  hovered live notice raises to front (eyeball).
- A click on a **flavor** scrap does nothing (inert, `MOUSE_FILTER_IGNORE`); only
  live notices respond (eyeball + no `select …` log fires on a flavor click).

## Item 3 — Take a notice down to read (T135 / R123)

- Click a **live** notice.
- Expected log: **`select <contractId>`** (the id of the clicked notice).
- The notice enlarges to centre over a dimmed board with the full reader: headline,
  target, `Site — <site>`, asserted-Origin seal + gloss, threat pips, preamble +
  charge, the Archive line (`"No prior testament on record."` — honest empty state,
  **no** signs/reward/gear), and the signature (eyeball).
- A **Return to the board** / dismiss returns to the wall; **nothing is sent** on
  open or close (no snapshot change, no new `select` log on close) — pure view state.

## Item 4 — The leader's reversible seal (T136 / R124, R127, P66, P69)

Leader, with a notice open in the reader:

- Click the **faint** wax seal ("Stamp your seal to take up this charge").
  - Expected log: **`seal <contractId> accepted=true`**.
  - The seal reads **firm**; a top-centre toast shows **"<leader> sealed the charge:
    <target>"** (eyeball). The phase does **not** change (still in the Collegium /
    WAITING) — no deploy screen swap.
- Click the now-**firm** seal.
  - Expected log: **`seal <contractId> accepted=false`**.
  - The seal returns to faint; toast **"<leader> lifted the seal on <target>"**
    (eyeball). Selection is reversible; still WAITING.

## Item 5 — Two clients: notification split + staged deploy (T136 / R124, R128, P66, P70)

Bring up a **second** client, join the same room as a **non-leader**. Both open the
same live notice in the reader.

- **Non-leader has no stamp affordance**: the seal is read-only, captioned "Awaiting
  the leader's seal." (eyeball). Only the leader's client shows the pointing-hand
  stamp.
- Leader stamps the seal → **both** clients show the firm seal and the
  **"… sealed the charge …"** toast (eyeball on the non-leader); leader logs
  `seal <id> accepted=true`. This is the seal state travelling on the snapshot, not a
  local guess.
- **Staged deploy (R128):**
  1. With the seal **lifted** (nothing selected), the leader walks to the **Deploy
     Gate** and presses deploy → a **`NO_CONTRACT_SELECTED`** error surfaces in the
     status line, no screen change (eyeball; the raced-error path, P66).
  2. Leader re-seals a contract, returns to the Deploy Gate, deploys → the room
     advances to **DEPLOYING** (deploy screen; `ROOM_DEPLOYING`), **no** field start
     yet (eyeball).
  3. Leader deploys again from the Deploy Gate in DEPLOYING → **FIELD_STARTED**; both
     clients enter the field (eyeball; the field render replaces the Collegium).
- A non-leader pressing deploy at any stage surfaces `NOT_LEADER` (eyeball).

## Item 6 — Trait containment & component reuse (R125, R126, P64)

- Cross-check the wire: nothing the client renders is trait-derived — no Known Signs,
  reward, recommended gear, or expedition notes appear on any notice (eyeball;
  backed by the Vitest serialized-shape assertions for `ContractIntel`/board).
- The **WaxSeal** (Origin) and **ThreatPips** render on both the board notices and
  the reader — reused, render-only components (eyeball). No game logic lives in the
  notice/seal scenes: they render snapshot/intel data and emit only the existing
  intents (`SELECT_CONTRACT` / `DESELECT_CONTRACT` / `DEPLOY`).

---

## Sign-off

- [ ] All six items green; expected log lines present in `get_debug_output`.
- [ ] No GDScript error in any `get_debug_output`.
- [ ] `stop_project` clean on every client.
- [ ] `pnpm --filter @testament/server test`, `pnpm --filter @testament/shared test`,
      and `pnpm build` (tsc) all pass.

---

# Pass-2 reskin — legibility & accessibility ACs

> These verify the visual reskin (`ux-designs/ux-Testament-2026-07-09/` DESIGN.md +
> EXPERIENCE.md), not the behavior above. They run only once the pixel-art reskin is
> implemented (Batch 1 structure → Batch 2 detail). Several are **measured**, not
> eyeball: sample the rendered framebuffer, don't judge by feel. Run on a **worst-case
> seed** — one that drops a live notice in the darkest, least torch-lit region.

## L1 — Live-notice contrast floor (measured)

- On each of the 4 live notices, sample the rendered framebuffer luminance at a
  **headline glyph** and a **body glyph** against its immediate parchment backing
  (post-gloom, post-overlay — the *composited* pixels, not the source token).
- Assert **≥ 4.5:1** for both, on the worst-case seed. Headline must be **ink `#2A2115`**,
  never wax. Confirm each live notice's paper is **≥ `#CBB583` (base)** tone, never shadow.

## L2 — Threat pips readable regardless of fill/gloom (measured/eyeball)

- Every pip (filled and empty) carries a **1px `#12100C` outline**; the empty pip is an
  outlined-hollow diamond. Assert the pip **edge** ≥ 3:1 against its parchment on the
  worst-case seed; the filled/empty count is resolvable by a viewer under gloom.

## L3 — Per-notice backlight, not torch-dependent (eyeball, worst-case seed)

- On the seed that drops a live notice farthest from both wall torches, that notice is
  **still at its floor tone** — its own local backlight carries it. Legibility does not
  depend on a wall torch reaching the scatter spot.

## L4 — Keep-out / occlusion (unit + eyeball)

- Layout unit test: on N seeds, **no live notice's headline/target/seal/pip keep-out
  rectangle intersects** any other notice, cobweb, votive, or foxing quad.
- Eyeball: at rest (no hover) every live headline/target is fully readable; decay props
  sit only in corners empty of live anchors.

## L5 — Reduced motion keeps the light (measured)

- Toggle the reduced-motion setting: flame + pulse stop, but the **glow holds at peak
  brightness**. Re-run L1's luminance sample — it **still passes** (the static board is
  at least as legible as the animated one).

## L6 — Focus / keyboard + hit-target (eyeball)

- **Tab** cycles the live notices in reading order with a visible **gold focus ring**
  (≥3:1); **Enter/Space** opens the focused notice's reader; the seal button is
  focus-reachable and activatable. Every live notice offers **≥ 44×44** un-occluded
  clickable area even at its smallest/tilted scatter variant.

## L7 — Pixel & palette integrity (eyeball + tooling)

- No off-`Ash & Ember`-ramp pixel on the board (sample a rendered frame; blended/lit
  output is quantized to the locked palette). Tilt uses pre-baked rotated variants;
  hover-lift and reader-enlarge are integer-scaled (no sub-pixel shimmer). VFX (glow,
  cobweb) are grayscale sources tinted to the flame ramp — no colored screen-blend.

## L8 — Empty board (eyeball)

- With the live pool empty, the board renders placard + bare plank + torches + the
  "The wall stands empty…" scrap — never a blank popup.

## Pass-2 sign-off

- [ ] L1–L8 pass on the worst-case seed; measured items sampled, not eyeballed.
- [ ] `ux-designs/…/validation-report.md` findings all addressed or consciously deferred.
