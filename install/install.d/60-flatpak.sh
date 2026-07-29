#!/usr/bin/env bash
# Flatpak — apps que ficam melhor portáveis entre distros (ver 01-packages.md).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

spin_run "flatpak remote-add flathub" -- \
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

FLATPAK_APPS=(
  com.google.AndroidStudio
  com.spotify.Client
  com.stremio.Stremio
  net.ankiweb.Anki
  org.telegram.desktop
  com.github.scrivanolabs.scrivano
)

log_info "flatpak install (${#FLATPAK_APPS[@]} apps)"
run "instalar apps flatpak" -- flatpak install -y --noninteractive flathub "${FLATPAK_APPS[@]}"
