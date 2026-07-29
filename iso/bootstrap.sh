#!/usr/bin/env bash
# DNA bootstrap — roda a partir da ISO live (via boot param script=/root/dna/iso/bootstrap.sh).
# Particiona um disco DO ZERO (ESP + LUKS2 root), instala o Arch base, configura
# GRUB+criptografia, e entrega pro install/install.sh de dentro do chroot.
#
# ⚠ DESTRUTIVO: apaga TUDO no disco escolhido. Pede confirmação digitada antes
# de tocar em qualquer coisa. Não é idempotente/retomável como o install/ —
# é um fluxo linear único, pra uma máquina nova.
set -euo pipefail

DNA_REPO_ROOT="/root/dna"
# shellcheck source=../install/lib/common.sh
source "$DNA_REPO_ROOT/install/lib/common.sh"

banner
box "Bem-vindo ao instalador DNA" "" \
  "Vou instalar Arch Linux + niri + DankMaterialShell no disco que você" \
  "escolher a seguir." "" \
  "⚠ TODOS OS DADOS no disco escolhido serão APAGADOS." "" \
  "Ctrl+C a qualquer momento cancela antes da confirmação final."
confirm "Quer continuar?" || { log_warn "Cancelado."; exit 0; }

# --- 1. Escolher disco (excluindo a mídia de boot) --------------------------
BOOT_SRC="$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null || true)"
BOOT_DISK=""
if [ -n "$BOOT_SRC" ]; then
  BOOT_DISK="/dev/$(lsblk -no PKNAME "$BOOT_SRC" 2>/dev/null || true)"
fi

mapfile -t DISK_LINES < <(lsblk -dpno NAME,SIZE,MODEL | grep -E '^/dev/(sd|nvme|vd|mmcblk)')
if [ -n "$BOOT_DISK" ]; then
  mapfile -t DISK_LINES < <(printf '%s\n' "${DISK_LINES[@]}" | grep -v "^${BOOT_DISK} ")
fi
[ ${#DISK_LINES[@]} -gt 0 ] || { log_err "Nenhum disco encontrado (além da mídia de boot)."; exit 1; }

TARGET_LINE="$(printf '%s\n' "${DISK_LINES[@]}" | gum choose --header 'Disco de destino (TUDO nele será apagado)')"
[ -n "$TARGET_LINE" ] || { log_warn "Cancelado."; exit 0; }
TARGET="$(awk '{print $1}' <<<"$TARGET_LINE")"

error_box "⚠ ÚLTIMA CHANCE" "" "Vou apagar TUDO em $TARGET e particionar do zero." "" \
  "Digite o caminho exato do disco pra confirmar (ex.: $TARGET):"
typed="$(gum input --placeholder "$TARGET")"
[ "$typed" = "$TARGET" ] || { log_err "Não bateu com '$TARGET' — cancelado por segurança."; exit 1; }

# nomes de partição: /dev/sda1 vs /dev/nvme0n1p1
ESP="${TARGET}1"; ROOT="${TARGET}2"
case "$TARGET" in
  *nvme*|*mmcblk*) ESP="${TARGET}p1"; ROOT="${TARGET}p2" ;;
esac

# --- 2. GPU mode + hostname/usuário (perguntado aqui, repassado pro install.sh) --
GPU_MODE="$(choose_one 'Modo de GPU (offload = PRIME, recomendado)' offload dgpu)"
HOSTNAME_IN="$(gum input --placeholder 'lunar' --header 'Hostname da máquina')"
DNA_HOSTNAME="${HOSTNAME_IN:-lunar}"
USERNAME="$(gum input --placeholder 'ianptkcs' --header 'Nome de usuário')"
[ -n "$USERNAME" ] || { log_err "Usuário não pode ser vazio."; exit 1; }
USERPASS1="$(gum input --password --header "Senha de $USERNAME")"
USERPASS2="$(gum input --password --header 'Confirme a senha')"
[ -n "$USERPASS1" ] && [ "$USERPASS1" = "$USERPASS2" ] || { log_err "Senhas de usuário vazias ou não batem."; exit 1; }

LUKS_PASS1="$(gum input --password --header 'Senha de criptografia do disco (LUKS)')"
LUKS_PASS2="$(gum input --password --header 'Confirme a senha de criptografia')"
[ -n "$LUKS_PASS1" ] && [ "$LUKS_PASS1" = "$LUKS_PASS2" ] || { log_err "Senhas de criptografia vazias ou não batem."; exit 1; }

# --- 3. Particionar (GPT: ESP 1GiB + LUKS2 root no resto) -------------------
box "Particionando $TARGET" "" "ESP 1GiB (fat32) + root LUKS2 (resto do disco)"
sgdisk --zap-all "$TARGET"
sgdisk -n1:0:+1GiB -t1:ef00 -c1:ESP "$TARGET"
sgdisk -n2:0:0     -t2:8309 -c2:cryptroot "$TARGET"
partprobe "$TARGET"
sleep 2

mkfs.fat -F32 -n ESP "$ESP"

printf '%s' "$LUKS_PASS1" | cryptsetup luksFormat --type luks2 --batch-mode "$ROOT" -d -
printf '%s' "$LUKS_PASS1" | cryptsetup open "$ROOT" cryptroot -d -
unset LUKS_PASS1 LUKS_PASS2

mkfs.ext4 -F -L root /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot
mount "$ESP" /mnt/boot

# --- 4. pacstrap (base do Arch) ----------------------------------------------
box "Instalando o Arch base (pacstrap) — isso demora um pouco"
BASE_PKGS=(base base-devel linux linux-firmware linux-lts linux-lts-headers linux-headers
           sudo networkmanager grub efibootmgr cryptsetup git fish)
pacstrap -K /mnt "${BASE_PKGS[@]}"
genfstab -U /mnt >> /mnt/etc/fstab

# --- 5. hostname / locale / usuário ------------------------------------------
echo "$DNA_HOSTNAME" > /mnt/etc/hostname
arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
arch-chroot /mnt hwclock --systohc
printf 'en_US.UTF-8 UTF-8\npt_BR.UTF-8 UTF-8\n' >> /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=br-abnt2" > /mnt/etc/vconsole.conf

arch-chroot /mnt useradd -m -G wheel -s /usr/bin/fish "$USERNAME"
printf '%s:%s\n' "$USERNAME" "$USERPASS1" | arch-chroot /mnt chpasswd
arch-chroot /mnt passwd -l root
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /mnt/etc/sudoers
unset USERPASS1 USERPASS2

# --- 6. mkinitcpio (hook encrypt) + GRUB (cryptdevice) -----------------------
ROOT_UUID="$(blkid -s UUID -o value "$ROOT")"
sed -i -E 's/^HOOKS=\((.*)\bfilesystems\b(.*)\)/HOOKS=(\1encrypt filesystems\2)/' /mnt/etc/mkinitcpio.conf
arch-chroot /mnt mkinitcpio -P

arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=DNA
sed -i "s#^GRUB_CMDLINE_LINUX=\"\"#GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${ROOT_UUID}:cryptroot root=/dev/mapper/cryptroot\"#" /mnt/etc/default/grub
echo 'GRUB_ENABLE_CRYPTODISK=y' >> /mnt/etc/default/grub
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

arch-chroot /mnt systemctl enable NetworkManager

# --- 7. copiar o repo dna pro usuário e rodar o install/install.sh -----------
cp -r "$DNA_REPO_ROOT" "/mnt/home/$USERNAME/dna"
arch-chroot /mnt chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/dna"

if [ "${DNA_TEST_SKIP_INSTALL:-0}" = "1" ]; then
  log_warn "DNA_TEST_SKIP_INSTALL=1 — pulando install/install.sh (só teste de disco/boot)."
else
  box "Base do Arch pronta. Rodando o instalador DNA (pacotes/niri/dank/etc) —" \
    "vai pedir a senha do $USERNAME pro sudo."
  arch-chroot /mnt runuser -u "$USERNAME" -- bash -lc \
    "cd /home/$USERNAME/dna/install && ./install.sh --yes --gpu-mode=$GPU_MODE"
fi

# --- 8. desmontar e reiniciar -------------------------------------------------
umount -R /mnt
cryptsetup close cryptroot

box "Instalação concluída! 🎉" "" "Remova o pendrive antes de reiniciar."
if confirm "Reiniciar agora?"; then
  reboot
fi
