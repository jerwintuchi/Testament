# Playtest — Station UI v2

> MCP-driven, against a live `pnpm dev:server` (the named test for the client
> tasks; no GDScript unit harness). `run_project` on `client/`, read
> `get_debug_output` after each step, `stop_project` at the end. Two clients
> (leader + joiner) exercise the leader-only gates. The client `print()`s the
> load-bearing events so `get_debug_output` can confirm them.

## Items

1. **Contract Board renders (R111).** Walk to the Contract Board, press E.
   `board cards=N` logged; the popup shows N parchment cards, each with a name,
   site, threat pips, and verb, and **no Incarnate image** anywhere. Threat pips
   match the card's tier.

2. **Select → Deploying (R110/R111).** As leader with the party ready, select a
   card (`select <id>`) and Accept → `ROOM_DEPLOYING`, phase → DEPLOYING, the
   *selected* target becomes the active contract. As non-leader, or before ready,
   the Accept is refused and `NOT_LEADER`/`PARTY_NOT_READY` shows in the status line.

3. **Quartermaster grid + detail (R114).** At the Quartermaster, the popup shows
   the gear grid; selecting an item fills the detail panel with its name, kind,
   description, and "Reads: <channel>" (or "Presents: <stimulus>"). The Stipend
   balance and `used/BAG_SLOTS` are shown.

4. **Requisition + Stipend (R113/R114).** Requisition a within-budget loadout:
   `requisition cost=C balance=B` logged, the bag and balance update. Attempt an
   over-budget loadout: `INSUFFICIENT_STIPEND` surfaces, nothing changes.

5. **Deploy Gate summary (R115).** At the Deploy Gate, the popup shows the selected
   contract summary (target/site/threat pips/verb) and the party roster with each
   Seeker's bag — **no class/role labels**. Deploy (leader) → `FIELD_STARTED`
   (`deploy target=<name>` logged); a raced `NOT_AT_DEPLOY_GATE` still surfaces.

6. **Shared theme + reuse (R117).** All three popups render in the gothic
   panel/theme; the threat-pip widget appears on both the board and the deploy
   summary; no GDScript errors across the run; `stop_project` leaves no orphan.
