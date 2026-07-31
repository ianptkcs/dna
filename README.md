<div align="center">

# TabelaOS

**Instalador Arch Linux com UI estilo Omarchy (`gum`), pro stack niri +
DankMaterialShell** — testado em ISO bootável via QEMU antes de rodar em
hardware real.

[![Shell](https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash&logoColor=white)](install/install.sh)
[![Arch Linux](https://img.shields.io/badge/target-Arch%20Linux-1793D1?style=flat-square&logo=archlinux&logoColor=white)](https://archlinux.org)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue?style=flat-square)](LICENSE)

</div>

---

## O que é

Plano + instalador pra migrar do Ubuntu atual pro Arch Linux mantendo o mesmo
stack (niri + DankMaterialShell), com a UI do instalador do Omarchy (via
`gum`) mas sem herdar o resto da arquitetura dele (que é pra Hyprland).

Snapshot original levantado em **2026-06-29** da máquina atual (Ubuntu,
notebook Clevo "LUNAR", Intel Raptor Lake iGPU + NVIDIA RTX 4050 Mobile).

> Status: **instalador pós-Arch pronto e testado (incluindo build de uma ISO
> bootável validada em QEMU); migração em si na máquina real ainda não
> rodou.** Use isto como rede de segurança quando/se decidir trocar.

## Índice

- [Ordem de operação](#ordem-de-operação-quando-for-migrar)
- [Decisão em aberto](#decisão-que-ainda-precisa-ser-tomada)
- [Arquivos](#arquivos)
- [Rodando os testes](#rodando-os-testes)
- [Hardware/sistema de referência](#fatos-do-hardwaresistema-referência)
- [Licença](#licença)

## Ordem de operação (quando for migrar)

1. **`00-backup-checklist.md`** — fazer backup de segredos + dados + dotfiles.
   Empurrar os dotfiles pro GitHub é o passo nº 1.
2. Instalar o Arch (base + GRUB EFI + `linux` + `linux-lts`).
3. **`install/install.sh`** ("TabelaOS") — instalador único,
   idempotente, com a UI do Omarchy (gum) mas pro stack niri+DankMaterialShell:
   cobre multilib, pacotes pacman+AUR, NVIDIA/Optimus (a parte mais delicada),
   flatpak, serviços, shell, stow dos dotfiles e mise. Ver `install/README.md`
   pra uso e flags.
4. Validar niri + previews + jogos (`install/install.d/99-validate.sh` já roda isso).

> `01-packages.md`, `02-nvidia-optimus.md` e `03-install-packages.sh` continuam
> como a documentação/rascunho original — `install/` é a versão executável e
> automatizada deles, um step por arquivo em `install/install.d/`.

## Decisão que ainda precisa ser tomada

**Modo gráfico do notebook** (ver `02-nvidia-optimus.md`):
- **PRIME render offload** (o que você usa hoje: iGPU na tela, jogo via `prime-run`).
- **dGPU-only** (só NVIDIA — depende de MUX no BIOS do Clevo; melhor pra jogo, pior bateria).

O `03-install-packages.sh` tem marcadores `# DECISÃO:` nos pontos afetados.

## Arquivos

| Arquivo | O que é |
|---|---|
| `00-backup-checklist.md` | Segredos, dados e configs a salvar antes de formatar |
| `01-packages.md` | Mapeamento apt/snap/flatpak → Arch (pacman/AUR), por categoria |
| `02-nvidia-optimus.md` | Setup NVIDIA + Optimus no Arch (gaming + suspend + niri) |
| `03-install-packages.sh` | Script idempotente de pós-instalação (rascunho original, superado por `install/`) |
| `install/` | **Instalador executável** (estilo Omarchy): `install.sh` + steps numerados em `install.d/` |
| `bin/tabelaos-reinstall-configs` | Resync dos dotfiles (restow) sem rodar o resto do instalador — pra quando algo driftar depois |
| `iso/` | Build da ISO archiso+LUKS2 customizada, testada em QEMU |
| `test/` | Suite de testes sem dependência externa (`./test/run.sh`) — sintaxe, parsing de flags, idempotência |
| `raw/` | Listas brutas exatas capturadas da máquina atual |

## Rodando os testes

```bash
./test/run.sh
```

Não precisa de Arch nem de root — testa sintaxe (`bash -n`), parsing de flags
do `install.sh`, idempotência dos helpers (`ensure_line`, markers de step) e
sanidade das listas de pacotes (sem duplicata entre pacman/AUR).

## Fatos do hardware/sistema (referência)

- **CPU/iGPU**: Intel Raptor Lake-S UHD (`i915`/`xe`)
- **dGPU**: NVIDIA RTX 4050 Max-Q Mobile (Ada, `AD107M`, `10de:28a1`)
- **Driver atual**: proprietário **595** open-kernel-modules, modeset=1, em PRIME offload
- **Boot**: GRUB EFI
- **Shell de login**: `/usr/bin/fish`
- **Teclado**: `br` / **`abnt2`** (dead keys — relevante na escolha de terminal)
- **Locale**: `en_US.UTF-8`
- **Compositor**: niri + DankMaterialShell (`dms`) + waybar — ecossistema **DankLinux** (AvengeMedia)
- **Input method**: ibus + tabelas Cangjie/Chewing/Pinyin (mandarim)

## Licença

[GNU AGPL-3.0](LICENSE) — livre e open source. Se você distribuir uma
versão modificada deste instalador, também precisa disponibilizar o
código-fonte modificado sob a mesma licença.
