#!/bin/bash
set -euo pipefail

BOOT_IMAGE="base/boot.img"
KERNEL_IMAGE="$PWD/../akb_build/arch/arm64/boot/Image"

EXTRA_BOOT_OPTS=(
	"log_buf_len=4M"
	"printk.devkmsg=on"
	"earlycon=simplefb,0x7dce0000,1200,1920"
	"keep_bootcon"
	"androidboot.selinux=permissive"
)

echo "- BOOT: Preparing"
mkdir -p boot
cp "$BOOT_IMAGE" boot/boot.img
cd boot

echo "- BOOT: Unpacking"
magiskboot unpack boot.img -h

echo "- BOOT: Patching"
rm kernel
cp "$KERNEL_IMAGE" kernel
sed -i "/^cmdline=/ s/\$/ ${EXTRA_BOOT_OPTS[*]} /" header

echo "- BOOT: Repacking"
magiskboot repack boot.img new_boot.img