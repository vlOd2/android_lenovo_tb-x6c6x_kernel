#!/bin/bash
set -e

TC_DIR="toolchain"
GCC_TC_BRANCH="pie-gsi"
GCC_TC_DIR="gcc-${GCC_TC_BRANCH}"

export PATH="$PWD/../../kernel-4.19/${TC_DIR}/${GCC_TC_DIR}/bin:${PATH}"

rm init || true
rm ramdisk.cpio || true

aarch64-linux-android-gcc -nostdlib \
	init.c -o init

cat cpio.list | cpio -ov > ramdisk.cpio