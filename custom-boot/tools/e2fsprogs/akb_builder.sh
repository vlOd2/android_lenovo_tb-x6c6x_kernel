#AKB_BUILDER
set -euo pipefail
IFS=$'\n\t'

E2FSPROGS_ARCHIVE="https://mirrors.edge.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.47.4/e2fsprogs-1.47.4.tar.gz"

if [[ -z "${__AKB_BUILDER:-}" ]]; then
    echo "error: this script cannot be invoked directly, only via the appropriate AKB build script"
    exit 1
fi

function download_src {
    if [[ -d "src" ]]; then
        return 0
    fi
    log "Downloading $E2FSPROGS_ARCHIVE"
    wget "$E2FSPROGS_ARCHIVE" -O"e2fsprogs.tar.gz"
    mkdir -p src
    tar -C "src" --strip-components=1 -xvf "e2fsprogs.tar.gz"
    rm "e2fsprogs.tar.gz"
}

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
                echo "USAGE: tools_e2fs {build/<none>|clean}"
                return 1
                ;;
        esac
    fi

    if [[ ($# -eq 0 || $1 != "build") && -e "$AKB_CB_OUT_BOOFS_DIR/sbin/mkfs.ext4" ]]; then
        log "e2fsprogs already exists in the bootfs, pass build explicitly to continue" "warn"
        return 0
    fi

    download_src
    tc::use

    if [[ ! -d "$AKB_MKB_SOURCE_DIR" ]]; then
        log "Configuring e2fsprogs"
        mkdir -p "$AKB_MKB_SOURCE_DIR"
        pushd "$AKB_MKB_SOURCE_DIR"

        (
            set -x
            ../configure \
                CC="$AKB_TC_CC" \
                CFLAGS="-O2 -static --sysroot=$AKB_TC_SYSROOT_DIR" \
                LDFLAGS="-static --sysroot=$AKB_TC_SYSROOT_DIR" \
                --host=aarch64-linux-musl \
                --disable-nls \
                --disable-elf-shlibs
        )

        popd
    else
        log "Skipping e2fsprogs configuration: already configured" "warn"
    fi

    mkb::run "-j$(nproc)"

    log "Copying built e2fsprogs"
    cp "$AKB_MKB_BUILD_DIR/misc/fsck" "$AKB_CB_OUT_BOOFS_DIR/sbin/fsck"
    cp "$AKB_MKB_BUILD_DIR/misc/mke2fs" "$AKB_CB_OUT_BOOFS_DIR/sbin/mke2fs"
    cp "$AKB_MKB_BUILD_DIR/misc/tune2fs" "$AKB_CB_OUT_BOOFS_DIR/sbin/tune2fs"
    cp "$AKB_MKB_BUILD_DIR/misc/dumpe2fs" "$AKB_CB_OUT_BOOFS_DIR/sbin/dumpe2fs"
    ln -sf fsck "$AKB_CB_OUT_BOOFS_DIR/sbin/fsck.ext4"
    ln -sf mke2fs "$AKB_CB_OUT_BOOFS_DIR/sbin/mkfs.ext4"
    ln -sf mke2fs "$AKB_CB_OUT_BOOFS_DIR/sbin/mkfs.ext3"
}