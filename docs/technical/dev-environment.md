# Dev Environment — WSL, Godot, and Seeing the Client

> **Status:** Canon (operational)
> **Why this file exists:** the Testament repo lives in WSL, but Godot is a
> Windows binary. Every session used to rediscover the seams between them. The
> facts below are verified, not assumed — re-verify before changing any of them.

---

## 1. There are two clones. Only one is real.

| Path | Status |
|------|--------|
| `/home/jerwin/projects/Testament` (WSL) | **Canonical.** All work happens here. |
| `D:\Projects\Testament` (Windows) | **Stale. Do not use.** Sits on `feat/protocol-contract`, many commits behind. |

The Windows clone predates the notice-board work entirely. If Godot is pointed at
it, you are looking at old code and wondering why your changes did nothing. This
has already cost real debugging time.

**Do not "fix" this by copying files between them.** Point Godot at the WSL clone
over its UNC path (§2). One clone, one truth.

## 2. Running Godot against the WSL clone

The Windows Godot binary executes directly from a WSL shell, and it *can* open a
WSL project — but only through the `wsl.localhost` share, with the exact distro
name.

```
Binary : /mnt/d/Godot_v4.7-stable_win64.exe        (v4.7.stable.official)
Distro : Ubuntu-24.04                              (NOT "Ubuntu" — verify: wsl.exe -l -q)
Project: \\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client
```

```bash
GODOT='/mnt/d/Godot_v4.7-stable_win64.exe'
CLIENT='\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client'

"$GODOT" --path "$CLIENT" --quit-after 900          # windowed run, hard time cap
"$GODOT" --headless --path "$CLIENT" --quit-after 5 # parse/import check only
```

**Gotchas, all learned the hard way:**

- A wrong distro name yields `Invalid project path specified` — which reads like
  "UNC is unsupported" but is not. Check the name first.
- `--headless` uses the dummy renderer. **It cannot capture pixels.** Use it to
  check that GDScript parses; never to look at anything.
- Godot rejects unknown *engine* arguments. Custom flags must follow a bare `--`,
  which puts them in `OS.get_cmdline_user_args()`.
- Always pass `--quit-after <frames>`. A windowed Godot with no exit condition
  will hang a tool call until it times out.

## 3. Seeing the client (screenshots)

`client/scripts/debug_capture.gd` is an autoload (`DebugCapture`) that writes the
rendered viewport to a PNG. Because `res://` resolves *through* the UNC mount back
into the WSL tree, the file lands in the repo where it can be read directly.

```bash
# Unattended: capture 3s after boot, then quit.
"$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=3

# Interactive: press F12 at any moment during a manual playtest.
```

Output goes to `client/.captures/<tag>-<ms>.png` (git-ignored), and the run logs
`[capture] <path> err=0 <w>x<h>`. A non-zero `err` means the write failed.

Capture is render-only: it reads the viewport and writes a file. It touches no
game state and sends no message, so it does not weaken the trust boundary (I1/I2).
Writing to `res://` only works in a debug run, so it is inert in an export build.

**Reaching a specific screen.** `--capture=<s>` fires on a timer from boot, so it
lands on the title screen unless something drives the client there first. To
capture a station popup you need the server running (§4), a room, and a Seeker
walked to the station — so F12 during a manual playtest is currently the practical
route for the Contract Board. A scripted preview harness that builds a popup from
fixture data would remove that constraint; it does not exist yet.

## 4. The server

The Godot client idles with "server offline" and no error when the server is down.
That is not a failure — it is the expected state, and it is easy to misread as a
client bug.

```bash
pnpm dev:server        # tsx watch, ws://localhost:3001
```

Start it **in the background** (`run_in_background: true`) before any live
round-trip, and leave it up for the whole playtest. It is a watch process: it never
returns, so a foreground call will block until it times out.

Run it **in WSL** — the WSL clone is the only real one (§1). But the Windows-side
client cannot then reach it at `localhost`; point it at the WSL IP (§6):

```bash
hostname -I                                    # in WSL → e.g. 172.22.125.177
"$GODOT" --path "$CLIENT" -- --server=ws://172.22.125.177:3001
```

`--server=` overrides `SERVER_URL` for one run. It moves *where* the client connects,
never what it trusts — the server stays authoritative over that socket (I1).

`tsx watch` reloads on `src/server/` + `src/shared/` edits, and a reload drops all
in-memory rooms (expedition state is ephemeral, I7), so an active playtest is bounced
to reconnect. Client-only work never disturbs it — but GDScript edits do not hot-reload
into a running client either, so relaunch the client to see them.

Suites, for reference:

```bash
pnpm --filter @testament/server test
pnpm --filter @testament/shared test
pnpm build                          # tsc across shared + server
```

## 5. Godot MCP

Registered in `~/.claude.json` for this project, as a **Windows** node process:

```json
{ "command": "/mnt/c/Program Files/nodejs/node.exe",
  "args": ["D:\\Tools\\godot-mcp\\build\\index.js"],
  "env": { "GODOT_PATH": "D:\\Godot_v4.7-stable_win64.exe" } }
```

- It exposes `run_project`, `get_debug_output`, `stop_project`, scene/node helpers.
- **It has no screenshot tool.** That gap is what `DebugCapture` (§3) closes.
- Being Windows-side, any project path handed to it must be the UNC path from §2,
  never `/home/jerwin/...`. *(Whether godot-mcp accepts a UNC path is untested —
  the direct `Bash` invocation in §2 is verified and is the recommended path.)*

Driving the binary from `Bash` is simpler, gives the exit code and full stdout, and
avoids the path translation entirely. Prefer it.

## 6. Networking

WSL sits behind a NAT: **WSL cannot reach a Windows `localhost` service.** A
Windows-side MCP server or tool must be launched by the Windows-side runtime, not
proxied through a WSL port.

**The reverse direction does not work on `localhost` either** (measured 2026-07-23;
this section previously claimed it did). WSL2 localhost-forwarding is *not* active on
this machine — there is no `C:\Users\jerwi\.wslconfig` — so a Windows process dialling
`127.0.0.1:3001` is refused while the server listens happily in WSL:

```
Windows → 127.0.0.1:3001        refused ("target machine actively refused it")
Windows → 172.22.125.177:3001   OK      (the WSL IP, from `hostname -I`)
```

Since the Godot client is a **Windows** process (§2) and the server runs in **WSL**
(§4), every live round-trip crosses this seam. Two ways across:

1. **Dial the WSL IP** — `-- --server=ws://<wsl-ip>:3001`. The server already binds
   `0.0.0.0`, so nothing changes server-side. The IP is **reassigned on every WSL
   restart**, which is why it is a runtime flag and never a hardcoded constant.
   Confirm a real connection with
   `ss -tn state established '( sport = :3001 )'` — a peer of `172.22.112.1` (the
   vEthernet gateway) is the Windows client.
2. **Mirrored networking** — create `C:\Users\jerwi\.wslconfig` with
   `[wsl2]` / `networkingMode=mirrored`, then `wsl --shutdown`. This makes `localhost`
   work in both directions permanently and retires the flag. It kills every running WSL
   session, so do it between work sessions, never mid-playtest.

## 7. Rendering, fullscreen, and the pixel grid

The client runs **GL Compatibility** (`renderer/rendering_method="gl_compatibility"`),
not Forward+/Vulkan. Confirm from the boot line:

```
OpenGL API 3.3.0 Core Profile Context - Compatibility - Using Device: AMD Radeon RX 6600
```

**Display config.** Base viewport **640×360** (TD-042), `window/size/mode=3`
(fullscreen at launch), `stretch/mode="canvas_items"`, `scale_mode="integer"`,
`aspect="keep"`. **F11** toggles fullscreen/windowed. The `PixelScale` autoload
(`client/scripts/pixel_scale.gd`) then picks the integer factor and sizes the
viewport to `window / factor`, so the screen fills with zero bars. **All UI metrics
are in logical 640×360 pixels.**

**Integer scaling is what keeps pixels crisp, and it is non-negotiable.** Godot
scales the canvas by a whole number only, so every source pixel becomes an exact
N×N block — no resampling, no shimmer. The cost is **letterboxing**: on a screen
that is not a whole multiple of 960×540, the largest fitting integer scale is used
and the remainder shows as black bars.

Switching `scale_mode` to `"fractional"` would fill any screen edge-to-edge, but at
a non-integer factor with Nearest filtering some source pixels become 2px wide and
others 3px. That is the classic pixel-art shimmer, and it violates the art canon in
`CLAUDE.md`. **Do not do it.** Everything below assumes integer scaling is fixed.

**The base viewport decides which monitors letterbox.** With integer scaling, a
screen only fills exactly when it is a whole multiple of the base. Measured:

| Screen | base 480×270 | base 640×360 | base 960×540 (current) |
|---|---|---|---|
| 1280×720 | ×2 bars | **×2 exact** | ×1 bars |
| 1920×1080 | **×4 exact** | **×3 exact** | **×2 exact** |
| 2560×1440 | ×5 bars | **×4 exact** | ×2 bars |
| 3840×2160 | **×8 exact** | **×6 exact** | **×4 exact** |
| 1366×768, 1600×900 | bars | bars | bars |

`960×540` is exact only on 1080p and 4K. **`640×360` is exact on 720p, 1080p, 1440p
and 4K** — the sizes most players have. 1440p is the common screen the current base
gets wrong.

**`aspect` handles a different problem: aspect *ratio*, not scale.** Verified by
measuring the logical viewport:

- `keep` pins the viewport to the base at every window size, so any mismatch bars.
- `expand` grows the viewport on an **aspect mismatch** (3440×1440 → logical
  860×360; portrait 1080×2400 → logical 960×2133), filling the screen.
- `expand` does **nothing** when the aspect matches but the scale is fractional.
  2560×1440 with a 960×540 base still measured `logical=960×540, bars`.

So filling every screen needs **both**: `640×360` base *and* `aspect="expand"`.
Measured with that pair: `bars=0×0` at 1280×720, 1920×1080, 2560×1440, and ultrawide
3440×1440.

**What actually ships (TD-042).** `PixelScale` chooses the integer factor, then sets
`content_scale_size = window / factor` (clamped to `MAX_LOGICAL` 1280×720). Measured
`bars=0×0` on every desktop and landscape-phone size tested:

```
1280x720  -> logical 640x360  x2      2400x1080 -> logical 800x360  x3
1920x1080 -> logical 640x360  x3      2340x1080 -> logical 780x360  x3
2560x1440 -> logical 640x360  x4      2778x1284 -> logical 926x428  x3
3840x2160 -> logical 640x360  x6      2556x1179 -> logical 852x393  x3
3440x1440 -> logical 860x360  x4
```

**The trade:** a wider screen sees more *area*, not bigger pixels. `MAX_LOGICAL` caps
it; the field camera may want its own clamp.

**Portrait is unverified.** Windows clamps an over-tall window, so a 1080×2400 test on
a 1080p desktop never resizes the real window and the reading is invalid. Needs a
device or emulator. Mobile also needs touch input, tap targets and orientation
handling — none of which exist yet (TD-042).

**UI metrics live in logical pixels.** The menu's fonts/margins/separations were
rescaled for 640×360. **The Contract Board's Pass-2 layout is not yet re-verified at
this base**, and its spec's `min_glyph` and contrast floor were written against
480×270.

**Capturing while fullscreen is on.** An unattended `--capture` forces a 960×540
window before it shoots, so the PNG is always the base viewport regardless of the
monitor. Pass `--capture-fullscreen` to shoot at screen size instead. F12 always
captures exactly what is on screen.

```bash
"$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=3                       # 960x540
"$GODOT" --path "$CLIENT" --quit-after 900 -- --capture=3 --capture-fullscreen  # 1920x1080
```

> Godot's own `--windowed` / `--resolution` engine flags **do not** work here:
> `window/size/mode=3` overrides them and you get a fullscreen capture anyway.
> Verified. `DebugCapture` sets the window mode from GDScript instead.

> **Open drift (unresolved).** `CLAUDE.md` and the notice-board `DESIGN.md` both
> specify a **480×270** internal resolution; `project.godot` uses **960×540**. UI
> and layout were authored against 960×540. Changing the base viewport would double
> the apparent size of every element. Flagged, not silently "fixed" — the docs and
> the project need reconciling by an explicit decision.
