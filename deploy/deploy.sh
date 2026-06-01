#!/bin/bash
set -euo pipefail

echo "- DEPLOY: Cleaning"
sudo rm boot/new_boot.img || true
sudo rm vendor/new_vendor.img || true

echo "- DEPLOY: Building boot image"
./build-boot.sh

echo "- DEPLOY: Building vendor image"
sudo ./build-vendor.sh

echo "- DEPLOY: Moving"
sudo chown $UID:$UID vendor/new_vendor.img
cp boot/new_boot.img .
cp vendor/new_vendor.img .