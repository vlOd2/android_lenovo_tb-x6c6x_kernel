#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

OPENSSL_REPO="https://github.com/openssl/openssl.git"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function download_repo {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Cloning $OPENSSL_REPO"
    git clone --depth=1 --branch "openssl-4.0.1" "$OPENSSL_REPO" "src"
}

function mkb::extra_clean {
    mkb::run "clean"
}

function _sb_main {
    AKB_MKB_SOURCE_DIR="$(realpath src)"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR/../build"
    AKB_MKB_BUILD_ARGS=(
        "CC=$AKB_TC_CC"
    )

    _akb_import "/../akb_lib/makebuild.sh"

    if [[ $# -gt 0 ]]; then
        case "$1" in
            clean)
                if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
                    log "Cannot clean OpenSSL: not downloaded or built" "warn"
                    return 0
                fi
                mkb::clean
                return 0
                ;;

            build)
                ;;

            *)
                echo "USAGE: tools_ossl {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -d "$AKB_MKB_BUILD_DIR" && -e "$AKB_MKB_BUILD_DIR/lib/libssl.a" ]]; then
        log "OpenSSL is already built" "warn"
        return 0
    fi

    download_repo
    tc::use

    log "Configuring OpenSSL"
    pushd "$AKB_MKB_SOURCE_DIR"

    (
        set -x
        ./Configure linux-aarch64 \
            no-shared \
            no-tests \
            no-apps \
            --cross-compile-prefix="$AKB_TC_PREFIX-" \
            --prefix="$AKB_MKB_BUILD_DIR"
    )

    popd

    mkb::run "-j$(nproc)"
    mkb::run "install_sw"
}