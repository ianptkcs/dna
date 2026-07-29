#!/usr/bin/env bash
# DNA (Dank · Niri · Arch) — instalador pós-Arch, orquestra install.d/*.sh em ordem.
# UI bonitinha via gum (github.com/charmbracelet/gum, instalado automaticamente
# no primeiro run) — mesma lib que dá a "cara" do instalador do Omarchy.
# Uso:
#   ./install.sh                      roda todos os steps pendentes (resume automático)
#   ./install.sh --only=50-nvidia     roda só um step (por nome, com ou sem .sh) — sem banner/confirm
#   ./install.sh --gpu-mode=dgpu      usa dGPU-only em vez de PRIME offload (ver 02-nvidia-optimus.md)
#                                     (sem essa flag, pergunta interativamente com gum choose)
#   ./install.sh --dry-run           imprime o que faria, sem executar nada
#   ./install.sh --force             ignora os markers de "já feito" e roda tudo de novo
#   ./install.sh --list              lista os steps e se já foram concluídos
#   ./install.sh --yes               não pergunta confirmação em nada
#
# Idempotente: cada step marca conclusão em $STATE_DIR; se algo falhar no meio,
# rode de novo e ele retoma do próximo step pendente.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# --- log persistente: tudo que sai no terminal também vai pro LOG_FILE -------
# (stdin não é tocado, então gum confirm/choose continuam lendo do terminal normalmente)
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1
printf '\n=== DNA install session: %s ===\n' "$(date '+%Y-%m-%d %H:%M:%S')"

export GPU_MODE="offload"
export DRY_RUN=0
export ASSUME_YES=0
FORCE=0
ONLY=""
LIST=0
GPU_MODE_SET=0

for arg in "$@"; do
  case "$arg" in
    --gpu-mode=*) GPU_MODE="${arg#*=}"; GPU_MODE_SET=1 ;;
    --only=*)     ONLY="${arg#*=}" ;;
    --dry-run)    DRY_RUN=1 ;;
    --yes|-y)     ASSUME_YES=1 ;;
    --force)      FORCE=1 ;;
    --list)       LIST=1 ;;
    -h|--help)    awk 'NR==1{next} /^#/{sub(/^# ?/,""); print; next} {exit}' "$0"; exit 0 ;;
    *) log_err "Argumento desconhecido: $arg"; exit 1 ;;
  esac
done

if [[ "$GPU_MODE" != "offload" && "$GPU_MODE" != "dgpu" ]]; then
  log_err "--gpu-mode precisa ser 'offload' ou 'dgpu' (veio: $GPU_MODE)"
  exit 1
fi

STEPS=("$SCRIPT_DIR"/install.d/*.sh)

if [ "$LIST" = "1" ]; then
  for step in "${STEPS[@]}"; do
    if step_done "$step"; then printf '  [x] %s\n' "$(step_name "$step")"
    else printf '  [ ] %s\n' "$(step_name "$step")"; fi
  done
  exit 0
fi

# --- preflight -------------------------------------------------------------
if [ -r /etc/os-release ] && ! grep -q '^ID=arch' /etc/os-release; then
  log_err "Isso não parece ser Arch Linux (/etc/os-release sem ID=arch)."
  log_err "Esse instalador é pra rodar DEPOIS do Arch base instalado — veja README.md."
  exit 1
fi
if [ "$(id -u)" = "0" ]; then
  log_err "Não rode como root — o script usa 'sudo' pontualmente. Rode como seu usuário normal."
  exit 1
fi
if ! sudo -v; then
  log_err "Preciso de sudo pra continuar."
  exit 1
fi
if ! have_cmd pacman; then
  log_err "pacman não encontrado — algo está muito errado."
  exit 1
fi

# --- bootstrap gum (a UI bonitinha) — precisa vir antes de qualquer banner/confirm --
if ! have_cmd gum; then
  log_info "Instalando gum (UI do instalador)"
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "  [dry-run] sudo pacman -S --needed --noconfirm gum"
  else
    sudo pacman -S --needed --noconfirm gum || log_warn "Falha instalando gum — seguindo sem UI bonitinha."
  fi
fi

# --- banner + confirmação + escolha interativa de GPU (só na rodada completa) --
if [ -z "$ONLY" ]; then
  banner
  if [ "$GPU_MODE_SET" = "0" ]; then
    GPU_MODE="$(choose_one 'Modo de GPU (PRIME offload = o que você já usa hoje)' offload dgpu)"
    export GPU_MODE
  fi
  box "Pronto pra instalar?" "" \
    "• Modo GPU: $GPU_MODE" \
    "• dry-run: $DRY_RUN" \
    "• Steps pendentes: $(for s in "${STEPS[@]}"; do step_done "$s" || printf '%s ' "$(step_name "$s")"; done)"
  confirm "Continuar com a instalação?" || { log_warn "Cancelado."; exit 0; }
fi

log_info "Modo GPU: $GPU_MODE  |  dry-run: $DRY_RUN  |  force: $FORCE"
echo

for step in "${STEPS[@]}"; do
  name="$(step_name "$step")"
  if [ -n "$ONLY" ] && [ "$name" != "$ONLY" ] && [ "$name" != "${ONLY%.sh}" ]; then
    continue
  fi
  if [ "$FORCE" != "1" ] && step_done "$step"; then
    log_ok "$name (já feito, pulando — use --force pra repetir)"
    continue
  fi
  echo "── $name ──────────────────────────────────────────"
  # shellcheck source=/dev/null
  if bash "$step"; then
    step_mark_done "$step"
    log_ok "$name concluído"
  else
    error_box "✗ $name falhou" "" \
      "Log completo em: $LOG_FILE" "" \
      "Corrija o problema e rode de novo — os steps anteriores ficam marcados" \
      "como feitos, então ele retoma direto daqui (use --only=$name pra repetir só este)."
    exit 1
  fi
  echo
done

if [ -z "$ONLY" ]; then
  box "Instalação concluída! 🎉" "" \
    "Rode 99-validate pra conferir NVIDIA/prime-run se ainda não rodou." "" \
    "Log completo em: $LOG_FILE"
else
  log_ok "$ONLY concluído."
fi
