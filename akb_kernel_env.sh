#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Kernel specific AKB environment

AKB_ROOT_DIR="$(dirname $BASH_SOURCE)"
if [[ ! -d "$AKB_ROOT_DIR" ]]; then AKB_ROOT_DIR="$PWD"; fi
AKB_ROOT_DIR="$(realpath $AKB_ROOT_DIR)"

AKB_KERNEL_TC_DIR="$AKB_ROOT_DIR/kernel_tc"

AKB_MKB_SOURCE_DIR="$AKB_ROOT_DIR/kernel-4.19"
AKB_MKB_BUILD_DIR="$AKB_ROOT_DIR/kernel_build"
AKB_MKB_BUILD_ARGS=(
    "ARCH=arm64"
    "CROSS_COMPILE=aarch64-linux-android-"
    "CLANG_TRIPLE=aarch64-linux-gnu-"
    "O=$AKB_MKB_BUILD_DIR"

    "CC=clang"
    "NM=llvm-nm"
    "OBJCOPY=llvm-objcopy"
    
    "LD=ld.lld"
    "LD_LIBRARY_PATH=$AKB_KERNEL_TOOLCHAIN_DIR/clang/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
)