#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

PAD_REPO="https://github.com/tchebb/parse-android-dynparts"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function download_repo {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Cloning $PAD_REPO"
    git clone --depth=1 "$PAD_REPO" "src"
    patch -d "src" -p1 < *.patch
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath src)/build"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR"
    AKB_MKB_BUILD_ARGS=(
        "__AKB_DUMMY=1" # todo: currently AKB_MKB_BUILD_ARGS cannot be empty
    )

    _akb_import "/../akb_lib/makebuild.sh"

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                mkb::clean
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_dmsetup {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/sbin/dmsetup" ]]; then
        log "dmsetup already exists in the bootfs, pass build explicitly to continue" "warn"
        return 0
    fi

    if [[ ! -d "$AKB_CB_TOOLS_DIR/openssl/build" ]]; then
        log "You must first build OpenSSL before dmsetup" "error"
        return 1
    fi

    download_repo
    tc::use

    if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
        log "Configuring dmsetup"
        mkdir -p "$AKB_MKB_SOURCE_DIR"
        pushd "$AKB_MKB_SOURCE_DIR"

        (
            set -x
            cmake .. \
                -DCMAKE_TOOLCHAIN_FILE="$AKB_ROOT_DIR/tc_aarch64-musl.cmake" \
                -DOPENSSL_ROOT_DIR="$AKB_CB_TOOLS_DIR/openssl/build" \
                -DOPENSSL_INCLUDE_DIR="$AKB_CB_TOOLS_DIR/openssl/build/include" \
                -DOPENSSL_CRYPTO_LIBRARY="$AKB_CB_TOOLS_DIR/openssl/build/lib/libcrypto.a"
        )

        popd
    else
        log "Skipping dmsetup configuration: already configured" "warn"
    fi

    mkb::run "-j$(nproc)"

    log "Copying built dmsetup"
    cp "$AKB_MKB_BUILD_DIR/parse-android-dynparts" "$AKB_CB_OUT_BOOFS_DIR/sbin/dmsetup"
}