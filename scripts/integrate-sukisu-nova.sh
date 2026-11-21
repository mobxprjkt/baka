#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
KSU_ROOT="$ROOT/KernelSU"
DRIVER_DIR="$COMMON/drivers"

: "${SUKISU_REPO:=https://git.zako.shirkneko.top:20004/shirkneko/SukiSU.git}"
: "${SUKISU_COMMIT:=a81ed4e3d9801e740d132ec0614fdc62735e2b69}"

fail() { echo "::error::$*" >&2; exit 1; }

[[ -d "$DRIVER_DIR" ]] || fail "Google common/drivers is missing."
[[ "$SUKISU_COMMIT" =~ ^[0-9a-f]{40}$ ]] || fail "SUKISU_COMMIT must be a full 40-character SHA."

rm -rf "$KSU_ROOT"
git clone --filter=blob:none "$SUKISU_REPO" "$KSU_ROOT"
git -C "$KSU_ROOT" fetch --depth=1 origin "$SUKISU_COMMIT"
git -C "$KSU_ROOT" checkout --detach FETCH_HEAD
[[ "$(git -C "$KSU_ROOT" rev-parse HEAD)" == "$SUKISU_COMMIT" ]] || fail "SukiSU commit pin mismatch."

KSU_KERNEL="$KSU_ROOT/kernel"
[[ -s "$KSU_KERNEL/Kconfig" ]] || fail "Pinned SukiSU checkout has no kernel/Kconfig."
[[ -s "$KSU_KERNEL/Kbuild" ]] || fail "Pinned SukiSU checkout has no kernel/Kbuild."

ln -sfn "$(realpath --relative-to="$DRIVER_DIR" "$KSU_KERNEL")" "$DRIVER_DIR/kernelsu"

grep -Fq 'obj-$(CONFIG_KSU) += kernelsu/' "$DRIVER_DIR/Makefile" ||
  printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$DRIVER_DIR/Makefile"

if ! grep -Fq 'source "drivers/kernelsu/Kconfig"' "$DRIVER_DIR/Kconfig"; then
  if grep -q '^endmenu' "$DRIVER_DIR/Kconfig"; then
    sed -i '/^endmenu/i source "drivers/kernelsu/Kconfig"' "$DRIVER_DIR/Kconfig"
  else
    printf '\nsource "drivers/kernelsu/Kconfig"\n' >> "$DRIVER_DIR/Kconfig"
  fi
fi

{
  echo "SukiSU repository: $SUKISU_REPO"
  echo "SukiSU commit: $(git -C "$KSU_ROOT" rev-parse HEAD)"
} | tee "$ROOT/integration-versions.txt"

echo "[SukiSU] Pinned Nova backend linked into Google common tree."
