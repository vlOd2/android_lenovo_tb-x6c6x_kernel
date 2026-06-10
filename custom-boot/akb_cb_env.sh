#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# custom-boot specific AKB environment

AKB_ROOT_DIR="$(akb::find_root_dir "${BASH_SOURCE[0]}")"

AKB_CB_TC_DIR="$AKB_ROOT_DIR/toolchain"
AKB_TC_SYSROOT_DIR="$AKB_CB_TC_DIR/aarch64-linux-musl"
AKB_TC_CC="aarch64-linux-musl-gcc"
AKB_TC_AR="aarch64-linux-musl-ar"
AKB_TC_NM="aarch64-linux-musl-nm"

AKB_CB_TOOLS_DIR="$AKB_ROOT_DIR/tools"

AKB_CB_BASE_DIR="$AKB_ROOT_DIR/base"
AKB_CB_BASE_BOOTFS_DIR="$AKB_CB_BASE_DIR/base_bootfs"
AKB_CB_BASE_IMG_DIR="$AKB_CB_BASE_DIR/base_img"

AKB_CB_OUT_DIR="$AKB_ROOT_DIR/out"
AKB_CB_OUT_BOOFS_DIR="$AKB_CB_OUT_DIR/bootfs"
AKB_CB_OUT_IMG_DIR="$AKB_CB_OUT_DIR/img"