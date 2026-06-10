#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

LVM_ARCHIVE="https://sourceware.org/pub/lvm2/LVM2.2.03.41.tgz"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function download_src {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Downloading $LVM_ARCHIVE"
    wget "$LVM_ARCHIVE" -O"lvm2.tar.gz"
    mkdir -p src
    tar -C "src" --strip-components=1 -xvf "lvm2.tar.gz"
    rm "lvm2.tar.gz"
}

# function mkb::extra_clean {
#     mkb::run "clean"
# }

function _sb_main {
AKB_MKB_SOURCE_DIR="$(realpath src)/build"
    AKB_MKB_BUILD_DIR="$AKB_MKB_SOURCE_DIR"
    AKB_MKB_BUILD_ARGS=(
        "CC=$AKB_TC_CC"
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
                echo "USAGE: tools_lvm {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    # if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/sbin/mkfs.ext4" ]]; then
    #     log "LVM2 already exists in the bootfs, pass build explicitly to continue" "warn"
    #     return 0
    # fi

    download_src
    tc::use

    if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
        log "Configuring LVM2"
        mkdir -p "$AKB_MKB_SOURCE_DIR"
        pushd "$AKB_MKB_SOURCE_DIR"

        (
            set -x
            ../configure \
                CC="$AKB_TC_CC" \
                CFLAGS="-static --sysroot=$AKB_TC_SYSROOT_DIR" \
                LDFLAGS="-static --sysroot=$AKB_TC_SYSROOT_DIR" \
                --host=aarch64-linux-musl \
                --enable-static_link \
                --disable-udev \
                --disable-selinux \
                --disable-readline \
                --disable-aio \
                --disable-bcache \
                --disable-vdo \
                --disable-cmdlib \
                --disable-dmeventd
        )

        popd
    else
        log "Skipping LVM2 configuration: already configured" "warn"
    fi

    mkb::run "device-mapper" "-j$(nproc)"
}