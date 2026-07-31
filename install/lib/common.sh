#!/usr/bin/env bash
# Shared helpers for install.d/*.sh steps. Sourced, not executed directly.

STATE_DIR="${STATE_DIR:-$HOME/.cache/tabelaos-install}"
mkdir -p "$STATE_DIR"
LOG_FILE="${LOG_FILE:-$STATE_DIR/install.log}"

_c_reset=$'\033[0m'; _c_blue=$'\033[1;34m'; _c_green=$'\033[1;32m'
_c_yellow=$'\033[1;33m'; _c_red=$'\033[1;31m'

log_info() { printf '%s>>> %s%s\n' "$_c_blue" "$*" "$_c_reset"; }
log_ok()   { printf '%s  ok: %s%s\n' "$_c_green" "$*" "$_c_reset"; }
log_warn() { printf '%s  !! %s%s\n' "$_c_yellow" "$*" "$_c_reset"; }
log_err()  { printf '%s  xx %s%s\n' "$_c_red" "$*" "$_c_reset" >&2; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# run <descrição> -- <cmd...>   respeita DRY_RUN=1 (só imprime, não executa)
run() {
  local desc="$1"; shift
  [ "$1" = "--" ] && shift
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '  [dry-run] %s: %s\n' "$desc" "$*"
    return 0
  fi
  log_info "$desc"
  "$@"
}

# marker de step concluído, pra permitir resume sem repetir trabalho já feito
step_name() { basename "$1" .sh; }
step_done()      { [ -f "$STATE_DIR/$(step_name "$1").done" ]; }
step_mark_done() { [ "${DRY_RUN:-0}" = "1" ] || touch "$STATE_DIR/$(step_name "$1").done"; }

# idempotent line-in-file: adiciona $2 em $1 só se ainda não estiver lá
ensure_line() {
  local file="$1" line="$2"
  grep -qxF "$line" "$file" 2>/dev/null || echo "$line" | sudo tee -a "$file" >/dev/null
}

confirm() {
  local prompt="$1"
  [ "${ASSUME_YES:-0}" = "1" ] && return 0
  if have_cmd gum; then
    gum confirm "$prompt"
    return $?
  fi
  read -r -p "$prompt [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# caixa estilo Omarchy (gum style --border ...); cai pra texto simples sem gum
box() {
  if have_cmd gum; then
    gum style --border normal --padding "1 2" --margin "1 0" --border-foreground 6 "$@"
  else
    printf -- '--- %s ---\n' "$1"; shift; printf '%s\n' "$@"
  fi
}

error_box() {
  if have_cmd gum; then
    gum style --border normal --padding "1 2" --margin "1 0" --border-foreground 1 --bold "$@"
  else
    printf -- '!!! %s !!!\n' "$1"; shift; printf '%s\n' "$@"
  fi
}

banner() {
  if have_cmd gum; then
    gum style --border double --border-foreground 6 --padding "1 4" --margin "1 0" \
      --align center --bold "TabelaOS"
  else
    printf '=== TabelaOS ===\n'
  fi
}

# roda um comando rápido/silencioso com spinner; sem gum, cai pro run() normal
spin_run() {
  local desc="$1"; shift
  [ "$1" = "--" ] && shift
  if [ "${DRY_RUN:-0}" = "1" ]; then
    printf '  [dry-run] %s: %s\n' "$desc" "$*"
    return 0
  fi
  if have_cmd gum; then
    gum spin --spinner dot --title "$desc" -- "$@"
  else
    run "$desc" -- "$@"
  fi
}

# gum choose <header> <opções...>; sem gum, retorna a primeira opção (default)
choose_one() {
  local header="$1"; shift
  if [ "${ASSUME_YES:-0}" = "1" ] || ! have_cmd gum; then
    echo "$1"
    return 0
  fi
  printf '%s\n' "$@" | gum choose --header "$header"
}
