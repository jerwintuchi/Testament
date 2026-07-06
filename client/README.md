# Testament — Godot Client

A Godot 4.x (GDScript) client speaking the **Testament protocol**: the full
Phase 4 loop — lobby → contract → requisition → field → probe → extract. Render
+ input only (the trust boundary): every screen transition is caused by a server
event; the client only ever sends *intentions*.

## Run it

1. **Start the server** (from the repo root):
   ```bash
   pnpm install
   pnpm dev:server        # listens on ws://localhost:3001
   ```
2. **Open this `client/` folder in Godot 4.x** (Project Manager → Import → pick
   `client/project.godot`).
3. Press **Play (F5)**. Create a room, share the code, and walk the expedition.
   Open a second instance for a party — distributed perception only shows its
   teeth with two or more Seekers.

## Files

| File | Role |
|------|------|
| `main.gd` | Screen state machine + code-built UI. All state is a render copy of server events. |
| `net.gd` | `WebSocketPeer` + JSON envelope transport. No game knowledge. |
| `protocol/protocol.gd` | **Generated** wire contract (messages, error codes, phases, channels, stimuli, gear catalog, scalars). Regenerate with `pnpm gen:protocol`; never edit by hand. |
| `catalog.gd` | Display helpers over `Protocol.GEAR` — no hand-copied data. |

## Protocol

Raw WebSocket, JSON envelope `{ "type": <string>, "payload": { ... } }` (TD-002).
Payload shapes are the shared types in `src/shared/src/lobbyMessages.ts` and
`fieldMessages.ts` — the single source of truth.

- **Out:** `CREATE_ROOM`, `JOIN_ROOM`, `TOGGLE_READY`, `ACCEPT_CONTRACT`,
  `LEAVE_ROOM`, `REQUISITION`, `KICK_PLAYER`, `DEPLOY`, `PROBE`, `EXTRACT`, `RECONNECT`
- **In:** `ROOM_CREATED`, `LOBBY_UPDATED`, `RECONNECT_TOKEN`, `ROOM_DEPLOYING`,
  `FIELD_STARTED`, `PROBE_RESULT`, `FIELD_TESTAMENT`, `ARCHIVE_UPDATED`,
  `STATE_RESYNC`, `LOBBY_ERROR`

The client never receives trait data — only *signs* — so there is nothing here
to cheat with (CLAUDE.md invariant 3).

## HTML5 / Web export

`Project → Export → Add… → Web`, then Export. Serve the exported files over HTTP
(Godot's "Remote Debug → Run in Browser" also works). The renderer is set to GL
Compatibility so the web export runs broadly.

## Manual playtest checklist (cited by specs/godot-client-catchup)

Two instances (A = host, B = joiner) unless noted.

1. **Menu → create.** A enters a name, creates a room; the lobby shows the room
   code and A marked ★ (you).
2. **Join.** B joins with the code; both instances list both players; B sees
   "(you)" against its own row (R71).
3. **Bad code.** B joining `ZZZZZZ` shows `ROOM_NOT_FOUND` in the status line
   and stays on the menu (R76).
4. **Ready → accept.** Both toggle ready; A (leader) accepts; both switch to the
   contract screen with the same target/site/tier/verb.
5. **Requisition.** A picks Witness Prism + Censer of Embers; B picks Ashen
   Lens. Both see both bags update. Picking a 5th item is refused client-side.
6. **Re-requisition replaces.** B requisitions a different single item; B's bag
   shows only the new item (replace-not-merge).
7. **Deploy.** A deploys; both enter the field. A sees "you perceive: REACTION",
   B sees "you perceive: RESIDUE" — each reads different signs (distributed
   perception).
8. **Probe read.** A presents FLAME: A's log shows a `[REACTION]` sign; B's log
   shows "you cannot read it"; exposure ticks up on both.
9. **Probe without the kit.** B presents COLD (no Phial): `MISSING_GEAR` in the
   status line; B stays in the field (R76).
10. **Extract.** A extracts; both see the Field Testament and the Archive entry.
11. **Return.** "Return to the Collegium" lands on the menu; a new room can be
	created (the old room is gone server-side).
12. **Reconnect (field).** Close B mid-field and relaunch — press Reconnect on
	the connection-lost screen; B is restored to the field with its signs and
	perceived channels intact (`STATE_RESYNC`).
13. **Server down.** Stop the server: both instances show the connection-lost
	screen; Abandon returns to the menu once the server is back.
14. **Ghost marker.** Close B while in the lobby: A's list marks B
	"(disconnected)" within a moment; B's ready state is preserved for resume.
15. **Kick.** As leader, A sees a Kick button on B's disconnected row; kicking
	removes the seat, a new player can join it, and B's later Resume fails
	(its client forgets the dead token instead of retrying).
