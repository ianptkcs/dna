#!/usr/bin/env bash
# NVIDIA + Optimus — ver ../02-nvidia-optimus.md para a explicação completa de cada passo.
# Modo controlado por $GPU_MODE: "offload" (PRIME, padrão/recomendado) ou "dgpu" (MUX/dGPU-only).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

GPU_MODE="${GPU_MODE:-offload}"
log_info "Modo GPU: $GPU_MODE"

# ---------------------------------------------------------------------------
# 1. /etc/modprobe.d/nvidia.conf — replica o que já funciona hoje no Ubuntu
# ---------------------------------------------------------------------------
MODPROBE_CONF=/etc/modprobe.d/nvidia.conf
MODPROBE_WANT=$'options nvidia_drm modeset=1\noptions nvidia NVreg_PreserveVideoMemoryAllocations=1\noptions nvidia NVreg_TemporaryFilePath=/var'

if [ -f "$MODPROBE_CONF" ] && diff -q <(printf '%s\n' "$MODPROBE_WANT") "$MODPROBE_CONF" >/dev/null 2>&1; then
  log_ok "$MODPROBE_CONF já está correto"
elif [ "${DRY_RUN:-0}" = "1" ]; then
  echo "  [dry-run] escrever $MODPROBE_CONF com modeset=1 + PreserveVideoMemoryAllocations"
else
  log_info "Escrevendo $MODPROBE_CONF"
  printf '%s\n' "$MODPROBE_WANT" | sudo tee "$MODPROBE_CONF" >/dev/null
fi

# ---------------------------------------------------------------------------
# 2. mkinitcpio — carregar os módulos NVIDIA cedo (edição idempotente da linha MODULES=)
# ---------------------------------------------------------------------------
MKINITCPIO_CONF=/etc/mkinitcpio.conf
NEEDED_MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
need_mkinitcpio_rebuild=0

current_line="$(grep -E '^MODULES=' "$MKINITCPIO_CONF" || true)"
if [ -z "$current_line" ]; then
  log_err "Não encontrei 'MODULES=(...)' em $MKINITCPIO_CONF — edite manualmente."
  exit 1
fi

missing=()
for m in "${NEEDED_MODULES[@]}"; do
  echo "$current_line" | grep -qw "$m" || missing+=("$m")
done

if [ ${#missing[@]} -eq 0 ]; then
  log_ok "mkinitcpio MODULES já inclui os módulos NVIDIA"
elif [ "${DRY_RUN:-0}" = "1" ]; then
  echo "  [dry-run] adicionar '${missing[*]}' à linha MODULES= em $MKINITCPIO_CONF"
else
  log_info "Adicionando módulos faltantes ao mkinitcpio: ${missing[*]}"
  new_line="$(echo "$current_line" | sed -E "s/\)\s*\$/ ${missing[*]})/")"
  sudo sed -i "s|^MODULES=.*|$new_line|" "$MKINITCPIO_CONF"
  need_mkinitcpio_rebuild=1
fi

# ---------------------------------------------------------------------------
# 3. GRUB — nvidia_drm.modeset=1 na cmdline, por garantia (você já usa GRUB EFI)
# ---------------------------------------------------------------------------
GRUB_FILE=/etc/default/grub
need_grub_rebuild=0

grub_line="$(grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUB_FILE" || true)"
if [ -z "$grub_line" ]; then
  log_warn "Não encontrei GRUB_CMDLINE_LINUX_DEFAULT em $GRUB_FILE — pulei esse ajuste, confira manualmente."
elif echo "$grub_line" | grep -q 'nvidia_drm.modeset=1'; then
  log_ok "GRUB já tem nvidia_drm.modeset=1"
elif [ "${DRY_RUN:-0}" = "1" ]; then
  echo "  [dry-run] adicionar 'nvidia_drm.modeset=1' a GRUB_CMDLINE_LINUX_DEFAULT em $GRUB_FILE"
else
  log_info "Adicionando nvidia_drm.modeset=1 ao GRUB_CMDLINE_LINUX_DEFAULT"
  new_grub_line="$(echo "$grub_line" | sed -E 's/"[[:space:]]*$/ nvidia_drm.modeset=1"/')"
  sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|$new_grub_line|" "$GRUB_FILE"
  need_grub_rebuild=1
fi

if [ "$need_mkinitcpio_rebuild" = "1" ]; then
  run "mkinitcpio -P" -- sudo mkinitcpio -P
fi
if [ "$need_grub_rebuild" = "1" ]; then
  run "grub-mkconfig" -- sudo grub-mkconfig -o /boot/grub/grub.cfg
fi

# ---------------------------------------------------------------------------
# 4. Serviços de energia/suspend (laptop)
# ---------------------------------------------------------------------------
run "habilitar serviços NVIDIA (suspend/resume/hibernate/powerd)" -- \
  sudo systemctl enable nvidia-suspend.service nvidia-resume.service \
    nvidia-hibernate.service nvidia-powerd.service

# ---------------------------------------------------------------------------
# 5. Decisão de modo — só orienta; a troca de BIOS não dá pra automatizar
# ---------------------------------------------------------------------------
case "$GPU_MODE" in
  offload)
    log_ok "Modo PRIME render offload (padrão): use 'prime-run <app>' pra rodar na NVIDIA."
    log_ok "Steam: 'prime-run %command%' nas opções de inicialização do jogo."
    ;;
  dgpu)
    box "⚠ Modo dGPU-only escolhido" "" \
      "Confirme no BIOS do Clevo que existe MUX/'Discrete' e troque pra lá ANTES" \
      "do primeiro boot pós-instalação — isso não dá pra automatizar por software." \
      "Sem MUX, use o modo 'offload' em vez desse."
    confirm "Já conferiu o BIOS (ou vai conferir antes de reiniciar)?" || \
      log_warn "Ok — lembre de checar antes do próximo boot."
    ;;
esac

echo
log_info "Validação: nvidia-smi ; prime-run glxinfo | grep 'OpenGL renderer' ; glxinfo | grep 'OpenGL renderer'"
