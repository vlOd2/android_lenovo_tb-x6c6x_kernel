#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

AKB_ROOT_DIR="$(dirname $BASH_SOURCE)"
if [[ ! -d "$AKB_ROOT_DIR" ]]; then AKB_ROOT_DIR="$PWD"; fi
AKB_ROOT_DIR="$(realpath $AKB_ROOT_DIR/..)"

AKB_KERNEL_DIR="$AKB_ROOT_DIR/kernel-4.19"
AKB_BUILD_DIR="$AKB_ROOT_DIR/akb_build"
AKB_TOOLCHAIN_DIR="$AKB_ROOT_DIR/akb_toolchain"

function log {
    local e=$'\x1B'
    local l=""

    case "${2:-"info"}" in
        error)
            l+="$e[0;31m[ERROR] "
            ;;

        warn)
            l+="$e[0;33m[WARN] "
            ;;

        *)
            l+="$e[0;34m[INFO] "
            ;;
    esac

    l+="$1"
    l+="$e[0m"
    l+="\n"

    printf "$l"
}

function common::init {
    if [[ ! -d "$AKB_ROOT_DIR" ]]; then
        log "AKB_ROOT_DIR is not a valid directory" "error"
        log "AKB root directory is invalid" "error"
        exit 1
    fi

    if [[ ! -d "$AKB_KERNEL_DIR" ]]; then
        log "AKB_KERNEL_DIR is not a valid directory" "error"
        log "AKB root directory is invalid" "error"
        exit 1
    fi
}