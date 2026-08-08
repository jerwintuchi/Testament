#!/usr/bin/env bash
# Start the Testament server for a playtest, and print the exact command the Godot
# client needs — including the current WSL IP, which is reassigned on every WSL restart
# and is the single most common reason "I can't create a lobby".
#
#   ./tools/playtest.sh          start the server, print the client command
#   ./tools/playtest.sh --client start the server AND launch the Godot client
#
# Runs in the FOREGROUND so Ctrl-C stops it. Nothing is left behind.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

# ── Find a LINUX pnpm+node, because the .bat cannot (TD-086) ─────────────────
# Two traps here, and the second only appeared after the first was fixed.
#
# 1. playtest.bat launches this through `wsl.exe -- bash tools/playtest.sh`: a NON-interactive,
#    NON-login shell. nvm installs itself in ~/.bashrc, which returns early for non-interactive
#    shells, so nvm's node/pnpm are not on PATH.
# 2. WSL appends the WINDOWS PATH to its own, so `command -v pnpm` then finds
#    /mnt/c/.../AppData/Roaming/npm/pnpm — a Windows shim that immediately fails with
#    "exec: node: not found" (status 127), because there is no Windows node in that shell.
#
# So "is pnpm on PATH" is the wrong question. The right one is "is there a pnpm AND a node that are
# both native to this Linux", which is what `_unusable` asks — anything under /mnt/ is a Windows
# binary reached through interop and cannot run the server.
_unusable() {
  _p="$(command -v "$1" 2>/dev/null)" || return 0
  case "$_p" in /mnt/*) return 0 ;; esac
  return 1
}

if _unusable pnpm || _unusable node; then
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" >/dev/null 2>&1
fi
if _unusable pnpm || _unusable node; then
  # PREPENDED, so nvm's pnpm wins over the Windows shim that interop put on PATH.
  _newest="$(ls -d "$HOME"/.nvm/versions/node/*/bin 2>/dev/null | sort -V | tail -1)"
  [ -n "$_newest" ] && PATH="$_newest:$PATH" && export PATH
fi
if _unusable pnpm || _unusable node; then
  echo
  echo "${red}No usable Linux pnpm/node found.${off}"
  echo "  pnpm: ${dim}$(command -v pnpm 2>/dev/null || echo 'not on PATH')${off}"
  echo "  node: ${dim}$(command -v node 2>/dev/null || echo 'not on PATH')${off}"
  echo
  echo "  Anything under /mnt/ is a WINDOWS binary reached through WSL interop and cannot"
  echo "  run the server. Looked in: \$NVM_DIR/nvm.sh and ~/.nvm/versions/node/*/bin"
  echo
  read -r -p "  Press Enter to close… " _
  exit 1
fi

PORT="${PORT:-3001}"
GODOT_WIN='D:\Godot_v4.7-stable_win64.exe'
GODOT_WSL='/mnt/d/Godot_v4.7-stable_win64.exe'
CLIENT_UNC='\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client'

bold=$'\e[1m'; dim=$'\e[2m'; gilt=$'\e[33m'; red=$'\e[31m'; off=$'\e[0m'

# The first address is the routable one for a Windows-side Godot. `hostname -I` can list
# several (Tailscale, IPv6); the WSL NAT address is the first.
WSL_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

# A busy port is the usual reason a playtest "just does nothing": this script exits, and when it was
# launched from playtest.bat the window closes with it, taking the explanation along. So say what is
# holding the port, offer to take it, and WAIT — an error nobody can read is not an error message.
if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
  echo
  echo "${red}Port ${PORT} is already in use.${off}"
  echo "${dim}Holder:${off}"
  ss -ltnp 2>/dev/null | grep ":${PORT} " | sed 's/^/    /'
  echo
  echo "  That is almost always a Testament server left running from an earlier session."
  read -r -p "  Stop it and start a fresh one? [Y/n] " reply
  if [ -z "$reply" ] || [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
    # By PID, from the port itself — never `pkill node`, which would take unrelated work with it.
    holder="$(ss -ltnp 2>/dev/null | grep ":${PORT} " | grep -o 'pid=[0-9]*' | head -1 | cut -d= -f2)"
    if [ -n "$holder" ]; then
      kill "$holder" 2>/dev/null
      sleep 2
    fi
    if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
      echo "  ${red}Still held. Stop it by hand, then re-run.${off}"
      read -r -p "  Press Enter to close… " _
      exit 1
    fi
    echo "  ${dim}released.${off}"
  else
    echo "  Leaving it alone. If it IS a Testament server, the client can just use it."
    read -r -p "  Press Enter to close… " _
    exit 1
  fi
fi

echo
echo "${bold}Testament — playtest server${off}"
echo "${dim}────────────────────────────────────────────────────────────${off}"
echo "  Launch the client from a Windows terminal with:"
echo
echo "    ${gilt}${GODOT_WIN} --path ${CLIENT_UNC} -- --server=ws://${WSL_IP}:${PORT}${off}"
echo
echo "  ${dim}The IP changes on every WSL restart — re-run this script to get the${off}"
echo "  ${dim}current one, or enable mirrored networking once and just use${off}"
echo "  ${dim}ws://localhost:${PORT} forever (see docs/technical/dev-environment.md §4).${off}"
echo "${dim}────────────────────────────────────────────────────────────${off}"
echo "  Ctrl-C stops the server. Expedition state is in-memory and ephemeral (I7)."
echo

if [ "${1:-}" = "--client" ]; then
  if [ -x "$GODOT_WSL" ]; then
    # Give the server a moment to bind before the client's first connect attempt.
    ( sleep 3; "$GODOT_WSL" --path "$CLIENT_UNC" -- --server="ws://${WSL_IP}:${PORT}" >/dev/null 2>&1 ) &
    echo "  ${dim}launching the client in ~3s…${off}"
    echo
  else
    echo "  ${red}Godot not found at ${GODOT_WSL} — start the client yourself.${off}"
    echo
  fi
fi

# Not `exec`: the trap below needs to survive the server exiting, so a crash on startup (a bad
# install, a TypeScript error) stays readable instead of vanishing with the window.
pnpm dev:server
status=$?
if [ "$status" -ne 0 ]; then
  echo
  echo "${red}The server exited with status ${status}.${off}"
  read -r -p "Press Enter to close… " _
fi
exit "$status"
