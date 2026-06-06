#!/bin/bash

# make support for AKB
# Required variables: AKB_MKB_SOURCE_DIR, AKB_MKB_BUILD_DIR, AKB_MKB_BUILD_ARGS
# Requires common toolchain (tc::check and tc::use)

__BD_SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__BD_SRC_DIR" ]]; then __BD_SRC_DIR="$PWD"; fi
source "$__BD_SRC_DIR/common.sh"

function _mkb::check {
    local invalid_config=0

    if [[ -z "${AKB_MKB_SOURCE_DIR:-}" || ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
        log "AKB_MKB_SOURCE_DIR is not a valid directory" "error"
        invalid_config=1
    fi

    if [[ -z "${AKB_MKB_BUILD_DIR:-}" ]]; then
        log "AKB_MKB_BUILD_DIR is not a valid path" "error"
        invalid_config=1
    fi

    if [[ -z "${AKB_MKB_BUILD_ARGS:-}" ]]; then
        log "AKB_MKB_BUILD_ARGS is not set" "error"
        invalid_config=1
    fi

    if [[ "$(type -t tc::check)" != "function" ]]; then
        log "tc::check is not defined (did you forget the toolchain?)" "error"
        invalid_config=1
    fi

    if [[ "$(type -t tc::use)" != "function" ]]; then
        log "tc::use is not defined (did you forget the toolchain?)" "error"
        invalid_config=1
    fi

    if [[ $invalid_config -eq 1 ]]; then
        log "AKB makebuild configuration is invalid" "error"
        exit 1
    fi

    tc::check
}

function mkb::clean {
    _mkb::check

    if [[ ! -d "$AKB_MKB_BUILD_DIR" ]]; then
        log "Build folder does not exist" "warn"
        exit 1
    fi

    log "Build folder: $AKB_MKB_BUILD_DIR"
    read -p "Clean and delete the build folder? [y/N] " delete_prompt

    case "$delete_prompt" in
        [yY])
            mkb::run "mrproper"
            set -x
            rm -rf "$AKB_MKB_BUILD_DIR"
            set +x
            ;;

        *)
            log "Clean cancelled" "warn"
            ;;
    esac
}

function mkb::run {
    _mkb::check
    tc::use

    local build_args_dump=$(printf '%s ' "${AKB_MKB_BUILD_ARGS[@]}")
    local make_action_dump=$(printf '%s ' "$@") 
    log "Make options: $build_args_dump"
    log "Running make $make_action_dump"

    local start_time=$EPOCHSECONDS
    mkdir -p "$AKB_MKB_BUILD_DIR"
    pushd "$AKB_MKB_SOURCE_DIR" &>/dev/null

    set +e
    make "${AKB_MKB_BUILD_ARGS[@]}" "$@"
    local exit_code=$?
    set -e

    popd &>/dev/null
    local exec_time=$((EPOCHSECONDS-start_time))

    if [[ $exit_code -eq 0 ]]; then
        log "MAKE COMPLETE IN ${exec_time}s"
    else
        log "MAKE FAILED ($exit_code) IN ${exec_time}s" "error"
    fi

    return $exit_code
}