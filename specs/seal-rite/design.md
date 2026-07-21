# Design — The seal rite (TD-062)

> Satisfies R196–R201. Client render only. Verified by captures + author playtest.

---

## R196 — the missing line_spacing

Godot Labels insert the theme constant `line_spacing` (default 3px) between wrapped lines;
`Font.get_multiline_string_size` does not. With a 2-line target + 2-line site the TD-061 fit was
~6px short — exactly the clipped "Ossuary". Fix in `_fit_writ`:

```gdscript
var ls := float(ThemeDB.get_default_theme().get_constant("line_spacing", "Label"))  # 3.0
var th := font.get_multiline_string_size(target, ..., fs[0]).y
th += ls * maxf(0.0, roundf(th / font.get_height(fs[0])) - 1.0)   # + spacing per extra line
# (same for the site line) … need += 2.0 safety
```

The fixture's `siteName`s adopt the longest authored server names ("The Gall Road Ossuary",
"Hollowmere Crossing", "The Broken Cloister", "The Collapsed Chancel") so V1 exercises the real
failure case in preview.

## R197 — the round seal

`wax_seal.gd _draw()`: the texture rect becomes a centred square —
`var s := minf(size.x, size.y); Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))` — for both
states; the faint ring keeps radius `s * 0.5 - 1.5` about the same centre. The control can take
any rect (HBox stretch included); the wax stays a circle.

## R198 — the oath + the tooltip

`_seal_block` captions (leader): unsealed *"I, %s, take up the charge against %s. Let it be
witnessed."* (`_display_name_plain(_self_id)`, fallback `"Seeker"`; target from intel); sealed
*"It is witnessed. %s is ours to answer."*. Non-leader: *"Awaiting the leader's seal."* / the same
witnessed line. Instructions move to `stamp.tooltip_text` (leader only). The popup theme gains
`TooltipPanel`/`TooltipLabel` styling (near-black warm panel, brass border, parchment-tone text)
so the tooltip sits in the scene.

## R199 — scroll preservation

Two members: `_reader_open_cid: String`, `_reader_scroll_mem: int`. `_show_notice_reader`:
- same `cid` as `_reader_open_cid` (a snapshot rebuild, e.g. stamp/lift) → restore
  `_reader_scroll_mem` instead of pinning 0;
- new cid (fresh open) → pin to top and set `_reader_open_cid`.
The memory tracks live scrolling via the scroll's `VScrollBar.value_changed` (after the settle
frames, so the pin itself doesn't clobber a restore); `_select_board_card({})` clears both.
`_reset_reader_scroll` generalises to `(rdr, target)` — the `--reader-foot` debug pin rides the
same path.

## R200 — the press + wax flash

State transition detection: `_seal_prev: Dictionary` (cid → sealed?) updated in `_seal_block`;
when the rebuilt block's `selected` differs from the remembered value (and reduced-motion is off),
`_animate_seal(seal, stamp, sealed)` runs deferred (one frame, so layout has sized the nodes;
pivot = centre):

- **Stamp:** seal starts `scale 1.8, alpha 0.4` → tween to `1.0 / 1.0` (0.12s, EASE_IN QUAD);
  impact: squash to `(1.18, 0.85)` then back (0.10s, EASE_OUT BACK); a flash `TextureRect`
  (`BoardGeo.backlight_gradient` + `additive_material`, IGNORE) blooms behind the seal
  (`scale 0.6→1.8, alpha 0.9→0` over 0.28s) then frees itself; the parchment sheet (the reader
  Control) nudges +2px and back (0.06s) — the desk thump.
- **Lift:** the new faint seal briefly renders firm (`set_faint(false)`, full alpha) and peels:
  `scale 1.0→1.5`, alpha→0.15 (0.16s, EASE_IN), then snaps to the true faint state
  (`set_faint(true)`, scale 1.0, the block's resting alpha).
- Reduced-motion (`_reduced_motion`): no tweens, no flash — the block renders its end state (the
  seal itself is already correct from the rebuild).

Tweens run on nodes the rebuild just created; if a second rebuild lands mid-tween the nodes are
freed and the tweens die with them (safe). The animation reads no input and emits nothing (P115).

## Correctness Properties

- **P113 (fit is exact, R196):** the fit height uses the same font metrics AND the same
  line-spacing the Label renders with; no writ text clips at any authored name length.
- **P114 (scroll continuity, R199):** a rebuild for the same open notice restores the prior scroll
  offset exactly; pin-to-top fires only on a cid change; close clears the memory.
- **P115 (ceremony is decorative, R200):** the animation changes no state, emits no message, and
  reduced-motion yields the identical end state — stamp authority remains the server's (P66).

## Files touched

Edited: `client/scripts/main.gd` (fit spacing; fixture long sites; oath captions + tooltip;
scroll memory; seal animation), `client/scripts/ui/wax_seal.gd` (square draw rect),
`docs/DECISION_LOG.md` (TD-062), `CLAUDE.md` (active spec), `docs/technical/asset-map.md` (check).
New: `specs/seal-rite/*`. No new assets (the flash reuses `BoardGeo.backlight_gradient`).
