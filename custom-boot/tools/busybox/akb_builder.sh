#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

BUSYBOX_ARCHIVE="https://busybox.net/downloads/busybox-1.38.0.tar.bz2"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function download_src {
    if [[ -d "bbsrc" ]]; then
        return 0
    fi
    log "Downloading $BUSYBOX_ARCHIVE"
    wget "$BUSYBOX_ARCHIVE" -O"bbsrc.tar.bz2"
    mkdir -p bbsrc
    tar -C "bbsrc" --strip-components=1 -xvf "bbsrc.tar.bz2"
    rm bbsrc.tar.bz2
}

function mkb::extra_clean {
    mkb::run "mrproper"
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath bbsrc)"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR/out"
    AKB_MKB_BUILD_ARGS=(
        "O=$AKB_MKB_BUILD_DIR"
    )

    _akb_import "/../akb_lib/makebuild.sh"

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -d "$AKB_MKB_SOURCE_DIR" || ! -d "$AKB_MKB_BUILD_DIR" ]]; then
                    log "Cannot clean busybox: not downloaded or built" "warn"
                    return 0
                fi
                log "Cleaning busybox does not restore the bootfs" "warn"
                mkb::clean
                return 0
                ;;
            
            build)
                ;;

            *)
                echo "USAGE: tools_bb {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/bin/busybox" ]]; then
        log "Busybox already exists in the bootfs, pass build explicitly to continue" "warn"
        return 0
    fi

    download_src

    # toolchain is specified by the config

    if [[ ! -e "$AKB_MKB_BUILD_DIR/.config" ]]; then
        mkb::run "defconfig"
        cp "./busybox.config" "$AKB_MKB_BUILD_DIR/.config"
        mkb::run "oldconfig"
    else
        log "Skipping busybox configuration: already configured" "warn"
    fi

    mkb::run "-j$(nproc)"
    mkb::run "CONFIG_PREFIX=$AKB_CB_OUT_BOOFS_DIR" "install"
}