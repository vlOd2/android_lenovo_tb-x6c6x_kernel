#!/bin/bash

# custom-boot AKB toolchain implementation

# Imports
# ---------------------------------------------------------
shopt -s expand_aliases;
__AKB_IMPORT_DIR_20715f34ecc0="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__AKB_IMPORT_DIR_20715f34ecc0" ]]; then __AKB_IMPORT_DIR_20715f34ecc0="$PWD"; fi
__AKB_IMPORT_DIR_20715f34ecc0="$(realpath $__AKB_IMPORT_DIR_20715f34ecc0)"
_akb_import() { alias _akb_import=20715f34ecc0444bbc8b3dc53d2664a6; source "$__AKB_IMPORT_DIR_20715f34ecc0$1"; unalias _akb_import >/dev/null 2>&1 || true; unset -f 20715f34ecc0444bbc8b3dc53d2664a6; }
# ---------------------------------------------------------
_akb_import "/../akb_lib/common.sh"

function tc::check {
    if [[ -z "${AKB_CB_TC_DIR:-}" ]]; then
        log "AKB_CB_TC_DIR is not a valid path" "error"
        exit 1
    fi

    if [[ -z "${AKB_TC_CC:-}" ]]; then
        log "AKB_TC_CC is not set" "error"
        exit 1
    fi
}

function cbtc::download {
    local tc_archive="https://musl.cc/aarch64-linux-musl-cross.tgz"

    tc::check

    if [[ -d "$AKB_CB_TC_DIR" && -x "$AKB_CB_TC_DIR/bin/$AKB_TC_CC" ]]; then
        return 0
    fi

    log "Downloading toolchain: $tc_archive"
    wget "$tc_archive" -Otoolchain.tar.gz

    log "Extracting toolchain"
    mkdir -p "$AKB_CB_TC_DIR"
    tar -C "$AKB_CB_TC_DIR" --strip-components=1 -xvf "toolchain.tar.gz"
    rm toolchain.tar.gz
}

function cbtc::version {
    tc::check
    local gcc_bin="$AKB_CB_TC_DIR/bin/$AKB_TC_CC"
    local gcc_version=$("$gcc_bin" --version | grep -Po '(\w+?\.\w+?\.\w+)' | head -n1)
    log "Using gcc version: $gcc_version"
}

function tc::use {
    tc::check
    export PATH="$AKB_CB_TC_DIR/bin:$PATH"
}
