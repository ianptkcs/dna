#!/usr/bin/env bash
# Roda todos os test_* definidos em test/cases/*.sh. Sem dependência externa.
# Uso: ./test/run.sh
set -uo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DNA_ROOT="$(cd "$TEST_DIR/.." && pwd)"
export DNA_ROOT

source "$TEST_DIR/lib/harness.sh"

for case_file in "$TEST_DIR"/cases/*.sh; do
  echo "── $(basename "$case_file" .sh) ──"
  before="$(declare -F | awk '{print $3}')"
  # shellcheck source=/dev/null
  source "$case_file"
  after="$(declare -F | awk '{print $3}')"
  new_fns="$(LC_ALL=C comm -13 <(echo "$before" | LC_ALL=C sort) <(echo "$after" | LC_ALL=C sort) | grep '^test_' || true)"
  for fn in $new_fns; do "$fn"; done
done

echo
if [ "$TESTS_FAILED" = 0 ]; then
  printf '\033[1;32m%d/%d testes passaram\033[0m\n' "$TESTS_RUN" "$TESTS_RUN"
  exit 0
else
  printf '\033[1;31m%d/%d testes falharam\033[0m\n' "$TESTS_FAILED" "$TESTS_RUN"
  exit 1
fi
