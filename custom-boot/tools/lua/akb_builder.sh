#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

LUA_ARCHIVE="https://www.lua.org/ftp/lua-5.5.1.tar.gz"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function download_src {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Downloading $LUA_ARCHIVE"
    wget "$LUA_ARCHIVE" -O"lua.tar.gz"
    mkdir -p src
    tar -C "src" --strip-components=1 -xvf "lua.tar.gz"
    rm "lua.tar.gz"
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath src)"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR/__dummy_dir__"
    AKB_MKB_BUILD_ARGS=(
        "CC=$AKB_TC_CC"
        "AR=$AKB_TC_PREFIX-ar rc"
        "RANLIB=$AKB_TC_PREFIX-ranlib"
        "MYLDFLAGS=-static"
    )

    _akb_import "/../akb_lib/makebuild.sh"

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                mkb::run "clean"
                rmdir "$AKB_MKB_BUILD_DIR"
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_lua {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/bin/lua" ]]; then
        log "Lua already exists in the bootfs, pass build explicitly to continue" "warn"
        return 0
    fi

    download_src
    tc::use

    mkb::run "posix" "-j$(nproc)"
    (
        set -x
        "$AKB_TC_PREFIX-strip" "$AKB_MKB_SOURCE_DIR/src/lua"
    )

    log "Copying built Lua"
    cp "$AKB_MKB_SOURCE_DIR/src/lua" "$AKB_CB_OUT_BOOFS_DIR/bin/lua"
}