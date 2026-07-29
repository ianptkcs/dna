#!/usr/bin/env bash
# Define fish como shell de login.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

FISH_BIN="$(command -v fish || true)"
if [ -z "$FISH_BIN" ]; then
  log_err "fish não encontrado — rode 20-pacman-packages antes."
  exit 1
fi

if [ "${SHELL:-}" = "$FISH_BIN" ] || getent passwd "$USER" | cut -d: -f7 | grep -qx "$FISH_BIN"; then
  log_ok "Shell de login já é $FISH_BIN"
  exit 0
fi

grep -qxF "$FISH_BIN" /etc/shells || ensure_line /etc/shells "$FISH_BIN"

spin_run "chsh -s $FISH_BIN" -- chsh -s "$FISH_BIN" "$USER"
