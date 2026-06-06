#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

_AKB_BUILDER_HEADER="#AKB_BUILDER"

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

function trimstring {
    if [[ $# -eq 0 ]]; then
        log "USAGE: trimstring [string]" "error"
        return 1
    fi

    local s="$1"
    local size_before=${#s}
    local size_after=0

    while [[ ${size_before} -ne ${size_after} ]]; do
        size_before=${#s}
        s="${s#[[:space:]]}"
        s="${s%[[:space:]]}"
        size_after=${#s}
    done

    echo "$s"
}

function akb::init {
    local invalid_config=0

    if [[ -z "${AKB_ROOT_DIR:-}" || ! -d "$AKB_ROOT_DIR" ]]; then
        log "AKB_ROOT_DIR is not a valid directory" "error"
        invalid_config=1
    fi

    if [[ $invalid_config -eq 1 ]]; then
        log "AKB configuration is invalid" "error"
        exit 1
    fi
}

function akb::invoke_builder() {
    if [[ $# -eq 0 ]]; then
        log "USAGE: akb::invoke_builder [path]" "error"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        log "Cannot find AKB builder: ${1:-(empty)}" "error"
        return 1
    fi

    if [[ "$(trimstring "$(head -n1 "$1")")" != "$_AKB_BUILDER_HEADER" ]]; then
        log "AKB builder has invalid signature: $1" "error"
        return 1
    fi

    log "Invoking AKB builder: $1"

    (
        __AKB_BUILDER=1
        source $1
        if [[ "$(type -t _sb_main)" != "function" ]]; then
            log "AKB builder has no main function: $1 _sb_main" "error"
            exit 1
        fi
        _sb_main
    )
}