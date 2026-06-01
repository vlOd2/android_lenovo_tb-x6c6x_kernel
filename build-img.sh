#!/bin/bash
set -e

mkdir -p boot
#cp stock-boot.img boot/boot.img
cp magisk-boot.img boot/boot.img
cd boot
magiskboot unpack boot.img -h
cp ../kernel-4.19/out/arch/arm64/boot/Image .
rm kernel
mv Image kernel
#magiskboot repack boot.img
