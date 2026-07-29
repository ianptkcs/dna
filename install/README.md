# DNA (Dank · Niri · Arch) — instalador pós-Arch

Um comando, idempotente, retomável, com a mesma "cara" do instalador do Omarchy
(mesma lib de UI: [gum](https://github.com/charmbracelet/gum)), mas pro seu
próprio stack — niri + DankMaterialShell, não Hyprland. Roda **depois** do
Arch base instalado (pacstrap + GRUB EFI + usuário criado), num shell com sudo.

```bash
git clone <url-do-repo-dna> ~/codigo/pessoal/dna
cd ~/codigo/pessoal/dna/install
./install.sh
```

## UI (gum)

- `gum` é instalado automaticamente no primeiro run (bootstrap antes de tudo,
  igual o Omarchy faz — ver `install.sh`). Sem ele, tudo cai num fallback de
  texto simples (`lib/common.sh`), então o script nunca trava por falta de gum.
- Na rodada completa (sem `--only`) você vê: banner **DNA**, escolha interativa
  de modo de GPU (`gum choose`, se não passou `--gpu-mode`), uma caixa
  resumindo o plano e uma confirmação (`gum confirm`) antes de começar.
- `--only=<step>` pula banner/confirm — modo rápido pra debugar um step isolado.
- Passos rápidos (refresh do pacman, clone de repo, enable de serviço, chsh)
  mostram um spinner (`gum spin`). Passos longos com output relevante
  (`pacman -S`, build do AUR, `mise install`, downloads do flatpak) continuam
  com saída visível — não escondemos progresso/erros atrás de spinner nesses,
  de propósito (é o mesmo motivo pelo qual o Omarchy usa log+stream em vez de
  spinner nos passos de pacote).

## Como funciona

- `install.sh` roda cada `install.d/NN-nome.sh` em ordem.
- Cada step marca conclusão em `~/.cache/dna-install/<nome>.done`.
  Se algo falhar no meio (ex.: rede caiu no meio do `pacman -S`), corrija e rode
  `./install.sh` de novo — ele **pula os steps já feitos** e continua de onde parou.
- Nenhum step é destrutivo: só instala pacotes, habilita serviços e edita
  configs de forma idempotente (nunca duplica linha, nunca sobrescreve sem checar).
- **Log persistente**: tudo que aparece no terminal também é gravado em
  `~/.cache/dna-install/install.log` (append entre execuções, com um cabeçalho
  de timestamp por sessão). Se um step falhar, a caixa de erro (`error_box`)
  mostra o caminho do log pra debug — `stdin` não é tocado, então `gum
  confirm`/`gum choose` continuam interativos normalmente.

## Flags

| Flag | Efeito |
|---|---|
| `--dry-run` | Imprime o que cada step faria, sem executar nada |
| `--gpu-mode=offload` | PRIME render offload (padrão — o que você já usa hoje) |
| `--gpu-mode=dgpu` | dGPU-only (só se o BIOS do Clevo tiver MUX — ver `../02-nvidia-optimus.md`) |
| `--only=50-nvidia` | Roda só um step (nome com ou sem `.sh`) |
| `--force` | Ignora os markers de "já feito" e roda tudo de novo |
| `--list` | Lista os steps e quais já foram concluídos |
| `--yes` / `-y` | Não pergunta confirmação em nada que peça (`confirm()`) |

## Steps

| Step | O que faz |
|---|---|
| `10-multilib` | Habilita `[multilib]` no pacman.conf (Steam/libs 32-bit) |
| `20-pacman-packages` | Pacotes oficiais (dev, shell, niri, gaming, mandarim, fontes...) |
| `30-aur-helper` | Instala `paru` se não houver AUR helper |
| `40-aur-packages` | Pacotes AUR (brave, ngrok, tabelas Cangjie...) |
| `50-nvidia` | modprobe.d + mkinitcpio + GRUB + serviços NVIDIA/Optimus |
| `60-flatpak` | Flathub + apps portáveis (Anki, Spotify, Android Studio...) |
| `70-services` | bluetooth/libvirtd/postgresql/redis (+ cups se instalado) |
| `80-shell` | `chsh` pra fish |
| `90-dotfiles` | Clona `~/dotfiles` se preciso, `stow` dos pacotes, instala mise + `mise install` |
| `99-validate` | `nvidia-smi`/`prime-run` + checklist do que fica manual (BIOS MUX, ibus, OpenRGB...) |

## O que NÃO é automatizado (de propósito)

- **Troca de MUX no BIOS** (modo dGPU-only) — é hardware, não dá.
- **DankMaterialShell/quickshell/matugen/dgop** — o ecossistema DankLinux tem
  instalador próprio; rode-o à parte e confira antes de instalar via AUR pra
  não duplicar/conflitar versão (ver aviso no fim de `40-aur-packages.sh`).
- Segredos (`~/.ssh`, `~/.gnupg`, tokens...) — isso é `00-backup-checklist.md`,
  restaurar é manual por natureza.
- ibus (tabelas de mandarim), OpenRGB, qt5ct/qt6ct, `monitors.xml`,
  `mimeapps.list` — ficam listados em `99-validate.sh` como pendência manual.
