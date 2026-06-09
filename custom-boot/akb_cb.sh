#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Imports
# ---------------------------------------------------------
shopt -s expand_aliases;
__AKB_IMPORT_DIR_83f785c0fd26="$(dirname ${BASH_SOURCE[0]})"
if [[ ! -d "$__AKB_IMPORT_DIR_83f785c0fd26" ]]; then __AKB_IMPORT_DIR_83f785c0fd26="$PWD"; fi
__AKB_IMPORT_DIR_83f785c0fd26="$(realpath $__AKB_IMPORT_DIR_83f785c0fd26)"
_akb_import() { alias _akb_import=83f785c0fd26401184c0854cb5091f82; source "$__AKB_IMPORT_DIR_83f785c0fd26$1"; unalias _akb_import >/dev/null 2>&1 || true; unset -f 83f785c0fd26401184c0854cb5091f82; }
# ---------------------------------------------------------
_akb_import "/../akb_lib/common.sh"
_akb_import "/akb_cb_env.sh"
_akb_import "/akb_cb_tc.sh"

akb::init

function bfs::pre_build_action {
    if [[ ! -d "$AKB_CB_OUT_BOOFS_DIR" ]]; then
        log "Out bootfs folder not found, run initfs first" "error"
        exit 1
    fi

    tc::check
    cbtc::download
    cbtc::version
}

function bfs::copyfs {
    if [[ ! -d "$AKB_CB_BASE_BOOTFS_DIR" ]]; then
        log "Base bootfs not found: $AKB_CB_BASE_BOOTFS_DIR" "error"
        exit 1
    fi
    mkdir -p "$AKB_CB_OUT_BOOFS_DIR"
    cp -a "$AKB_CB_BASE_BOOTFS_DIR/"* "$AKB_CB_OUT_BOOFS_DIR/"
}

function bfs:___ {
    KERNEL_IMAGE="$PWD/../akb_build/arch/arm64/boot/Image"
    KERNEL_DTB="$PWD/../akb_build/arch/arm64/boot/dts/mediatek/mt6765.dtb"

    rm ramdisk.cpio.gz || true
    pushd bootfs
    find . -print0 2>/dev/null | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > ../ramdisk.cpio.gz 2>/dev/null
    popd

    pushd boot

    rm kernel || true
    rm dtb || true
    rm ramdisk.cpio || true
    rm new_boot.img || true
    cp "$KERNEL_IMAGE" kernel
    cp "$KERNEL_DTB" dtb
    mv ../ramdisk.cpio.gz ramdisk.cpio

    magiskboot repack boot.img new_boot.img

    popd

    fastboot flash boot ./boot/new_boot.img
    fastboot reboot
}

case "${1:-}" in
    init_fs)
        if [[ -d "$AKB_CB_OUT_BOOFS_DIR" ]]; then
            log "Out bootfs already exists, clean and try again, or use copyfs to recopy base" "error"
            exit 1
        fi
        bfs::copyfs
        pushd "$AKB_CB_OUT_BOOFS_DIR" &>/dev/null
        mkdir -p dev proc sys etc root mnt
        popd &>/dev/null
        log "Initialised bootfs"
        ;;

    copy_fs)
        bfs::copyfs
        log "Copied base bootfs"
        ;;

    copy_img)
        if [[ ! -d "$AKB_CB_BASE_IMG_DIR" ]]; then
            log "Base image not found: $AKB_CB_BASE_IMG_DIR" "error"
            exit 1
        fi
        mkdir -p "$AKB_CB_OUT_IMG_DIR"
        cp -a "$AKB_CB_BASE_IMG_DIR/"* "$AKB_CB_OUT_IMG_DIR/"
        log "Copied base image"
        ;;

    clean_out)
        if [[ ! -d "$AKB_CB_OUT_DIR" ]]; then
            log "Out folder does not exist" "warn"
            exit 1
        fi

        log "Out folder: $AKB_CB_OUT_DIR"
        read -p "Delete the out folder? [y/N] " delete_prompt

        case "$delete_prompt" in
            [yY])
                (
                    set -x
                    rm -rf "$AKB_CB_OUT_DIR"
                )
                ;;

            *)
                log "Clean cancelled" "warn"
                ;;
        esac
        ;;

    tc)
        bfs::pre_build_action
        ;;

    all_tools)
        bfs::pre_build_action
        log "Building busybox"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/busybox/akb_builder.sh"
        log "Building rebooter"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/rebooter/akb_builder.sh"
        ;;

    clean_tools)
        log "STUB: Not implemented" "warn"
        ;;

    tools_bb)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/busybox/akb_builder.sh"
        ;;

    tools_rb)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/rebooter/akb_builder.sh"
        ;;

    *)
        echo "Usage: $0 {init_fs|copy_fs|copy_img|clean_out|tc|all_tools|clean_tools|tools_bb|tools_rb}"
        exit 1
        ;;
esac
