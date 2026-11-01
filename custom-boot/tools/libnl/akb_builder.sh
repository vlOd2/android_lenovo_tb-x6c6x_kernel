#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

LIBNL_ARCHIVE="https://github.com/thom311/libnl/releases/download/libnl3_12_0/libnl-3.12.0.tar.gz"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

LIBNL_LOGS="$(realpath .)/build.log"

function download_src {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Downloading $LIBNL_ARCHIVE"
    wget "$LIBNL_ARCHIVE" -O"libnl.tar.gz" &>>$LIBNL_LOGS
    mkdir -p src
    tar -C "src" --strip-components=1 -xvf "libnl.tar.gz" &>>$LIBNL_LOGS
    rm "libnl.tar.gz"
}

function mkb::extra_clean {
    mkb::run "distclean"
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath src)/build"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR"
    AKB_MKB_BUILD_ARGS=(
        "__AKB_DUMMY=1" # todo: currently AKB_MKB_BUILD_ARGS cannot be empty
    )

    _akb_import "/../akb_lib/makebuild.sh"
    echo -n > $LIBNL_LOGS

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                mkb::clean
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_lnl {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -d "$AKB_MKB_BUILD_DIR" && -e "$AKB_MKB_BUILD_DIR/lib/libnl-3.a" ]]; then
        log "libnl is already built" "warn"
        return 0
    fi

    download_src
    tc::use

    if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
        log "Configuring libnl"
        mkdir -p "$AKB_MKB_SOURCE_DIR"
        pushd "$AKB_MKB_SOURCE_DIR"

        (
            set -x
            ../configure \
                CC="$AKB_TC_CC" \
                --enable-static \
                --disable-debug \
                --disable-cli \
                --host="$AKB_TC_PREFIX" \
                --prefix="$AKB_MKB_BUILD_DIR" \
                &>>$LIBNL_LOGS
        )

        popd
    else
        log "Skipping libnl configuration: already configured" "warn"
    fi

    mkb::run "-j$(nproc)"
    mkb::run "install"
}