# Device-specific AnyKernel3 configuration

The workflow downloads upstream AnyKernel3, overlays this directory, then
copies the compiled `Image` into the ZIP.

Before building a flashable ZIP:

1. Copy `anykernel.sh.example` to `anykernel.sh`.
2. Configure device codename checks.
3. Configure the correct boot image/partition and A/B slot behavior.
4. Add any required ramdisk, vendor_boot, dtbo, or image handling for your device.
5. Test against the exact device and recovery.

The workflow refuses to package if `anykernel/anykernel.sh` is missing or still
contains template placeholders. There is no safe universal AnyKernel3 installer
for every GKI device.
