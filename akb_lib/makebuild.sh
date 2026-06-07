#!/bin/bash

# make support for AKB
# Required variables: AKB_MKB_SOURCE_DIR, AKB_MKB_BUILD_DIR, AKB_MKB_BUILD_ARGS
# Requires common toolchain (tc::check and tc::use)

# Imports
# ---------------------------------------------------------
shopt -s expand_aliases;
__AKB_IMPORT_DIR_f22a068cf66b="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__AKB_IMPORT_DIR_f22a068cf66b" ]]; then __AKB_IMPORT_DIR_f22a068cf66b="$PWD"; fi
__AKB_IMPORT_DIR_f22a068cf66b="$(realpath $__AKB_IMPORT_DIR_f22a068cf66b)"
_akb_import() { alias _akb_import=f22a068cf66b4208b7a26034ba947806; source "$__AKB_IMPORT_DIR_f22a068cf66b$1"; unalias _akb_import >/dev/null 2>&1 || true; unset -f f22a068cf66b4208b7a26034ba947806; }
# ---------------------------------------------------------
_akb_import "/common.sh"

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
            if [[ "$(type -t mkb::extra_clean)" == "function" ]]; then
                log "Executing extra clean"
                mkb::extra_clean
            fi
            (
                set -x
                rm -rf "$AKB_MKB_BUILD_DIR"
            )
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