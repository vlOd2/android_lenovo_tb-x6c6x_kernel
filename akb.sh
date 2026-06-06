#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

__SRC_DIR="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__SRC_DIR" ]]; then __SRC_DIR="$PWD"; fi
source "$__SRC_DIR/akb_env.sh"
source "$__SRC_DIR/akb_lib/common.sh"
source "$__SRC_DIR/akb_lib/toolchain.sh"
source "$__SRC_DIR/akb_lib/makebuild.sh"

akb::init

function pre_action {
    tc::check
    tc::download
    tc::version
}

case "${1:-}" in
    config)
        pre_action
        mkb::run "P98928AA1_defconfig" "serversetup.config"
        ;;

    build)
        pre_action
        mkb::run "-j$(nproc)"
        mkdir -p "$AKB_MKB_BUILD_DIR/modules"
        mkb::run "INSTALL_MOD_PATH=modules" "modules_install" "-j$(nproc)"
        ;;

    clean)
        pre_action
        mkb::clean
        ;;

    tc)
        pre_action
        ;;

    run)
        pre_action

        args=(${@:2})

        if [[ -z "${AKB_ALLOW_EMPTY_RUN:-}" && "${#args[@]}" -eq 0 ]]; then
            echo "No valid make command specified"
            echo "Either set AKB_ALLOW_EMPTY_RUN to 1 or pass a valid make comamnd"
            echo "Example: $0 run help"
            exit 1
        fi
        
        mkb::run "${args[@]}"
        ;;

    *)
        echo "Usage: $0 {config|build|clean|tc|run}"
        exit 1
        ;;
esac
