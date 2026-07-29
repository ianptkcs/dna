#!/usr/bin/env bash
# Clona (se preciso) e faz stow dos dotfiles; instala runtimes via mise.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/stow-packages.sh"

DOTFILES_DIR="$HOME/dotfiles"
DOTFILES_REPO="https://github.com/ianptkcs/dotfiles.git"

if [ ! -d "$DOTFILES_DIR" ]; then
  spin_run "clonar dotfiles" -- git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
  log_ok "$DOTFILES_DIR já existe"
fi

have_cmd stow || { log_err "stow não encontrado — rode 20-pacman-packages antes."; exit 1; }

if [ "${DRY_RUN:-0}" = "1" ]; then
  for pkg in "${STOW_PACKAGES[@]}"; do echo "  [dry-run] stow -t $HOME $pkg"; done
else
  cd "$DOTFILES_DIR"
  failed=()
  for pkg in "${STOW_PACKAGES[@]}"; do
    if stow -v -t "$HOME" "$pkg"; then
      log_ok "stow $pkg"
    else
      failed+=("$pkg")
      log_warn "stow $pkg falhou (provável arquivo já existente em ~) — mova/renomeie o"
      log_warn "arquivo conflitante e rode: cd $DOTFILES_DIR && stow -t \$HOME $pkg"
    fi
  done
  [ ${#failed[@]} -eq 0 ] || log_warn "Pacotes com conflito pendente: ${failed[*]}"
fi

# --- mise (runtimes: bun/node/go/java/python/elixir/erlang/typst/yazi/...) --
MISE_BIN="$(command -v mise || true)"
if [ -z "$MISE_BIN" ] && [ -x "$HOME/.local/bin/mise" ]; then
  MISE_BIN="$HOME/.local/bin/mise"
fi

if [ -z "$MISE_BIN" ]; then
  if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "  [dry-run] curl https://mise.run | sh"
  else
    log_info "Instalando mise"
    curl -fsSL https://mise.run | sh
  fi
  MISE_BIN="$HOME/.local/bin/mise"
fi

if [ -x "$MISE_BIN" ] || [ "${DRY_RUN:-0}" = "1" ]; then
  run "mise install (runtimes fixados em ~/.config/mise/config.toml)" -- "$MISE_BIN" install
else
  log_warn "mise não ficou disponível — rode 'mise install' manualmente depois de abrir um shell novo."
fi
