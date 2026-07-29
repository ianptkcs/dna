#!/usr/bin/env bash
# Pacotes AUR — precisa do helper instalado em 30-aur-helper.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

AUR="$(have_cmd paru && command -v paru || command -v yay || true)"
if [ -z "$AUR" ]; then
  log_err "Nenhum AUR helper disponível — rode o step 30-aur-helper antes."
  exit 1
fi

AUR_PKGS=(
  brave-bin
  ngrok
  ibus-chewing ibus-table-others   # tabelas Cangjie
  gpu-screen-recorder              # ou manter como flatpak
)

log_info "$AUR -S --needed (${#AUR_PKGS[@]} pacotes AUR)"
run "instalar pacotes AUR" -- "$AUR" -S --needed --noconfirm "${AUR_PKGS[@]}"

log_warn "DankMaterialShell/dms/quickshell/matugen/dgop NÃO estão nessa lista de propósito:"
log_warn "o ecossistema DankLinux (AvengeMedia) tem instalador próprio — rode-o manualmente"
log_warn "depois deste step e confira se ele já cobre quickshell/matugen/dgop antes de"
log_warn "instalar via AUR pra evitar duplicidade/conflito de versão."
