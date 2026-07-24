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

PORT="${PORT:-3001}"
GODOT_WIN='D:\Godot_v4.7-stable_win64.exe'
GODOT_WSL='/mnt/d/Godot_v4.7-stable_win64.exe'
CLIENT_UNC='\\wsl.localhost\Ubuntu-24.04\home\jerwin\projects\Testament\client'

bold=$'\e[1m'; dim=$'\e[2m'; gilt=$'\e[33m'; red=$'\e[31m'; off=$'\e[0m'

# The first address is the routable one for a Windows-side Godot. `hostname -I` can list
# several (Tailscale, IPv6); the WSL NAT address is the first.
WSL_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

if ss -ltn 2>/dev/null | grep -q ":${PORT} "; then
  echo "${red}Port ${PORT} is already in use.${off}"
  echo "Another server is probably already running — reuse it, or stop it first:"
  echo "    ${dim}ss -ltnp | grep ${PORT}${off}"
  exit 1
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

exec pnpm dev:server
