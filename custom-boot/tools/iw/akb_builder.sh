#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

IW_ARCHIVE="https://www.kernel.org/pub/software/network/iw/iw-6.17.tar.xz"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

IW_LOGS="$(realpath .)/build.log"

function download_src {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Downloading $IW_ARCHIVE"
    wget "$IW_ARCHIVE" -O"iw.tar.xz" &>>$IW_LOGS
    mkdir -p src
    tar -C "src" --strip-components=1 -xvf "iw.tar.xz" &>>$IW_LOGS
    rm "iw.tar.xz"
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath src)"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR"
    AKB_MKB_BUILD_ARGS=(
        "CC=$AKB_TC_CC"
        "CCFLAGS=-I$AKB_CB_TOOLS_DIR/libnl/src/build/include"
        "LDFLAGS=-static -L$AKB_CB_TOOLS_DIR/libnl/src/build/lib"
    )

    _akb_import "/../akb_lib/makebuild.sh"
    echo -n > $IW_LOGS

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
                    log "Source directory not found, cannot run clean" "error"
                    return 1
                fi
                
                read -p "Run clean? [y/N] " clean_prompt

                case "$clean_prompt" in
                    [yY])
                        mkb::run "clean"
                        return 0
                        ;;

                    *)
                        log "Clean cancelled" "warn"
                        ;;
                esac
                
                return 1
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_iw {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/sbin/iw" ]]; then
        log "iw already exists in the bootfs, pass build explicitly to continue" "warn"
        return 0
    fi

    if [[ ! -d "$AKB_CB_TOOLS_DIR/libnl/src/build" ]]; then
        log "You must first build libnl before iw" "error"
        return 1
    fi

    download_src
    tc::use

    mkb::run "-j$(nproc)" 
    (
        set -x
        "$AKB_TC_PREFIX-strip" "$AKB_MKB_BUILD_DIR/iw"
    )

    log "Copying built iw"
    cp "$AKB_MKB_BUILD_DIR/iw" "$AKB_CB_OUT_BOOFS_DIR/sbin/iw"
}
