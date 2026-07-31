#!/usr/bin/env bash
# Builda a ISO do TabelaOS: vendora o repo atual pro profile e roda mkarchiso dentro
# de um container Arch (via podman), já que mkarchiso não roda fora do Arch.
# Uso: ./iso/build.sh
set -euo pipefail

ISO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TABELAOS_ROOT="$(cd "$ISO_DIR/.." && pwd)"
PROFILE_DIR="$ISO_DIR/profile"
BAKE_DIR="$PROFILE_DIR/airootfs/root/tabelaos"
OUT_DIR="$ISO_DIR/out"

echo ">>> Vendorando o repo tabelaos em $BAKE_DIR"
rm -rf "$BAKE_DIR"
mkdir -p "$BAKE_DIR"
rsync -a --exclude='.git' --exclude='iso/profile' --exclude='iso/out' \
  --exclude='iso/releng-upstream' \
  "$TABELAOS_ROOT/" "$BAKE_DIR/"

mkdir -p "$OUT_DIR"

echo ">>> Rodando mkarchiso num container archlinux:latest (podman, --privileged)"
podman run --rm --privileged --network=host \
  -v "$PROFILE_DIR:/profile:Z" \
  -v "$OUT_DIR:/out:Z" \
  archlinux:latest \
  bash -c '
    set -euo pipefail
    pacman -Sy --noconfirm archiso
    mkarchiso -v -w /tmp/work -o /out /profile
  '

echo ">>> ISO gerada em: $OUT_DIR"
ls -la "$OUT_DIR"
