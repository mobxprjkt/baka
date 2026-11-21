# AnyKernel3 — Xiaomi Redmi Note 13 4G / NFC

This folder contains a device-specific AnyKernel3 installer for:

- `sapphiren`
- `sapphire`
- Qualcomm Snapdragon 685 / SM6225
- A/B boot partition layout

The installer detects the active slot using AnyKernel3's `find_slot` helper
and targets `/dev/block/bootdevice/by-name/boot${slot}`. It uses `split_boot`
and `flash_boot` so the current boot ramdisk is retained while the kernel
image is replaced.

Before flashing:
1. Confirm the device reports `sapphiren` or `sapphire`.
2. Keep a backup of the stock boot image for the active slot.
3. Use a recovery compatible with the installed Android/boot image format.
4. Do not flash if the device codename or partition layout differs.

The installer does not guarantee compatibility across Android 14–17. Kernel
KMI, vendor modules, boot image format, and device firmware still need testing.
