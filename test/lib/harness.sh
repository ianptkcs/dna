#!/usr/bin/env bash
# Harness mínimo, sem dependência externa (sem bats). Cada assert_* conta e
# reporta na hora; test/run.sh soma o total no final.

TESTS_RUN=0
TESTS_FAILED=0

_check() {
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$1" = "0" ]; then
    printf '  \033[1;32mok\033[0m   %s\n' "$2"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    printf '  \033[1;31mFAIL\033[0m %s\n' "$2"
  fi
}

assert_eq() {
  local expected="$1" actual="$2"
  local desc="${3:-'$expected' == '$actual'}"
  [ "$expected" = "$actual" ]
  _check "$?" "$desc"
}

assert_true()  { local desc="$*"; "$@" >/dev/null 2>&1; _check "$?" "sucesso: $desc"; }
assert_false() { local desc="$*"; "$@" >/dev/null 2>&1; local rc=$?; [ "$rc" != 0 ]; _check "$?" "falha esperada: $desc"; }

assert_contains() {
  local haystack="$1" needle="$2"
  [[ "$haystack" == *"$needle"* ]]
  _check "$?" "contém '$needle'"
}

assert_file_exists()     { [ -e "$1" ]; _check "$?" "existe: $1"; }
assert_file_not_exists() { [ ! -e "$1" ]; _check "$?" "não existe: $1"; }
