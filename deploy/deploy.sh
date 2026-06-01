#!/bin/bash
set -euo pipefail

echo "- DEPLOY: Building boot image"
./build-boot.sh

echo "- DEPLOY: Building vendor image"
sudo ./build-vendor.sh

echo "- DEPLOY: Moving"
mv boot/new_boot.img .
mv vendor/new_vendor.img .