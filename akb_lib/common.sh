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
    if [[ $# -eq 0 || -z "$1" ]]; then
        log "USAGE: akb::invoke_builder [path]" "error"
        return 1
    fi
    local builder_path=$(realpath "$1")

    if [[ -z "$builder_path" || ! -f "$builder_path" ]]; then
        log "Cannot find AKB builder: $1" "error"
        return 1
    fi

    if [[ "$(trimstring "$(head -n1 "$builder_path")")" != "$_AKB_BUILDER_HEADER" ]]; then
        log "AKB builder has invalid signature: $builder_path" "error"
        return 1
    fi

    log "Invoking AKB builder: $builder_path"
    local builder_dir="${builder_path%/*}"

    pushd "$builder_dir"
    (
        __AKB_BUILDER=1
        source $builder_path
        if [[ "$(type -t _sb_main)" != "function" ]]; then
            log "AKB builder has no main function: $builder_path" "error"
            exit 1
        fi
        _sb_main
    )
    popd
}

function akb::find_root_dir {
    local root_dir="$(dirname $1)"
    if [[ ! -d "$root_dir" ]]; then 
        root_dir="$PWD"
    fi
    root_dir="$(realpath $root_dir)"
    echo "$root_dir"
}