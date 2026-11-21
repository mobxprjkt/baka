#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
KSU_ROOT="$ROOT/KernelSU"
SUSFS_DIR="$ROOT/susfs4ksu"

: "${SUSFS_REPO:=https://gitlab.com/simonpunk/susfs4ksu.git}"
: "${SUSFS_REF:=gki-android13-5.15}"

if [[ ! -d "$KSU_ROOT/.git" || ! -d "$KSU_ROOT/kernel" ]]; then
  echo "::error::SukiSU Nova kernel backend is missing. Run integrate-sukisu-nova.sh first."
  exit 1
fi

echo "[SUSFS] Cloning branch: $SUSFS_REF"
rm -rf "$SUSFS_DIR"
git clone --depth=1 --branch "$SUSFS_REF" "$SUSFS_REPO" "$SUSFS_DIR"

PATCH_DIR="$SUSFS_DIR/kernel_patches"
KSU_PATCH="$PATCH_DIR/KernelSU/10_enable_susfs_for_ksu.patch"
KERNEL_PATCH="$(find "$PATCH_DIR" -maxdepth 1 -type f \
  -name '50_add_susfs_in_kernel-5.15.patch' -print -quit)"

if [[ ! -s "$KSU_PATCH" ]]; then
  echo "::error::SUSFS KernelSU patch not found: $KSU_PATCH"
  exit 1
fi

if [[ -z "$KERNEL_PATCH" || ! -s "$KERNEL_PATCH" ]]; then
  echo "::error::SUSFS 5.15 kernel patch not found in $PATCH_DIR"
  find "$PATCH_DIR" -maxdepth 2 -type f -name '*.patch' -print || true
  exit 1
fi

if [[ ! -f "$PATCH_DIR/fs/susfs.c" || ! -f "$PATCH_DIR/include/linux/susfs.h" ]]; then
  echo "::error::SUSFS source files are missing."
  exit 1
fi

echo "[SUSFS] Copying kernel source files"
install -m 0644 "$PATCH_DIR/fs/susfs.c" "$COMMON/fs/susfs.c"
install -m 0644 "$PATCH_DIR/include/linux/susfs.h" "$COMMON/include/linux/susfs.h"

echo "[SUSFS] Checking and applying SukiSU-side patch"
(
  cd "$KSU_ROOT"
  git apply --check "$KSU_PATCH"
  git apply "$KSU_PATCH"
)

echo "[SUSFS] Checking and applying Linux 5.15 kernel patch"
(
  cd "$COMMON"
  git apply --check "$KERNEL_PATCH"
  git apply "$KERNEL_PATCH"
)

if ! grep -q 'config KSU_SUSFS' "$KSU_ROOT/kernel/Kconfig"; then
  echo "::error::CONFIG_KSU_SUSFS was not added to SukiSU Kconfig."
  exit 1
fi

if ! grep -q 'susfs.o' "$COMMON/fs/Makefile"; then
  echo "::error::SUSFS patch did not register susfs.o in fs/Makefile."
  exit 1
fi

{
  echo "SUSFS repository: $SUSFS_REPO"
  echo "SUSFS ref: $SUSFS_REF"
  echo "SUSFS commit: $(git -C "$SUSFS_DIR" rev-parse HEAD)"
  echo "Kernel patch: $(basename "$KERNEL_PATCH")"
  echo "KernelSU patch: $(basename "$KSU_PATCH")"
} | tee -a "$ROOT/integration-versions.txt"

echo "[SUSFS] Kernel and SukiSU-side patches applied successfully."
