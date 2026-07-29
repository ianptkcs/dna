#!/usr/bin/env bash
# Pós-instalação Arch — rascunho idempotente.
# Rodar DEPOIS do Arch base instalado, com rede e usuário criado.
# Revise cada bloco antes; procure por "DECISÃO" e "REVISAR".
# NÃO roda nada destrutivo; só instala/habilita.
set -euo pipefail

echo ">>> Conferir multilib em /etc/pacman.conf (Steam/libs 32-bit)"
if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
  echo "!! Habilite [multilib] em /etc/pacman.conf e rode 'sudo pacman -Sy' antes de continuar."
  echo "   (descomente as 2 linhas [multilib] / Include = ...)"
  exit 1
fi

# ---------------------------------------------------------------------------
# 1. Pacotes oficiais (pacman)
# ---------------------------------------------------------------------------
PACMAN_PKGS=(
  # base dev
  base-devel git github-cli cmake ninja clang gcc pkgconf
  # shell / cli
  fish starship stow tmux eza fd ripgrep bat zoxide jq tree
  wl-clipboard curl unzip inotify-tools cosign i2c-tools ddcutil
  # terminal + yazi previews
  foot poppler ffmpeg 7zip
  # compositor
  niri waybar
  # GPU: iGPU Intel + dGPU NVIDIA (open) + prime
  mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver
  nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-prime
  linux-headers linux-lts linux-lts-headers
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
  # áudio (caso não venha por default)
  pipewire pipewire-pulse wireplumber
  # flatpak
  flatpak
  brightnessctl openrgb
)
echo ">>> pacman -S (${#PACMAN_PKGS[@]} pacotes)"
sudo pacman -S --needed "${PACMAN_PKGS[@]}"

# ---------------------------------------------------------------------------
# 2. AUR (precisa de um helper — instalar paru/yay antes)
# ---------------------------------------------------------------------------
if ! command -v paru >/dev/null && ! command -v yay >/dev/null; then
  echo "!! Instale um AUR helper (paru/yay) e rode os AUR_PKGS manualmente."
else
  AUR=$(command -v paru || command -v yay)
  AUR_PKGS=(
    brave-bin
    ngrok
    ibus-chewing ibus-table-others   # tabelas Cangjie
    gpu-screen-recorder              # ou manter como flatpak
    # DankLinux — REVISAR: pode ser mais fácil pelo instalador oficial do AvengeMedia
    # dms-shell quickshell matugen dgop
  )
  echo ">>> $AUR -S (AUR)"
  "$AUR" -S --needed "${AUR_PKGS[@]}"
fi

# ---------------------------------------------------------------------------
# 3. NVIDIA / Optimus  (ver 02-nvidia-optimus.md para o passo a passo completo)
# ---------------------------------------------------------------------------
echo ">>> NVIDIA: modprobe tweaks (replica o setup atual do Ubuntu)"
sudo tee /etc/modprobe.d/nvidia.conf >/dev/null <<'EOF'
options nvidia_drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
options nvidia NVreg_TemporaryFilePath=/var
EOF
echo "   REVISAR: adicionar 'MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)'"
echo "            em /etc/mkinitcpio.conf e rodar: sudo mkinitcpio -P"
echo "   DECISÃO: PRIME offload (padrão) vs dGPU-only (MUX no BIOS) — ver 02-*.md"

# ---------------------------------------------------------------------------
# 4. Flatpak (manter apps portáveis)
# ---------------------------------------------------------------------------
echo ">>> Flatpak + flathub + apps"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
  com.google.AndroidStudio com.spotify.Client com.stremio.Stremio \
  net.ankiweb.Anki org.telegram.desktop com.github.scrivanolabs.scrivano

# ---------------------------------------------------------------------------
# 5. Serviços
# ---------------------------------------------------------------------------
echo ">>> Habilitar serviços"
sudo systemctl enable bluetooth.service libvirtd.service postgresql.service redis.service
sudo systemctl enable nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service nvidia-powerd.service
# CUPS (impressão) se precisar: sudo pacman -S cups && sudo systemctl enable cups.service

# ---------------------------------------------------------------------------
# 6. Shell de login = fish
# ---------------------------------------------------------------------------
echo ">>> Definir fish como shell de login"
chsh -s /usr/bin/fish "$USER" || echo "   (rode 'chsh -s /usr/bin/fish' manualmente)"

# ---------------------------------------------------------------------------
# 7. Dotfiles
# ---------------------------------------------------------------------------
echo ">>> Dotfiles via stow"
echo "   cd ~/dotfiles && stow alacritty fish foot mise niri nvim starship tmux yazi DankMaterialShell"
echo "   (instale mise: https://mise.jdx.dev ; depois 'mise install' usa o config.toml)"

# ---------------------------------------------------------------------------
# 8. mise (runtimes)
# ---------------------------------------------------------------------------
echo ">>> mise: 'mise install' reconstrói bun/node/go/java/python/elixir/erlang/typst/yazi/etc"
echo "   (versões fixadas em raw/mise-config.toml)"

echo ">>> Pronto. Próximo: validar NVIDIA (nvidia-smi / prime-run glxinfo) e subir o niri."
