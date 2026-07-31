#!/usr/bin/env bash
# Builda a variante de TESTE da ISO (console serial + autologin ttyS0), a partir
# de profile-test/ (que já deve ter o airootfs/root/tabelaos vendorado por build.sh).
# NÃO é a ISO real — só pra automatizar testes em QEMU via expect.
set -euo pipefail

ISO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_DIR="$ISO_DIR/profile-test"
OUT_DIR="$ISO_DIR/out-test"

mkdir -p "$OUT_DIR"

echo ">>> Rodando mkarchiso (profile de TESTE) num container archlinux:latest"
podman run --rm --privileged --network=host \
  -v "$PROFILE_DIR:/profile:Z" \
  -v "$OUT_DIR:/out:Z" \
  archlinux:latest \
  bash -c '
    set -euo pipefail
    pacman -Sy --noconfirm archiso
    mkarchiso -v -w /tmp/work -o /out /profile
  '

echo ">>> ISO de teste gerada em: $OUT_DIR"
ls -la "$OUT_DIR"
