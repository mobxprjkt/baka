# Device-specific AnyKernel3 configuration

The build workflow downloads the upstream AnyKernel3 installer and overlays this
directory before adding the compiled `Image`.

Before running the workflow, place your tested device-specific files here,
especially:

- `anykernel.sh` — required.
- Any device-specific installer scripts or tools required by your device.

Do not use a generic `block=boot` assumption. Set the correct boot partition,
slot handling, device codename checks, ramdisk handling, and AVB/vbmeta behavior
for your exact device.

The workflow intentionally stops if `anykernel/anykernel.sh` is missing or still
contains template placeholders. This prevents publishing a ZIP that looks
flashable but targets the wrong partition.
