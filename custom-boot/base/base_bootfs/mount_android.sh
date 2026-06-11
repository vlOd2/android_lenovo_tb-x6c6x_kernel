#!/bin/sh
set -euo pipefail

echo "Mounting partitions"
mount /dev/mapper/dynpart-vendor_a /mnt/vendor
mount /dev/mapper/dynpart-system_a /mnt/system

echo "Binding filesystems"
mount -o bind /mnt/vendor /mnt/system/vendor
mount -o bind /dev /mnt/system/dev
mount -o bind /proc /mnt/system/proc
mount -o bind /sys /mnt/system/sys

echo "Creating temporary /data"
mount -t tmpfs tmpfs /mnt/system/data
mkdir -p /mnt/system/data/vendor/stp_dump
mkdir -p /mnt/system/data/vendor/connsyslog

echo "Creating temporary /apex"
mount -t tmpfs tmpfs /mnt/system/apex
mkdir -p /mnt/system/apex/com.android.runtime

echo "Extracting apex into /apex"
rm /tmp/apex_payload.img
unzip /mnt/system/system/apex/com.android.runtime.apex apex_payload.img -d /tmp/
mount -o ro,loop /tmp/apex_payload.img /mnt/system/apex/com.android.runtime

echo "Copying test build"
cp /property_shim.so /mnt/system/data/
cp /libnl.so /mnt/system/data/

echo "enter with: chroot /mnt/system /system/bin/sh"