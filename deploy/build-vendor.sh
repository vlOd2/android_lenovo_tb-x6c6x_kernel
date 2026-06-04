#!/bin/bash
set -euo pipefail

VENDOR_IMAGE="../vendor.img"
MODULES_DIR="$PWD/../kernel-4.19/out/modules/lib/modules/4.19.127-docker"
CONNECTIVITY_DIR="$MODULES_DIR/kernel/drivers/misc/mediatek/connectivity"

echo "error: this script is not needed anymore and is kept around just in case" 
exit 1

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

echo "- VENDOR: Copying modules"
pushd vendor_mount/lib/modules

cat > modules.load <<END
#connadp.ko
wmt_drv.ko
wmt_chrdev_wifi.ko
wlan_drv_gen4m.ko
END

#cat > modules.dep <<END
#connadp.ko:
#wmt_drv.ko: connadp.ko
#wmt_chrdev_wifi.ko: wmt_drv.ko connadp.ko
#wlan_drv_gen4m.ko: wmt_chrdev_wifi.ko wmt_drv.ko connadp.ko
#END

cat > modules.dep <<END
wmt_drv.ko:
wmt_chrdev_wifi.ko: wmt_drv.ko
wlan_drv_gen4m.ko: wmt_chrdev_wifi.ko wmt_drv.ko
END

cat > modules.softdep <<END
# Soft dependencies extracted from modules themselves.

END

cp "$MODULES_DIR/modules.alias" .

#cp "$CONNECTIVITY_DIR/connadp.ko" .
cp "$CONNECTIVITY_DIR/wmt_drv/wmt_drv.ko" .
cp "$CONNECTIVITY_DIR/wmt_chrdev_wifi/wmt_chrdev_wifi.ko" .
cp "$CONNECTIVITY_DIR/wlan_drv_gen4m/wlan_drv_gen4m.ko" .

popd

echo "- VENDOR: Patching init scripts"

cat > vendor_mount/etc/init/init.wmt_drv.rc <<END
on boot
    #insmod /vendor/lib/modules/connadp.ko
    insmod /vendor/lib/modules/wmt_drv.ko

END

cat > vendor_mount/etc/init/init.wlan_drv.rc <<END
# load wifi driver after wmt_loader finish
on property:vendor.connsys.driver.ready=yes
    insmod /vendor/lib/modules/wmt_chrdev_wifi.ko
    insmod /vendor/lib/modules/wlan_drv_gen4m.ko
    start wlan_assistant

END

echo "- VENDOR: Unmounting"
umount vendor_mount