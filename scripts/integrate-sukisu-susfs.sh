#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
SUKISU_DIR="$ROOT/KernelSU"
SUSFS_DIR="$ROOT/susfs4ksu"

: "${SUKISU_REF:=main}"
: "${SUSFS_REF:=gki-android13-5.15}"

echo "[1/5] Clone SukiSU-Ultra: $SUKISU_REF"
if [[ ! -d "$SUKISU_DIR/.git" ]]; then
  git clone https://github.com/SukiSU-Ultra/SukiSU-Ultra.git "$SUKISU_DIR"
fi
git -C "$SUKISU_DIR" fetch --tags --force origin
git -C "$SUKISU_DIR" checkout --detach "$SUKISU_REF"

test -d "$SUKISU_DIR/kernel"
test -f "$COMMON/drivers/Makefile"
test -f "$COMMON/drivers/Kconfig"

echo "[2/5] Register SukiSU in the kernel tree"
ln -sfn ../../KernelSU/kernel "$COMMON/drivers/kernelsu"

if ! grep -qE 'obj-\$\(CONFIG_KSU\).*kernelsu' "$COMMON/drivers/Makefile"; then
  printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$COMMON/drivers/Makefile"
fi

if ! grep -qF 'source "drivers/kernelsu/Kconfig"' "$COMMON/drivers/Kconfig"; then
  sed -i '/^endmenu/i source "drivers/kernelsu/Kconfig"' \
    "$COMMON/drivers/Kconfig"
fi

echo "[3/5] Clone SUSFS branch: $SUSFS_REF"
if [[ ! -d "$SUSFS_DIR/.git" ]]; then
  git clone --depth=1 --branch "$SUSFS_REF" \
    https://gitlab.com/simonpunk/susfs4ksu.git "$SUSFS_DIR"
else
  git -C "$SUSFS_DIR" fetch --depth=1 origin "$SUSFS_REF"
  git -C "$SUSFS_DIR" checkout --detach FETCH_HEAD
fi

PATCH_DIR="$SUSFS_DIR/kernel_patches"
KSU_PATCH="$PATCH_DIR/KernelSU/10_enable_susfs_for_ksu.patch"
KERNEL_PATCH="$(find "$PATCH_DIR" -maxdepth 1 -type f \
  -name '50_add_susfs_in*5.15*.patch' -print -quit)"

if [[ ! -s "$KSU_PATCH" || ! -s "$KERNEL_PATCH" ]]; then
  echo "::error::Required SUSFS patches for GKI 5.15 were not found."
  find "$PATCH_DIR" -maxdepth 2 -type f -name '*.patch' -print || true
  exit 1
fi

echo "[4/5] Copy SUSFS sources and apply version-specific patches"
mkdir -p "$COMMON/fs" "$COMMON/include/linux"
cp -a "$PATCH_DIR/fs/." "$COMMON/fs/"
cp -a "$PATCH_DIR/include/linux/." "$COMMON/include/linux/"

cp "$KSU_PATCH" "$SUKISU_DIR/10_enable_susfs_for_ksu.patch"
(
  cd "$SUKISU_DIR"
  patch --batch --forward -p1 \
    < 10_enable_susfs_for_ksu.patch
)

(
  cd "$COMMON"
  patch --batch --forward -p1 < "$KERNEL_PATCH"
)

echo "[5/5] Verify integration symbols"
grep -Rqs 'config KSU' "$SUKISU_DIR/kernel"
grep -Rqs 'config KPM' "$SUKISU_DIR/kernel"
grep -Rqs 'config KSU_SUSFS' "$SUKISU_DIR/kernel" "$COMMON/fs" "$COMMON/include/linux" \
  || grep -Rqs 'KSU_SUSFS' "$SUKISU_DIR/kernel"

{
  echo "SukiSU commit: $(git -C "$SUKISU_DIR" rev-parse HEAD)"
  echo "SUSFS commit: $(git -C "$SUSFS_DIR" rev-parse HEAD)"
  echo "Kernel common commit: $(git -C "$COMMON" rev-parse HEAD)"
  echo "Kernel SUSFS patch: $KERNEL_PATCH"
} | tee "$ROOT/integration-versions.txt"

echo "SukiSU + SUSFS source integration completed."
