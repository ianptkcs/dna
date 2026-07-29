#!/usr/bin/env bash
# Habilita [multilib] em /etc/pacman.conf (necessário pra Steam e libs 32-bit).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

CONF=/etc/pacman.conf

if grep -qE '^\[multilib\]' "$CONF"; then
  log_ok "[multilib] já habilitado em $CONF"
  exit 0
fi

if [ "${DRY_RUN:-0}" = "1" ]; then
  echo "  [dry-run] descomentar [multilib] + Include em $CONF e rodar 'pacman -Sy'"
  exit 0
fi

if grep -qE '^#\[multilib\]' "$CONF"; then
  log_info "Descomentando bloco [multilib] em $CONF"
  sudo sed -i \
    -e '/^#\[multilib\]/s/^#//' \
    -e '/^\[multilib\]/{n;s/^#Include/Include/}' \
    "$CONF"
else
  log_info "Bloco [multilib] não encontrado comentado — adicionando ao fim de $CONF"
  printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a "$CONF" >/dev/null
fi

grep -qE '^\[multilib\]' "$CONF" || { log_err "Falha ao habilitar [multilib], confira $CONF manualmente"; exit 1; }

spin_run "pacman -Sy (refresh após multilib)" -- sudo pacman -Sy
