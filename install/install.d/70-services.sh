#!/usr/bin/env bash
# Serviços de sistema (NVIDIA já foi habilitado em 50-nvidia.sh).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

SERVICES=(bluetooth.service libvirtd.service postgresql.service redis.service)

spin_run "habilitar serviços de sistema" -- sudo systemctl enable "${SERVICES[@]}"

if pacman -Qq cups >/dev/null 2>&1; then
  spin_run "habilitar cups (impressão)" -- sudo systemctl enable cups.service
else
  log_warn "cups não instalado — pule ou 'sudo pacman -S cups' se precisar de impressão."
fi
