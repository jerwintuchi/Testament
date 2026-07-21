# Design — main.gd decomposition (TD-067)

> Satisfies R214–R220. Client render only; behavior-preserving. Verified by captures.

---

## The method (every tranche)

1. Create the new module under `client/scripts/ui/` (builders) or `client/scripts/board/` (features),
   `extends RefCounted` for a namespace or `extends Control`/its own scene for a node-owner.
2. **Move the function bodies verbatim** — same logic, constants, and comments — turning instance
   `func _foo(...)` into `static func foo(...)` where it touched no instance state, or a method on
   the new node where it did.
3. Add `const Name = preload("res://scripts/ui/name.gd")` to `main.gd` (and to any other consumer).
4. Replace call sites mechanically (`_foo(` → `Name.foo(`); delete the moved funcs from `main.gd`.
5. Regenerate the dependency map (new `preload` edges); capture-verify; commit.

## Tranche 1 modules

### `ui/fonts.gd` — `Fonts`
`static func cinzel(weight: int) -> FontVariation` — the verbatim `_cinzel` body (loads
`res://assets/fonts/Cinzel.ttf`, builds a `FontVariation` on the `wght` axis). Consumers:
`main._engraved_line` and `RiteBanner` → `Fonts.cinzel(...)`.

### `ui/popup_theme.gd` — `PopupTheme`
`static func build() -> Theme` — the verbatim `_build_popup_theme` body (panel 9-slice + fallback,
button/label/checkbox colours, the TD-062 scene-tint tooltip), with `_btn_box` moved in as a private
`static func _btn_box(...)`. Consumer: `main` (the popup theme assignment) → `PopupTheme.build()`.

### `ui/rite_banner.gd` — `RiteBanner`
Owns a **transient CanvasLayer overlay**, so it follows the `BoardDecor.add_torches(host, …)` idiom
(a static builder that creates nodes on a passed-in host and self-frees) rather than a persistent
scene — the banner is fire-and-forget, code-built, no editor layout:

```gdscript
const Fonts = preload("res://scripts/ui/fonts.gd")
static func show(host: Node, title: String, sub: String, reduced_motion: bool) -> void
static func _band_gradient() -> GradientTexture2D
```

Verbatim from `_show_rite_banner`/`_rite_band_gradient`, with `add_child`→`host.add_child`,
`get_tree()`→`host.get_tree()`, `_cinzel`→`Fonts.cinzel`, `_reduced_motion`→the `reduced_motion`
param, `_rite_band_gradient()`→`_band_gradient()`. The `await host.get_tree().process_frame` is fine
in a static coroutine (unchanged fire-and-forget from `_on_message`). Consumers: the two
`CONTRACT_SELECTION`/preview call sites → `RiteBanner.show(self, title, sub, _reduced_motion)`
(and `.call_deferred(self, …)` for the `--rite-banner` hook).

## Correctness Properties

- **P122 (refactor ≠ redesign, R215):** the moved code is behaviorally identical — same nodes, same
  tweens, same values; a capture before/after is pixel-identical, and no game state or wire message
  changes (I1/I2). The only diff is the file a function lives in and its call spelling.

## Files touched (tranche 1)

New: `client/scripts/ui/fonts.gd`, `client/scripts/ui/popup_theme.gd`,
`client/scripts/ui/rite_banner.gd`, `specs/main-decompose/*`. Edited: `client/scripts/main.gd`
(preloads + call sites; delete the six moved funcs), `docs/technical/asset-map.md` (regenerated),
`docs/DECISION_LOG.md` (TD-067), `CLAUDE.md` (active spec). No `src/**` change.
