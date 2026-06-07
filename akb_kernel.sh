#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Android kernel specific AKB root builder

# Imports
# ---------------------------------------------------------
shopt -s expand_aliases;
__AKB_IMPORT_DIR_d036f081c960="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__AKB_IMPORT_DIR_d036f081c960" ]]; then __AKB_IMPORT_DIR_d036f081c960="$PWD"; fi
__AKB_IMPORT_DIR_d036f081c960="$(realpath $__AKB_IMPORT_DIR_d036f081c960)"
_akb_import() { alias _akb_import=d036f081c960434aaa7c1268de2b43b2; source "$__AKB_IMPORT_DIR_d036f081c960$1"; unalias _akb_import >/dev/null 2>&1 || true; unset -f d036f081c960434aaa7c1268de2b43b2; }
# ---------------------------------------------------------
_akb_import "/akb_lib/common.sh"
_akb_import "/akb_kernel_env.sh"
_akb_import "/akb_kernel_tc.sh"
_akb_import "/akb_lib/makebuild.sh"

akb::init

function pre_action {
    tc::check
    ktc::download
    ktc::version
}

function mkb::extra_clean {
    mkb::run "mrproper"
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
