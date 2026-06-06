#!/bin/bash

# Kernel specific AKB toolchain implementation

__TC_SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__TC_SRC_DIR" ]]; then __TC_SRC_DIR="$PWD"; fi
source "$__TC_SRC_DIR/akb_lib/common.sh"

function _ktc::download_gcc {
    local GCC_TC_BRANCH="pie-gsi"
    local GCC_TC_URL="https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
    log "Downloading gcc ($GCC_TC_BRANCH)"
    git clone --depth 1 -b "$GCC_TC_BRANCH" "$GCC_TC_URL" "gcc"
}

function _ktc::download_clang {
    local CLANG_TC_BRANCH="android11-gsi"
    local CLANG_TC_REV="clang-r383902"
    local CLANG_TC_URL="https://android.googlesource.com/platform//prebuilts/clang/host/linux-x86"
    log "Downloading clang ($CLANG_TC_BRANCH $CLANG_TC_REV)"

    git clone \
        --no-checkout --sparse --filter=tree:0 --depth=1 --single-branch \
        -b "$CLANG_TC_BRANCH" "$CLANG_TC_URL" "_clang"
    git -C "_clang" sparse-checkout set --no-cone "/$CLANG_TC_REV"
    git -C "_clang" checkout --progress --force

    mv "_clang/$CLANG_TC_REV" "clang"
    rm -rf "_clang"
}

# Common toolchain function
function tc::check {
    if [[ -z "${AKB_KERNEL_TC_DIR:-}" ]]; then
        log "AKB_KERNEL_TC_DIR is not a valid path" "error"
        exit 1
    fi

    if ! command -v "git" &>/dev/null; then
        log "Could not find git executable" "error"
        exit 1
    fi
}

function ktc::download {
    tc::check

    if [[ -d "$AKB_KERNEL_TC_DIR" && -d "$AKB_KERNEL_TC_DIR/clang" && -d "$AKB_KERNEL_TC_DIR/gcc" ]]; then
        return 0
    fi
    log "Downloading toolchain"

    mkdir -p "$AKB_KERNEL_TC_DIR"
    pushd "$AKB_KERNEL_TC_DIR" &>/dev/null

    _ktc::download_gcc
    _ktc::download_clang

    popd &>/dev/null
}

function ktc::version {
    tc::check
    local clang_bin="$AKB_KERNEL_TC_DIR/clang/bin/clang"
    local gcc_bin="$AKB_KERNEL_TC_DIR/gcc/bin/aarch64-linux-android-gcc"
    local clang_version=$("$clang_bin" --version | grep -Po '(?<=clang version )(\w+?\.\w+?\.\w+)' | head -n1)
    local gcc_version=$("$gcc_bin" --version | grep -Po '(\w+?\.\w+?\.\w+)' | head -n1)
    log "Using clang version: $clang_version"
    log "Using gcc version: $gcc_version"
}

# Common toolchain function
function tc::use {
    tc::check
    export PATH="$AKB_KERNEL_TC_DIR/clang/bin:${PATH}"
    export PATH="$AKB_KERNEL_TC_DIR/gcc/bin:${PATH}"
}