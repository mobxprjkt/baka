# SukiSU Nova + SUSFS port for GKI 5.15

## Why this changes the backend ref

The old integration tried to apply SUSFS `10_enable_susfs_for_ksu.patch` to SukiSU Nova `main`.
That patch targets a different KernelSU internal layout and rewrites/removes many unrelated
hook and lifecycle paths. It is not a safe path-prefix or filename mismatch.

SukiSU Nova's `builtin` branch contains the corresponding KSU-side SUSFS integration natively:
- `CONFIG_KSU_SUSFS` and SUSFS sub-options in `kernel/Kconfig`
- `susfs_init()` in `kernel/ksu_main.c`
- SUSFS-aware `sucompat.c`
- the `SUSFS_INLINE_HOOK` build path in `kernel/Makefile`
- KPM remains available in the same Nova Kconfig

Therefore the KSU-side functionality is supplied by the Nova backend itself, not silently omitted.
The separate SUSFS Linux 5.15 kernel patch remains mandatory and is applied strictly by
`scripts/integrate-susfs.sh`.

## Apply

1. Replace the two scripts in your repository with the versions in `scripts/`.
2. Apply `workflow-defaults.patch` to `.github/workflows/kernel-build.yml`, or manually change
   the `sukisu_ref` default and `SUKISU_REF` fallback from `main` to `builtin`.
3. Run the workflow with:
   - `sukisu_ref=builtin`
   - `susfs_ref=gki-android13-5.15`
   - `manifest_branch=common-android13-5.15-lts`

## Strict failure behavior

The SUSFS script:
- fails if the Nova backend lacks native SUSFS symbols/hooks;
- copies the SUSFS kernel source and headers;
- checks and applies `50_add_susfs_in_kernel-5.15.patch`;
- fails if the patch cannot apply cleanly;
- verifies `susfs.o` and the SUSFS header after integration.

It does not use `git apply --reject`, `|| true`, or continue after a failed patch.

## Important

This is a source integration fix, not a successful build or device validation claim.
The next Actions run must still compile the kernel. Only after the build succeeds should the
resulting boot image/AnyKernel package be tested on the exact `sapphiren` device and stock
boot image. Keep a recovery path and backup of the original boot image.
