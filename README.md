# Android GKI 5.15 - SukiSU Nova + SUSFS + KPM

A GitHub Actions scaffold for building the Android Common Kernel 5.15 GKI
lineage with Google Clang, ccache, SukiSU Nova kernel integration, SUSFS,
KPM, manager APK download, AnyKernel3 packaging, and GitHub Releases.

## Source layout and integration model

- Google kernel manifest: `common-android13-5.15-lts`
- Kernel source project in the manifest: `kernel/common`, branch
  `android13-5.15-lts`
- Build config: `common/build.config.gki.aarch64`
- Build entrypoint: `build/build.sh`
- SukiSU Nova: official `kernel/setup.sh` from `SukiSU-Nova/SukiSU-Nova`
- SUSFS: `gki-android13-5.15`
- KPM: `CONFIG_KPM=y`
- Output: `Image`, then AnyKernel3 ZIP

The official SukiSU Nova setup script currently installs its kernel backend
under `KernelSU/` and registers `common/drivers/kernelsu`. The script is fetched
from the Nova repository at build time. The manager app repository and kernel
backend are related but are not the same thing.

## Important compatibility warning

This project builds the Android 13 GKI 5.15 kernel lineage. The workflow's
Android target input is a label for your device's installed Android version;
it does not change the kernel KMI. Android 14 devices may use a 5.15 KMI, but
Android 15/16/17 devices generally correspond to newer kernel generations
(6.6/6.12/6.18 in the current Nova compatibility overview). Do not assume a
5.15 Image is compatible with every Android 14-17 device.

Before flashing, verify:
- Exact device codename and SoC
- Exact kernel version and KMI
- Vendor modules and protected exports
- Boot/vendor_boot/dtbo layout
- AVB and slot handling
- Recovery compatibility

## Repository setup

1. Create a new GitHub repository and upload this project.
2. The included `anykernel/anykernel.sh` is configured for Xiaomi Redmi Note 13 4G/NFC (`sapphire` / `sapphiren`) A/B boot slots. Verify it against your installed partition map before flashing.
3. Review and pin tested SukiSU and SUSFS refs before production releases.
4. Open Actions -> Android GKI 5.15 - SukiSU Nova + SUSFS + KPM.
5. Run workflow_dispatch.
6. Enable `publish_release` only after the build and device test pass.

## Workflow inputs

- `android_target`: metadata label only.
- `manifest_branch`: defaults to `common-android13-5.15-lts`.
- `sukisu_ref`: backend ref passed to the official Nova setup script.
- `susfs_ref`: defaults to `gki-android13-5.15`.
- `manager_repo`: defaults to `SukiSU-Nova/SukiSU-Nova`.
- `publish_release`: create a GitHub Release after successful build.

## Build and release artifacts

- AnyKernel3 ZIP
- SHA-256 checksum
- SukiSU Nova manager APK
- `manifest.lock.xml`
- `BUILD_INFO.txt`

## Reproducibility

For production, pin `sukisu_ref` and `susfs_ref` to tested commit hashes. The
workflow records the kernel manifest and integration refs. Moving branch names
are convenient for testing but are not immutable build inputs.

## Known boundaries

- The included AnyKernel3 installer targets the active `boot_a` / `boot_b` slot for Sapphire/Sapphiren. Do not use it on other devices.
- SukiSU Nova's manager APK is not the same artifact as the kernel backend.
- KPM is enabled by `CONFIG_KPM`; it is not a separate `.kpm` module.
- SUSFS requires both the kernel-side patch and the KernelSU-side patch.
- Patch failures stop the build; there is no automatic fuzzy patching.
