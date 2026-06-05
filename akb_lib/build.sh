#!/bin/bash
__BD_SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__BD_SRC_DIR" ]]; then __BD_SRC_DIR="$PWD"; fi
source "$__BD_SRC_DIR/common.sh"
source "$__BD_SRC_DIR/toolchain.sh"

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
    local build_args=(
        "ARCH=arm64"
        "CROSS_COMPILE=aarch64-linux-android-"
        "CLANG_TRIPLE=aarch64-linux-gnu-"
        "O=$AKB_BUILD_DIR"

        "CC=clang"
        "NM=llvm-nm"
        "OBJCOPY=llvm-objcopy"
        
        "LD=ld.lld"
        "LD_LIBRARY_PATH=$AKB_TOOLCHAIN_DIR/clang/lib64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    )

    mkdir -p "$AKB_BUILD_DIR"
    tc::use

    local build_args_dump=$(printf '%s ' "${build_args[@]}")
    local make_action_dump=$(printf '%s ' "$@") 
    log "Make options: $build_args_dump"
    log "Running make $make_action_dump"

    local start_time=$EPOCHSECONDS
    pushd "$AKB_KERNEL_DIR" &>/dev/null

    set +e
    make "${build_args[@]}" "$@"
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