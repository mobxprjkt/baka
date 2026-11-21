# Android GKI 5.15 - SukiSU / SUSFS / KPM builder

This repository is a GitHub Actions builder scaffold for the Android common
kernel manifest branch `common-android13-5.15-lts`.

## Included

- Google Android kernel manifest sync (including Google Clang prebuilts)
- SukiSU-Ultra integration
- SUSFS 5.15 patch integration
- KPM config (`CONFIG_KPM=y`)
- ccache with GitHub Actions cache
- SukiSU manager APK download
- AnyKernel3 ZIP packaging
- GitHub Releases publishing

## Important compatibility note

The source remains Linux 5.15 / Android 13 GKI lineage. The Android 14/15/16/17
workflow input is a target-device label only; it does not turn a 5.15 kernel
into the native GKI kernel generation for every Android release.

Some devices upgraded to Android 14-17 continue to use a 5.15 kernel/KMI and
may be candidates, but compatibility must be checked against the exact device,
KMI, vendor modules, boot image format, and required ABI symbols. Android 15+
devices commonly use newer kernel generations. Do not flash this build to a
device merely because its Android version matches the workflow label.

## Repository setup

1. Add this builder scaffold to your own GitHub repository.
2. Configure `anykernel/anykernel.sh` for your exact device.
3. Review the SukiSU and SUSFS upstream revisions you intend to build.
4. Run Actions -> Android GKI 5.15 - SukiSU + SUSFS + KPM -> Run workflow.
5. Enable `publish_release` only after the build and device test pass.

## Defaults

- Manifest: `common-android13-5.15-lts`
- SukiSU ref: `main`
- SUSFS ref: `gki-android13-5.15`
- Architecture: `arm64`
- Build config: `common/build.config.gki.aarch64`
- Output: `Image`
- Compiler: Google Clang from the synced Android manifest
- Cache: ccache (8 GB)

## SUSFS patch compatibility

The SUSFS kernel patch and the SukiSU-side patch must match each other. The
integration script applies both with `patch --batch --forward`; it intentionally
fails on rejected hunks instead of silently producing a partially patched tree.

For reproducible release builds, pin `sukisu_ref` and `susfs_ref` to tested
commit hashes rather than leaving them on moving branches.

## AnyKernel3 is device-specific

The workflow downloads the upstream AnyKernel3 framework, then overlays your
`anykernel/` directory and copies the compiled `Image`.

A valid `anykernel.sh` must identify the correct device and boot partition.
There is no universally safe recovery ZIP for all GKI devices. Keep a stock
boot image backup and verify the installer before flashing.

## Build outputs

- `AnyKernel3-GKI-5.15-Android-<target>-<commit>.zip`
- `.sha256` checksum
- SukiSU manager APK
- `manifest.lock.xml`
- `BUILD_INFO.txt`

## License

The kernel and third-party components retain their respective upstream
licenses. Review the licenses of SukiSU-Ultra, SUSFS, Google kernel sources,
and AnyKernel3 before redistributing builds.
