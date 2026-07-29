#!/usr/bin/env bash
# Pacotes oficiais (pacman) — ver 01-packages.md pro mapeamento apt→arch completo.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

PACMAN_PKGS=(
  # base dev
  base-devel git github-cli cmake ninja clang gcc pkgconf
  # shell / cli
  fish starship stow tmux eza fd ripgrep bat zoxide jq tree gum
  wl-clipboard curl unzip inotify-tools cosign i2c-tools ddcutil
  # terminal + yazi previews
  foot poppler ffmpeg 7zip
  # compositor
  niri waybar
  # GPU: iGPU Intel + dGPU NVIDIA (open) + prime
  mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver
  nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-prime
  linux linux-headers linux-lts linux-lts-headers
  # gaming
  steam lutris wine winetricks gamemode lib32-gamemode mangohud lib32-mangohud
  # dev services / vm
  postgresql redis qemu-full libvirt virt-manager dnsmasq bridge-utils edk2-ovmf iptables-nft
  android-tools
  # input method (mandarim)
  ibus ibus-table ibus-libpinyin
  # dicionários
  hunspell hunspell-pt_br hunspell-en_us words
  # fontes
  ttf-jetbrains-mono-nerd noto-fonts noto-fonts-cjk noto-fonts-emoji
  # browsers / apps nativos
  firefox neovim discord
  # áudio
  pipewire pipewire-pulse wireplumber
  # flatpak (infra)
  flatpak
  brightnessctl openrgb
)

log_info "pacman -S --needed (${#PACMAN_PKGS[@]} pacotes)"
run "instalar pacotes oficiais" -- sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
