#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

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
    local invalid_config=0

    if [[ -z "${AKB_ROOT_DIR:-}" || ! -d "$AKB_ROOT_DIR" ]]; then
        log "AKB_ROOT_DIR is not a valid directory" "error"
        invalid_config=1
    fi

    if [[ -z "${AKB_SOURCE_DIR:-}" || ! -d "$AKB_SOURCE_DIR" ]]; then
        log "AKB_SOURCE_DIR is not a valid directory" "error"
        invalid_config=1
    fi

    if [[ -z "${AKB_BUILD_DIR:-}" ]]; then
        log "AKB_BUILD_DIR is not a valid path" "error"
        invalid_config=1
    fi

    if [[ -z "${AKB_BUILD_ARGS:-}" ]]; then
        log "AKB_BUILD_ARGS is not set" "error"
        invalid_config=1
    fi

    if [[ $invalid_config -eq 1 ]]; then
        log "AKB configuration is invalid" "error"
        exit 1
    fi
}