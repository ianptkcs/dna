#!/usr/bin/env bash
# Sintaxe de todos os scripts do instalador (bash -n).

test_syntax_all_scripts() {
  local f
  for f in "$TABELAOS_ROOT"/install/install.sh "$TABELAOS_ROOT"/install/lib/common.sh \
    "$TABELAOS_ROOT"/install/lib/stow-packages.sh "$TABELAOS_ROOT"/install/install.d/*.sh \
    "$TABELAOS_ROOT"/bin/tabelaos-reinstall-configs "$TABELAOS_ROOT"/iso/bootstrap.sh \
    "$TABELAOS_ROOT"/iso/build.sh; do
    assert_true bash -n "$f"
  done
}
