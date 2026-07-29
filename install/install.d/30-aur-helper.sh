#!/usr/bin/env bash
# Instala paru (AUR helper) se ainda não tiver um.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

if have_cmd paru || have_cmd yay; then
  log_ok "AUR helper já presente: $(have_cmd paru && echo paru || echo yay)"
  exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "  [dry-run] git clone AUR/paru-bin + makepkg -si"
  exit 0
fi

log_info "Nenhum AUR helper encontrado — buildando paru-bin"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
spin_run "clonar paru-bin" -- git clone --depth=1 https://aur.archlinux.org/paru-bin.git "$TMP/paru-bin"
(cd "$TMP/paru-bin" && makepkg -si --noconfirm)

have_cmd paru || { log_err "paru não ficou disponível após o build"; exit 1; }
