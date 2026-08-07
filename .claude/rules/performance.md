# Performance — Canon

> **Author's standing instruction (2026-07-26):** optimization for performance is **always a must**
> when implementing game UI, game mechanics, and the game loop. It is a requirement of the work, not
> a pass that happens afterwards.

This is not a general plea to write fast code. It is a rule about **when** performance is decided:
before the thing is built, in the spec, as a number — because the expensive choices in this project
are architectural (how much of the screen is redrawn, how many particles exist, what runs per frame),
and by the time a capture looks right those choices are already baked in.

## P0 — Every spec that adds render or loop work states a budget

`requirements.md` names the budget as an acceptance criterion, in the same breath as the look:

- **particles** — total live count across the screen, and per emitter
- **full-frame layers** — how many additive/overlay sheets cover the whole viewport (this is
  overdraw, and it is the most common way this project has made a screen expensive)
- **per-frame work** — what runs in `_process`/`_draw` at all, and why a looping tween could not
- **rebuild scope** — what a state change re-instantiates
- **node count** — for anything built per-item (writs, roster rows, gear slots)

A spec that adds an effect without a budget is incomplete, the same way one without a named test is.

## P1 — Mobile is a target platform, and effects are paid at device resolution

Testament targets **mobile** (TD-042). The client renders `canvas_items` at the **device**
resolution, not the 640×360 logical viewport (see `docs/technical/dev-environment.md` and the render
register): a full-frame additive overlay on a 1080p phone is a 1080p-worth of blend, not a
640×360-worth. Anything per-pixel — overlays, fog sheets, glow pools, shaders — must be counted at
the real target, never at the logical size.

Correspondingly: **the title screen and menus are the first thing that runs.** They set the user's
impression of whether the game is heavy, and they run on the coldest cache. They get the same
scrutiny as the field, not less.

## P2 — The patterns this project already proved (prefer these; they are not optional folklore)

- **Update the smallest subtree that reflects a change.** Never rebuild a screen for a local change.
  Sealing a contract refreshes only the reader (TD-065); taking a writ down swaps only the overlay
  (TD-068). Both were shipped as fixes for exactly this, twice.
- **Memoize deterministic generators.** Textures and geometry that are a pure function of their
  inputs are built once (TD-064, `BoardGeo`).
- **Keep work out of `_process`.** Looping tweens animate without a frame callback and free with
  their node. The title rig animates every layer this way and has no `_process` at all.
- **Avoid per-frame allocation** in rebuild paths and callbacks.

## P3 — Verify the budget, do not assert it

The same discipline as every other claim in this repo: measure it. A frame-time or count check in a
capture run, a printed emitter total, an assertion in a `--selftest` — whatever makes the number
falsifiable. "It felt fine in the capture" is not verification, and a still frame cannot show a
particle cost at all.

## P4 — If the design cannot meet the budget, say so before building it

Offer the cheaper form and let the author choose. Shipping the expensive version with a note about
its cost is the failure mode this rule exists to prevent: by then it is in the tree, it looks right,
and removing it reads as a regression.

---

**Golden rule:** decide the cost when you decide the design. See also `code-structure.md` **S6**
(performance is architecture, not file layout), which this expands.
