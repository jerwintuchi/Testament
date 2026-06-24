# Veins — UI & Controls Style Guide

> **Status:** Mixed (canon controls/UI + implemented HUD inventory + draft visual direction)
> **Sources:** GLOSSARY.md (Auto-Aim, Aim Override, PWA); DECISION_LOG.md (control-scheme entry; implemented UI components); SYSTEM DESIGN DOC.md §8.1; GPT_CHAT_HISTORY.txt (draft, "membranes not boxes")
> **See also:** [art-bible.md](art-bible.md) · [systems/combat.md](systems/combat.md) · [doctrines.md](doctrines.md)

## Controls

### Desktop
WASD movement + mouse aim. Desktop is **always manual aim**.

### Mobile — virtual joystick
Left half of screen = move; right half = aim. Zero-vector on release.

### Auto-Aim (mobile default)
When the aim joystick is at rest, the game **auto-aims at the nearest alive enemy** (Euclidean distance, no cone bias — enemies approach from any direction, so a directional cone would create unfair dead zones). Fires toward that target without player input.

- Rejected alternatives: lowest-HP and highest-threat targeting (counterintuitive in chaotic fights).
- Auto-aim range constant: `AUTO_AIM_RANGE = 250`.

### Aim Override
Activated when the player actively moves the aim joystick (non-zero input). Disables auto-aim for that moment and fires in the joystick direction; returns to auto-aim when the stick is released. Desktop mouse-aim auto-reverts to auto after 500ms idle. Critical for targeting specific minions during boss fights.

## No explicit doctrine UI

Players never see doctrine scores ("Sanctum +12") — only effects. Threshold crossings surface only as flavor-text toasts (the doctrine itself is omitted from the payload). See [doctrines.md](doctrines.md) and [systems/doctrine-tracking.md](systems/doctrine-tracking.md).

## PWA / fullscreen

Mobile fullscreen via **PWA** (`manifest.json`, `"display": "standalone"` + iOS meta tags). Users add the game to their home screen; subsequent launches open with no browser chrome — indistinguishable from native. Chosen over the Fullscreen API (blocked on iOS Safari for non-video elements). See [technical/stack-and-deployment.md](technical/stack-and-deployment.md).

## Implemented HUD / UI inventory (current build)

- **HUD:** Bleed Clock bar (with stage), floor + phase readout, local player HP, teammate HP rows, live enemy count.
- **BoardPanel:** SVG hex grid, owner colors, synergy highlight (CSS `synergy-pulse`), loot-phase visibility, relic detail card (base + synergy effect text), placement-error feedback.
- **RelicTray:** lists unplaced relics from the current loot pool; selection/deselect; "all relics placed" ready hint.
- **DescendPanel:** loot-phase only; "Descend ↓" / "Extract ↑"; buttons disable on click to prevent double-tap.
- **PhaseToast:** transient COMBAT / FLOOR CLEARED / FLOOR N announcements (2.5s auto-dismiss).
- **Lobby/WaitingRoom:** create/join, room code with Copy button, player list, host-only Start Run.
- **PostRunScreen:** WIPED/EXTRACTED outcome, final floor, enemies-killed stat, return-to-lobby.
- **Linked Fates revive UI:** downed-teammate panel, two-step revive (select source relic → select downed player's empty slot).

---

## Draft / Exploratory — UI visual direction

> Mined from `GPT_CHAT_HISTORY.txt`. Aspirational; the implemented UI above is the current reality.

> Don't make boxes. Make **membranes**.

- **Health bars:** not flat fills — a fill with a *flowing blood animation* beneath it.
- **Synergy links:** vein lines drawn between portraits, pulsing when activated.
