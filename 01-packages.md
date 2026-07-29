# Pacotes: Ubuntu → Arch

Mapeamento dos **113 pacotes apt manuais** + snaps + flatpaks pro Arch.
Listas brutas exatas em `raw/`. Lendo coluna `Fonte`:
`pacman` = repos oficiais (core/extra/multilib), `AUR` = precisa de helper (yay/paru),
`flatpak` = manter como flatpak (cross-distro), `mise` = já gerenciado pelo mise, `—` = não migrar.

> **Habilitar `multilib`** em `/etc/pacman.conf` (necessário pra Steam e libs 32-bit).

## Compositor / desktop (DankLinux)

| Atual | Arch | Fonte |
|---|---|---|
| niri | `niri` | pacman (extra) |
| DankMaterialShell (dms) | `dms-shell` (+ `quickshell`, `matugen`, `dgop`) | AUR |
| dgop, danksearch, dank-todo | pacote DankLinux correspondente | AUR |
| waybar | `waybar` | pacman |
| ubuntu-desktop-minimal, ubuntu-*, snap-store, etc. | — (meta do Ubuntu) | — |

> O ecossistema DankLinux tem instalador próprio (script do AvengeMedia) que pode
> ser mais simples que montar pacote-a-pacote no Arch. Conferir na hora.

## GPU / drivers (ver detalhes em `02-nvidia-optimus.md`)

| Atual | Arch | Fonte |
|---|---|---|
| nvidia-driver-590-open / nvidia-dkms | `nvidia-open-dkms` `nvidia-utils` `lib32-nvidia-utils` | pacman |
| (fallback de kernel) | `linux-lts` `linux-lts-headers` `linux-headers` | pacman |
| mesa (Intel iGPU) | `mesa` `lib32-mesa` `vulkan-intel` `lib32-vulkan-intel` `intel-media-driver` | pacman |
| nvidia-prime (`prime-run`) | `nvidia-prime` | pacman |
| openrgb | `openrgb` | pacman/AUR |
| brightnessctl | `brightnessctl` | pacman |

## Gaming

| Atual | Arch | Fonte |
|---|---|---|
| steam (snap) | `steam` | pacman (multilib) |
| lutris | `lutris` `wine` `winetricks` | pacman |
| (recomendado adicionar) | `gamemode` `lib32-gamemode` `mangohud` `lib32-mangohud` | pacman |
| gpu-screen-recorder (flatpak) | `gpu-screen-recorder` | AUR (ou manter flatpak) |
| gaming-graphics-core24 (snap) | — (era só p/ snap mesa) | — |

## Dev / build / runtimes

| Atual | Arch | Fonte |
|---|---|---|
| build-essential | `base-devel` | pacman |
| gcc clang cmake ninja make pkg-config | `gcc clang cmake ninja make pkgconf` | pacman |
| git gh | `git github-cli` | pacman |
| postgresql | `postgresql` | pacman |
| redis-server | `redis` (ou `valkey`) | pacman |
| erlang elixir | manter via **mise** (já no `config.toml`) | mise |
| qemu-system-x86 libvirt-* bridge-utils | `qemu-full libvirt virt-manager dnsmasq bridge-utils edk2-ovmf iptables-nft` | pacman |
| adb (android-tools) | `android-tools` | pacman |
| ngrok | `ngrok` | AUR |
| cosign | `cosign` | pacman/AUR |
| i2c-tools | `i2c-tools` `ddcutil` | pacman |
| inotify-tools | `inotify-tools` | pacman |
| bun, node, go, java, python, typst, resvg, prettier, fzf, yazi | manter via **mise** | mise |

## CLI / shell / utilitários

| Atual | Arch | Fonte |
|---|---|---|
| fish | `fish` | pacman |
| starship | `starship` | pacman |
| stow | `stow` | pacman |
| tmux | `tmux` | pacman |
| eza | `eza` | pacman |
| fd-find | `fd` | pacman |
| ripgrep | `ripgrep` | pacman |
| bat | `bat` | pacman |
| zoxide | `zoxide` | pacman |
| jq | `jq` | pacman |
| tree | `tree` | pacman |
| wl-clipboard | `wl-clipboard` | pacman |
| ffmpeg | `ffmpeg` | pacman |
| curl unzip | `curl unzip` | pacman |
| **yazi previews** | `poppler` `ffmpeg` `7zip` `jq` (todos já cobertos) | pacman |
| **terminal (foot)** | `foot` | pacman |

## Input method (mandarim / Cangjie) — não esquecer

| Atual | Arch | Fonte |
|---|---|---|
| ibus | `ibus` | pacman |
| ibus-table-cangjie* | `ibus-table` + `ibus-table-others` | pacman/AUR |
| libchewing / ibus-chewing | `ibus-chewing` | AUR |
| libpinyin | `ibus-libpinyin` | pacman |

## Dicionários / corretor

| Atual | Arch | Fonte |
|---|---|---|
| hunspell-pt-br, hunspell-en-* | `hunspell hunspell-pt_br hunspell-en_us` | pacman |
| wbrazilian wbritish wportuguese | `words` (+ dicts hunspell) | pacman |

## Fontes

| Atual | Arch | Fonte |
|---|---|---|
| JetBrainsMono Nerd Font | `ttf-jetbrains-mono-nerd` | pacman/AUR |
| (recomendado) | `noto-fonts noto-fonts-cjk noto-fonts-emoji` | pacman |

## Snaps → equivalentes nativos (Arch não usa snap)

| Snap atual | Arch | Fonte |
|---|---|---|
| brave | `brave-bin` | AUR |
| discord | `discord` | pacman (multilib) |
| firefox | `firefox` | pacman |
| nvim | `neovim` (já é a versão atual no Arch) | pacman |
| steam | `steam` | pacman (multilib) |
| core*/snapd/gnome-* | — (infra do snap) | — |

## Flatpaks → MANTER como flatpak (portável entre distros)

Reinstalar `flatpak` + remote flathub, depois:
`com.google.AndroidStudio`, `com.spotify.Client`, `com.stremio.Stremio`,
`net.ankiweb.Anki`, `org.telegram.desktop`, `com.github.scrivanolabs.scrivano`,
`com.dec05eba.gpu_screen_recorder`.
Lista exata em `raw/flatpak.txt`. (O runtime GL `nvidia-595-71-05` o flatpak
baixa sozinho conforme o driver instalado.)

## Serviços a habilitar no Arch (estavam enabled aqui)

- Sistema: `bluetooth` `cups` `libvirtd` `postgresql` `redis`
- NVIDIA (laptop): `nvidia-suspend` `nvidia-resume` `nvidia-hibernate` `nvidia-powerd`
  (ver `02-nvidia-optimus.md`)
- Áudio: pipewire/wireplumber (default no Arch, só instalar `pipewire pipewire-pulse wireplumber`)
