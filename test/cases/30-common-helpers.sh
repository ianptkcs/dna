#!/usr/bin/env bash
# lib/common.sh: helpers usados por todos os steps.

test_ensure_line_is_idempotent() {
  local f statedir
  statedir="$(mktemp -d)"
  f="$statedir/file.txt"
  touch "$f"
  (
    STATE_DIR="$statedir"
    source "$TABELAOS_ROOT/install/lib/common.sh"
    # ensure_line usa sudo tee -a; sem sudo disponível em teste, sobrescrevemos por uma versão sem sudo
    ensure_line() { local file="$1" line="$2"; grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >>"$file"; }
    ensure_line "$f" "minha-linha"
    ensure_line "$f" "minha-linha"
    ensure_line "$f" "minha-linha"
  )
  local count
  count="$(grep -c '^minha-linha$' "$f")"
  rm -rf "$statedir"
  assert_eq "1" "$count" "ensure_line não deve duplicar"
}

test_step_done_markers() {
  local statedir out
  statedir="$(mktemp -d)"
  out="$(
    STATE_DIR="$statedir"
    source "$TABELAOS_ROOT/install/lib/common.sh"
    step_done "/x/50-nvidia.sh" && echo "done-antes" || echo "nao-feito-antes"
    step_mark_done "/x/50-nvidia.sh"
    step_done "/x/50-nvidia.sh" && echo "done-depois" || echo "nao-feito-depois"
  )"
  rm -rf "$statedir"
  assert_contains "$out" "nao-feito-antes"
  assert_contains "$out" "done-depois"
}

test_dry_run_does_not_execute() {
  local statedir marker out
  statedir="$(mktemp -d)"
  marker="$statedir/marker"
  out="$(
    STATE_DIR="$statedir"
    DRY_RUN=1
    source "$TABELAOS_ROOT/install/lib/common.sh"
    run "criar marker" -- touch "$marker"
  )"
  local marker_exists=1
  [ -e "$marker" ] && marker_exists=0
  rm -rf "$statedir"
  assert_contains "$out" "dry-run"
  assert_eq "1" "$marker_exists" "marker NÃO deveria existir em dry-run"
}

test_run_executes_when_not_dry_run() {
  local statedir marker
  statedir="$(mktemp -d)"
  marker="$statedir/marker"
  (
    STATE_DIR="$statedir"
    source "$TABELAOS_ROOT/install/lib/common.sh"
    run "criar marker" -- touch "$marker"
  ) >/dev/null
  assert_file_exists "$marker"
  rm -rf "$statedir"
}

test_choose_one_respects_assume_yes() {
  local statedir out
  statedir="$(mktemp -d)"
  out="$(
    STATE_DIR="$statedir"
    ASSUME_YES=1
    source "$TABELAOS_ROOT/install/lib/common.sh"
    choose_one "modo?" offload dgpu
  )"
  rm -rf "$statedir"
  assert_eq "offload" "$out" "choose_one deve retornar a 1ª opção com ASSUME_YES=1"
}

test_confirm_respects_assume_yes() {
  local statedir rc
  statedir="$(mktemp -d)"
  (
    STATE_DIR="$statedir"
    ASSUME_YES=1
    source "$TABELAOS_ROOT/install/lib/common.sh"
    confirm "continuar?"
  )
  rc=$?
  rm -rf "$statedir"
  assert_eq "0" "$rc" "confirm deve retornar sucesso direto com ASSUME_YES=1"
}
