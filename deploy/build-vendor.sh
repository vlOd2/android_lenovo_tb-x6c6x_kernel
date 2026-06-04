#!/bin/bash
set -euo pipefail

VENDOR_IMAGE="../vendor.img"
MODULES_DIR="$PWD/../kernel-4.19/out/modules/lib/modules/4.19.127-docker"
CONNECTIVITY_DIR="$MODULES_DIR/kernel/drivers/misc/mediatek/connectivity"

if [[ $EUID -ne 0 ]]; then
	echo "error: this script must be run as root" 
	exit 1
fi

echo "- VENDOR: Preparing"
mkdir -p vendor
cp "$VENDOR_IMAGE" vendor/new_vendor.img
cd vendor

echo "- VENDOR: Resizing"
umount vendor_mount || true
dd if=/dev/zero bs=64M count=1 >> new_vendor.img
e2fsck -f new_vendor.img || true
resize2fs new_vendor.img
e2fsck -f new_vendor.img || true

echo "- VENDOR: Mounting"
mkdir -p vendor_mount
mount new_vendor.img vendor_mount

echo "- VENDOR: Cleaning modules"
mkdir -p vendor_mount/lib/modules
ls -Al vendor_mount/lib/modules
rm -rf vendor_mount/lib/modules/*

echo "- VENDOR: Patching init scripts"

cat > vendor_mount/etc/init/init.wmt_drv.rc <<END
END

cat > vendor_mount/etc/init/init.wlan_drv.rc <<END
END

echo "- VENDOR: Unmounting"
umount vendor_mount