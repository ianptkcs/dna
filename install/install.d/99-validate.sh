#!/usr/bin/env bash
# Checks finais + lembrete do que fica de fora da automação (ver 00-backup-checklist.md).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

echo "=== NVIDIA / Optimus ==="
if have_cmd nvidia-smi; then
  nvidia-smi --query-gpu=name,driver_version --format=csv,noheader || log_warn "nvidia-smi rodou mas sem GPU detectada"
else
  log_warn "nvidia-smi não encontrado"
fi

if have_cmd glxinfo; then
  echo "-- sem prime-run (esperado: Intel) --"
  glxinfo | grep "OpenGL renderer" || true
  if have_cmd prime-run; then
    echo "-- com prime-run (esperado: NVIDIA RTX 4050) --"
    prime-run glxinfo | grep "OpenGL renderer" || true
  else
    log_warn "prime-run não encontrado (nvidia-prime instalado?)"
  fi
else
  log_warn "glxinfo não encontrado — 'sudo pacman -S mesa-utils' pra checar."
fi

echo
echo "=== Pendências manuais (não automatizáveis por aqui) ==="
cat <<'EOF'
  [ ] BIOS do Clevo: confirmar se existe MUX/"Discrete" (só relevante se --gpu-mode=dgpu)
  [ ] ibus: reconfigurar tabelas de mandarim (Cangjie/Chewing/Pinyin) — ver 00-backup-checklist.md
  [ ] OpenRGB: reimportar perfis de RGB salvos no backup
  [ ] qt5ct / qt6ct: tema Qt
  [ ] monitors.xml / layout de telas (tiling-assistant)
  [ ] mimeapps.list: apps padrão por tipo de arquivo
  [ ] Senhas do navegador: confirmar sync do Brave/Firefox
  [ ] Validar niri + DankMaterialShell subindo (Mod+D calendário, previews yazi, etc.)
EOF
