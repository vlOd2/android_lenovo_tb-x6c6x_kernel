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

function bfs::build_img {
    if ! command -v "magiskboot" >/dev/null 2>&1; then
        log "magiskboot not found, make sure its in your PATH and try again" "error"
        exit 1
    fi
    
    if [[ ! -d "$AKB_CB_OUT_DIR" || ! -d "$AKB_CB_OUT_BOOFS_DIR" ]]; then
        log "Out bootfs does not exist, run init_fs and all_tools then retry" "error"
        exit 1
    fi

    if [[ ! -d "$AKB_CB_OUT_IMG_DIR" || ! -f "$AKB_CB_OUT_IMG_DIR/original_boot.img" ]]; then
        log "Out image does not exist, run copy_img then retry" "error"
        exit 1
    fi

    local kernel_build_dir="$AKB_ROOT_DIR/../kernel_build"
    local kernel_image="$kernel_build_dir/arch/arm64/boot/Image"
    local kernel_dtb="$kernel_build_dir/arch/arm64/boot/dts/mediatek/mt6765.dtb"

    if [[ ! -d "$kernel_build_dir" || ! -f "$kernel_image" || ! -f "$kernel_dtb" ]]; then
        log "Kernel has not been built, cannot build image" "error"
        exit 1
    fi

    log "Cleaning image dir"
    rm "$AKB_CB_OUT_IMG_DIR/kernel" || true
    rm "$AKB_CB_OUT_IMG_DIR/dtb" || true
    rm "$AKB_CB_OUT_IMG_DIR/ramdisk.cpio" || true
    rm "$AKB_CB_OUT_DIR/new_boot.img" || true

    log "Copying kernel"
    cp "$kernel_image" "$AKB_CB_OUT_IMG_DIR/kernel"
    cp "$kernel_dtb" "$AKB_CB_OUT_IMG_DIR/dtb"

    log "Creating ramdisk"
    pushd "$AKB_CB_OUT_BOOFS_DIR"

    find . -print0 2>/dev/null | \
        cpio --null -ov --format=newc 2>/dev/null | \
        gzip -9 > "$AKB_CB_OUT_IMG_DIR/ramdisk.cpio" 2>/dev/null
    
    popd

    log "Packing image"
    pushd "$AKB_CB_OUT_IMG_DIR"

    magiskboot repack original_boot.img "$AKB_CB_OUT_DIR/new_boot.img"

    popd

    log "Built image: $AKB_CB_OUT_DIR/new_boot.img"
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

    build_img)
        bfs::build_img
        ;;

    build_and_flash_img)
        bfs::build_img

        if [[ -z "$(fastboot devices)" ]]; then
        	log "Cannot flash image: no device detected" "error"
        	exit 1
        fi
        
        log "Flashing image and rebooting"
        fastboot flash boot "$AKB_CB_OUT_DIR/new_boot.img"
        fastboot reboot
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
        log "Building BusyBox"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/busybox/akb_builder.sh"
        log "Building rebooter"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/rebooter/akb_builder.sh"
        log "Building e2fsprogs"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/e2fsprogs/akb_builder.sh"
        log "Building OpenSSL"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/openssl/akb_builder.sh"
        log "Building PAD"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/parse-android-dynparts/akb_builder.sh"
        log "Building LVM2"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/lvm2/akb_builder.sh"
        ;;

    clean_tools)
        log "Cleaning BusyBox"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/busybox/akb_builder.sh" "clean"
        log "Cleaning rebooter"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/rebooter/akb_builder.sh" "clean"
        log "Cleaning e2fsprogs"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/e2fsprogs/akb_builder.sh" "clean"
        log "Cleaning OpenSSL"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/openssl/akb_builder.sh" "clean"
        log "Cleaning PAD"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/parse-android-dynparts/akb_builder.sh" "clean"
        log "Cleaning LVM2"
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/lvm2/akb_builder.sh" "clean"
        ;;

    tools_bbox)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/busybox/akb_builder.sh" "${@:2}"
        ;;

    tools_rebooter)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/rebooter/akb_builder.sh" "${@:2}"
        ;;

    tools_e2fs)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/e2fsprogs/akb_builder.sh" "${@:2}"
        ;;

    tools_ossl)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/openssl/akb_builder.sh" "${@:2}"
        ;;

    tools_pad)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/parse-android-dynparts/akb_builder.sh" "${@:2}"
        ;;

    tools_lvm)
        bfs::pre_build_action
        akb::invoke_builder "$AKB_CB_TOOLS_DIR/lvm2/akb_builder.sh" "${@:2}"
        ;;

    *)
        echo "Usage: $0" $'...\n'
        echo $'Out bootfs:\n\tinit_fs\n\tcopy_fs\n'
        echo $'Out image:\n\tcopy_img\n\tbuild_img\n\tbuild_and_flash_img\n'
        echo $'Out:\n\tclean_out\n'
        echo $'All tools:\n\ttc\n\tall_tools\n\tclean_tools\n'
        echo $'Specific tools:\n\ttools_bbox\n\ttools_rebooter\n\ttools_e2fs\n\ttools_ossl\n\ttools_pad\n\ttools_lvm'
        exit 1
        ;;
esac
