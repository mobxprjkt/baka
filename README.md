# Sapphire(n) — Google Common GKI LTS 5.15 build project

This is a reproducible **build source project**, not a prebuilt kernel. Target:
- Xiaomi Redmi Note 13 4G NFC (`sapphiren` / `sapphire`)
- Qualcomm SM6225 / Snapdragon 685
- Google Android Common Kernel: `common-android13-5.15-lts`
- SukiSU Nova + SUSFS + KPM
- Google Clang from the Android kernel manifest
- ccache, Image output, AnyKernel3 ZIP

## Important device compatibility warning

Google Common GKI is a generic kernel base. It does not automatically include
all Sapphire device-specific configuration, DTB/DTBO, vendor modules, firmware,
or the exact boot image layout. This project deliberately does **not** invent
a `sapphiren_defconfig` or claim that a generic GKI `Image` is boot-tested.

The workflow builds the Google common GKI image and packages it into an
AnyKernel3 installer. Treat the resulting ZIP as experimental until it has
been matched against the exact ROM/vendor boot image and tested with a backup
boot image available. Prefer a temporary `fastboot boot` test where supported.

## Build

1. Upload/extract this project into a GitHub repository.
2. Open **Actions → Google Common GKI 5.15 (Sapphire)**.
3. Run workflow manually with the defaults.
4. Download the workflow artifact after a successful run.

The default integration refs are pinned:
- SukiSU Nova Forgejo commit: `a81ed4e3d9801e740d132ec0614fdc62735e2b69`
- SUSFS commit: `c1d1da42b74771944207ec45aaceff9c57e84985`

The SUSFS kernel patch and KernelSU-side patch are both mandatory. The
integration script stops on a rejected hunk; it never reports SUSFS enabled
when the KSU-side integration is incomplete. If upstream source layout drifts,
the build stops and must be updated using the narrowly-scoped compatibility
recovery logic from `nikakvo/GKI_Kernel_SukiSU`, not by ignoring `.rej` files.

## Device-specific completion still required

Before treating this as a daily-driver kernel, compare the generated config,
KMI, modules, DTB/DTBO and boot/vendor_boot arrangement against the stock
Sapphire ROM. `gki_defconfig` is used as the Google GKI baseline; this is not a
replacement for a verified Sapphire device config. Do not flash on the basis
of a successful compile alone.

## Layout

- `.github/workflows/kernel-build.yml` — GitHub Actions build pipeline
- `scripts/integrate-sukisu-nova.sh` — pinned SukiSU Nova checkout + driver link
- `scripts/integrate-susfs.sh` — SUSFS kernel and KSU-side patch application
- `scripts/configure-kernel.sh` — Kconfig enablement and verification
- `scripts/fetch-manager-apks.sh` — manager APK from the selected GitHub release
- `anykernel/anykernel.sh` — A/B boot-slot installer for Sapphire/Sapphiren

## Recovery

Keep a copy of the exact stock `boot.img` and `vendor_boot.img`. If the device
fails to boot, restore the original boot image using the matching fastboot
partition command for the current firmware. Never use an image from another
device or ROM build.
