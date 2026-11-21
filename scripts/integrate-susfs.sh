#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
KSU_ROOT="$ROOT/KernelSU"
KSU_KERNEL="$KSU_ROOT/kernel"
SUSFS_DIR="$ROOT/susfs4ksu"

: "${SUSFS_REPO:=https://gitlab.com/simonpunk/susfs4ksu.git}"
: "${SUSFS_REF:=gki-android13-5.15}"

fail() {
  echo "::error::$*" >&2
  exit 1
}

# Do not attempt the legacy 10_enable_susfs_for_ksu.patch against Nova main.
# Nova builtin already contains the corresponding KSU-side SUSFS implementation.
[[ -d "$COMMON" ]] || fail "Linux common/ source directory is missing."
[[ -d "$KSU_KERNEL" ]] || fail "SukiSU Nova backend is missing; run integrate-sukisu-nova.sh first."

for file in \
  "$KSU_KERNEL/Kconfig" \
  "$KSU_KERNEL/Makefile" \
  "$KSU_KERNEL/ksu_main.c" \
  "$KSU_KERNEL/feature/sucompat.c"; do
  [[ -s "$file" ]] || fail "Nova builtin integration source missing: $file"
done

grep -qE '^[[:space:]]*config KSU_SUSFS$' "$KSU_KERNEL/Kconfig" ||
  fail "Backend lacks CONFIG_KSU_SUSFS. Refusing to bypass the KSU-side integration failure; select SukiSU Nova builtin."
grep -q 'susfs_init()' "$KSU_KERNEL/ksu_main.c" ||
  fail "Nova SUSFS init hook is missing; refusing to continue."
grep -q 'CONFIG_KSU_SUSFS' "$KSU_KERNEL/feature/sucompat.c" ||
  fail "Nova sucompat SUSFS path is missing; refusing to continue."
grep -q 'SUSFS_INLINE_HOOK' "$KSU_KERNEL/Makefile" ||
  fail "Nova backend does not advertise its native SUSFS inline-hook build mode."

echo "[SUSFS] Fetching SUSFS source branch: $SUSFS_REF"
rm -rf "$SUSFS_DIR"
git clone --depth=1 --branch "$SUSFS_REF" "$SUSFS_REPO" "$SUSFS_DIR"

PATCH_DIR="$SUSFS_DIR/kernel_patches"
KERNEL_PATCH="$PATCH_DIR/50_add_susfs_in_kernel-5.15.patch"

[[ -s "$KERNEL_PATCH" ]] ||
  fail "Required Linux 5.15 kernel patch not found: $KERNEL_PATCH"
[[ -d "$PATCH_DIR/fs" ]] ||
  fail "SUSFS fs/ source directory is missing."
[[ -d "$PATCH_DIR/include/linux" ]] ||
  fail "SUSFS include/linux/ source directory is missing."

[[ -s "$PATCH_DIR/fs/susfs.c" ]] ||
  fail "SUSFS fs/susfs.c source is missing."
[[ -s "$PATCH_DIR/include/linux/susfs.h" ]] ||
  fail "SUSFS include/linux/susfs.h header is missing."

# Copy the kernel-side implementation exactly as documented by SUSFS.
cp -a "$PATCH_DIR/fs/." "$COMMON/fs/"
cp -a "$PATCH_DIR/include/linux/." "$COMMON/include/linux/"

# Apply the kernel patch strictly. No --reject, || true, or continue-on-error.
if (
  cd "$COMMON"
  git apply --check "$KERNEL_PATCH"
); then
  (
    cd "$COMMON"
    git apply "$KERNEL_PATCH"
  )
  echo "[SUSFS] Linux 5.15 kernel patch applied."
elif (
  cd "$COMMON"
  git apply --reverse --check "$KERNEL_PATCH"
); then
  echo "[SUSFS] Exact Linux 5.15 kernel patch is already present."
else
  fail "Linux 5.15 SUSFS kernel patch does not apply cleanly. Build stopped; inspect patch context and source revision."
fi

grep -q 'susfs.o' "$COMMON/fs/Makefile" ||
  fail "Kernel patch did not register susfs.o in common/fs/Makefile."
grep -q 'SUSFS_VERSION' "$COMMON/include/linux/susfs.h" ||
  fail "SUSFS version declaration is missing after source installation."
grep -qE '^[[:space:]]*config KSU_SUSFS$' "$KSU_KERNEL/Kconfig" ||
  fail "Nova CONFIG_KSU_SUSFS disappeared after integration."

{
  echo "SUSFS repository: $SUSFS_REPO"
  echo "SUSFS ref: $SUSFS_REF"
  echo "SUSFS commit: $(git -C "$SUSFS_DIR" rev-parse HEAD)"
  echo "Linux kernel patch: $(basename "$KERNEL_PATCH")"
  echo "Nova backend commit: $(git -C "$KSU_ROOT" rev-parse HEAD)"
  echo "KSU-side SUSFS: provided natively by SukiSU Nova builtin backend"
  echo "Kernel-side SUSFS: patch applied and verified"
} | tee -a "$ROOT/integration-versions.txt"

echo "[SUSFS] Nova-native KSU integration and Linux 5.15 SUSFS integration verified."
