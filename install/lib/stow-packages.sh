#!/usr/bin/env bash
# Fonte única da lista de pacotes stow — usada por install.d/90-dotfiles.sh
# e por bin/dna-reinstall-configs, pra nunca ficarem dessincronizados.
# shellcheck disable=SC2034 # consumido por scripts que dão `source` neste arquivo
STOW_PACKAGES=(alacritty fish foot git mise niri nvim starship tmux yazi DankMaterialShell)
