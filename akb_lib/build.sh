#!/bin/bash
__BD_SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__BD_SRC_DIR" ]]; then __BD_SRC_DIR="$PWD"; fi
source "$__BD_SRC_DIR/common.sh"

function build::clean {
    if [[ ! -d "$AKB_BUILD_DIR" ]]; then
        log "Build folder does not exist" "warn"
        exit 1
    fi

    log "Build folder: $AKB_BUILD_DIR"
    read -p "Clean and delete the build folder? [y/N] " delete_prompt

    case "$delete_prompt" in
        [yY])
            build::run "mrproper"
            set -x
            rm -rf "$AKB_BUILD_DIR"
            set +x
            ;;

        *)
            log "Clean cancelled" "warn"
            ;;
    esac
}

function build::run {
    mkdir -p "$AKB_BUILD_DIR"
    tc::use

    local build_args_dump=$(printf '%s ' "${AKB_BUILD_ARGS[@]}")
    local make_action_dump=$(printf '%s ' "$@") 
    log "Make options: $build_args_dump"
    log "Running make $make_action_dump"

    local start_time=$EPOCHSECONDS
    pushd "$AKB_SOURCE_DIR" &>/dev/null

    set +e
    make "${AKB_BUILD_ARGS[@]}" "$@"
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