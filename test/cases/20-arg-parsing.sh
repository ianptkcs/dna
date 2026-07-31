#!/usr/bin/env bash
# install.sh: paths que retornam antes do preflight (funcionam em qualquer OS).

test_help_exits_zero_and_prints_usage() {
  local out rc
  out="$("$TABELAOS_ROOT/install/install.sh" --help 2>&1)"; rc=$?
  assert_eq "0" "$rc" "--help sai com 0"
  assert_contains "$out" "Uso:"
  assert_false [ -z "$out" ]
}

test_list_exits_zero_and_lists_all_steps() {
  local out rc statedir
  statedir="$(mktemp -d)"
  out="$(STATE_DIR="$statedir" "$TABELAOS_ROOT/install/install.sh" --list 2>&1)"; rc=$?
  rm -rf "$statedir"
  assert_eq "0" "$rc" "--list sai com 0"
  assert_contains "$out" "10-multilib"
  assert_contains "$out" "99-validate"
}

test_invalid_gpu_mode_rejected() {
  local rc
  "$TABELAOS_ROOT/install/install.sh" --gpu-mode=bogus --list >/dev/null 2>&1
  rc=$?
  assert_false [ "$rc" = 0 ]
}

test_unknown_flag_rejected() {
  local rc
  "$TABELAOS_ROOT/install/install.sh" --isso-nao-existe >/dev/null 2>&1
  rc=$?
  assert_false [ "$rc" = 0 ]
}

test_list_marks_done_steps() {
  local statedir out
  statedir="$(mktemp -d)"
  touch "$statedir/10-multilib.done"
  out="$(STATE_DIR="$statedir" "$TABELAOS_ROOT/install/install.sh" --list 2>&1)"
  rm -rf "$statedir"
  assert_contains "$out" "[x] 10-multilib"
}
