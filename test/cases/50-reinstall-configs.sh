#!/usr/bin/env bash
# bin/dna-reinstall-configs: smoke test com um $HOME e dotfiles fake (nunca
# toca o $HOME de verdade).

_make_fake_home() {
  local fakehome pkg
  fakehome="$(mktemp -d)"
  mkdir -p "$fakehome/dotfiles"
  for pkg in alacritty fish foot git mise niri nvim starship tmux yazi DankMaterialShell; do
    mkdir -p "$fakehome/dotfiles/$pkg/.config/$pkg"
    touch "$fakehome/dotfiles/$pkg/.config/$pkg/dummy.conf"
  done
  echo "$fakehome"
}

test_reinstall_configs_help() {
  local out rc
  out="$("$DNA_ROOT/bin/dna-reinstall-configs" --help 2>&1)"; rc=$?
  assert_eq "0" "$rc"
  assert_contains "$out" "Uso:"
}

test_reinstall_configs_missing_dotfiles_fails() {
  local fakehome rc
  fakehome="$(mktemp -d)"
  HOME="$fakehome" "$DNA_ROOT/bin/dna-reinstall-configs" --yes >/dev/null 2>&1
  rc=$?
  rm -rf "$fakehome"
  assert_false [ "$rc" = 0 ]
}

test_reinstall_configs_check_does_not_modify() {
  local fakehome
  fakehome="$(_make_fake_home)"
  HOME="$fakehome" "$DNA_ROOT/bin/dna-reinstall-configs" --check >/dev/null 2>&1
  assert_file_not_exists "$fakehome/.config/fish"
  rm -rf "$fakehome"
}

test_reinstall_configs_yes_creates_symlinks() {
  local fakehome
  fakehome="$(_make_fake_home)"
  HOME="$fakehome" "$DNA_ROOT/bin/dna-reinstall-configs" --yes >/dev/null 2>&1
  assert_true [ -L "$fakehome/.config/fish" ]
  assert_true [ -L "$fakehome/.config/DankMaterialShell" ]
  rm -rf "$fakehome"
}

test_reinstall_configs_is_idempotent() {
  local fakehome rc1 rc2
  fakehome="$(_make_fake_home)"
  HOME="$fakehome" "$DNA_ROOT/bin/dna-reinstall-configs" --yes >/dev/null 2>&1; rc1=$?
  HOME="$fakehome" "$DNA_ROOT/bin/dna-reinstall-configs" --yes >/dev/null 2>&1; rc2=$?
  rm -rf "$fakehome"
  assert_eq "0" "$rc1"
  assert_eq "0" "$rc2"
}
