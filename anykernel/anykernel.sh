#!/sbin/sh
#
# AnyKernel3 installer for Xiaomi Redmi Note 13 4G / NFC
# Device codenames: sapphire, sapphiren
# SoC: Qualcomm Snapdragon 685 (SM6225)
# Partition layout: A/B boot slots
#
# Based on the AnyKernel3 framework by osm0sis.
# Verify the boot image and keep a stock boot backup before flashing.

properties() { '
kernel.string=GKI 5.15 - SukiSU Nova
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=sapphiren
device.name2=sapphire
'; }

# Detect currently active slot and target the matching boot partition.
slot=$(find_slot)
block=/dev/block/bootdevice/by-name/boot${slot}
is_slot_device=1

# Let AnyKernel3 handle ramdisk compression and AVB vbmeta flag patching.
ramdisk_compression=auto
patch_vbmeta_flag=auto

## AnyKernel methods (DO NOT CHANGE)
. tools/ak3-core.sh

## AnyKernel install
ui_print " "
ui_print "SukiSU Nova GKI 5.15"
ui_print "Device: Xiaomi Redmi Note 13 4G / NFC"
ui_print "Codename: sapphire / sapphiren"
ui_print "Active slot: ${slot}"
ui_print " "

# Split the currently installed boot image, replace the kernel Image,
# preserve the device ramdisk, then flash the active boot slot.
split_boot
flash_boot

ui_print " "
ui_print "SukiSU Nova kernel installed."
ui_print "Reboot only after confirming the installer completed."
ui_print " "
