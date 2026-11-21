#!/sbin/sh
# AnyKernel3 installer for Xiaomi Redmi Note 13 4G / NFC
# Codename: sapphiren / sapphire. Experimental GKI build only.

properties() { '
kernel.string=Google Common GKI 5.15 LTS - SukiSU Nova
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=sapphiren
device.name2=sapphire
'; }

slot="$(find_slot)"
block="/dev/block/bootdevice/by-name/boot${slot}"
is_slot_device=1
ramdisk_compression=auto
patch_vbmeta_flag=auto

. tools/ak3-core.sh

ui_print "Google Common GKI 5.15 / SukiSU Nova"
ui_print "Target: sapphiren / sapphire"
ui_print "Active slot: ${slot}"
ui_print "WARNING: only flash after verifying ROM/vendor compatibility."

split_boot
flash_boot

ui_print "Kernel image installed to active boot slot."
ui_print "Keep the stock boot image ready for recovery."
