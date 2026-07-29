#!/usr/bin/env bash
# Sanidade das listas de pacotes — só parseia o texto do array, nunca executa
# o step (que faria pacman -S de verdade).

_extract_array() {
  local file="$1" name="$2"
  awk -v name="$name" '
    $0 ~ "^"name"=\\(" { inarr=1; next }
    inarr && /^\)/ { inarr=0 }
    inarr { gsub(/#.*/, ""); print }
  ' "$file" | tr -s ' \t' '\n' | sed '/^$/d'
}

test_pacman_pkgs_no_duplicates() {
  local file="$DNA_ROOT/install/install.d/20-pacman-packages.sh"
  local pkgs dupes
  pkgs="$(_extract_array "$file" PACMAN_PKGS)"
  dupes="$(echo "$pkgs" | sort | uniq -d)"
  assert_eq "" "$dupes" "PACMAN_PKGS não deve ter duplicatas (achou: $dupes)"
}

test_aur_pkgs_no_duplicates() {
  local file="$DNA_ROOT/install/install.d/40-aur-packages.sh"
  local pkgs dupes
  pkgs="$(_extract_array "$file" AUR_PKGS)"
  dupes="$(echo "$pkgs" | sort | uniq -d)"
  assert_eq "" "$dupes" "AUR_PKGS não deve ter duplicatas (achou: $dupes)"
}

test_pacman_and_aur_dont_overlap() {
  local pac aur overlap
  pac="$(_extract_array "$DNA_ROOT/install/install.d/20-pacman-packages.sh" PACMAN_PKGS | LC_ALL=C sort -u)"
  aur="$(_extract_array "$DNA_ROOT/install/install.d/40-aur-packages.sh" AUR_PKGS | LC_ALL=C sort -u)"
  overlap="$(LC_ALL=C comm -12 <(echo "$pac") <(echo "$aur"))"
  assert_eq "" "$overlap" "mesmo pacote não deveria estar em pacman E aur (achou: $overlap)"
}

test_pacman_pkgs_not_empty() {
  local pkgs count
  pkgs="$(_extract_array "$DNA_ROOT/install/install.d/20-pacman-packages.sh" PACMAN_PKGS)"
  count="$(echo "$pkgs" | grep -c .)"
  assert_false [ "$count" -lt 10 ]
}
