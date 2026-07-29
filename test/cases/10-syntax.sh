#!/usr/bin/env bash
# Sintaxe de todos os scripts do instalador (bash -n).

test_syntax_all_scripts() {
  local f
  for f in "$DNA_ROOT"/install/install.sh "$DNA_ROOT"/install/lib/common.sh \
    "$DNA_ROOT"/install/lib/stow-packages.sh "$DNA_ROOT"/install/install.d/*.sh \
    "$DNA_ROOT"/bin/dna-reinstall-configs "$DNA_ROOT"/iso/bootstrap.sh \
    "$DNA_ROOT"/iso/build.sh; do
    assert_true bash -n "$f"
  done
}
