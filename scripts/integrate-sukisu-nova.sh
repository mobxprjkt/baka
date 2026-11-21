#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
REPO_URL="https://github.com/SukiSU-Nova/SukiSU-Nova.git"
KSU_ROOT="$ROOT/KernelSU"
KSU_KERNEL="$KSU_ROOT/kernel"
DRIVER_DIR="$ROOT/common/drivers"

# Nova builtin is the Nova backend variant with native SUSFS + KPM support.
: "${SUKISU_REF:=builtin}"

[[ -d "$DRIVER_DIR" ]] || {
  echo "::error::common/drivers directory is missing."
  exit 1
}

echo "[SukiSU Nova] Fetching official GitHub source: $SUKISU_REF"
rm -rf "$KSU_ROOT"
git clone --filter=blob:none --no-checkout "$REPO_URL" "$KSU_ROOT"
git -C "$KSU_ROOT" fetch --depth=1 origin "$SUKISU_REF"
git -C "$KSU_ROOT" checkout --detach FETCH_HEAD

for file in \
  "$KSU_KERNEL/Kconfig" \
  "$KSU_KERNEL/Makefile" \
  "$KSU_KERNEL/ksu_main.c" \
  "$KSU_KERNEL/feature/sucompat.c"; do
  if [[ ! -s "$file" ]]; then
    echo "::error::Expected Nova builtin source file missing: $file"
    exit 1
  fi
done

grep -qE '^[[:space:]]*config KSU$' "$KSU_KERNEL/Kconfig" || {
  echo "::error::Nova KSU Kconfig symbol is missing."
  exit 1
}
grep -qE '^[[:space:]]*config KPM$' "$KSU_KERNEL/Kconfig" || {
  echo "::error::Nova KPM Kconfig symbol is missing."
  exit 1
}
grep -qE '^[[:space:]]*config KSU_SUSFS$' "$KSU_KERNEL/Kconfig" || {
  echo "::error::This Nova ref does not provide native CONFIG_KSU_SUSFS. Use the Nova builtin branch/ref."
  exit 1
}
grep -q 'susfs_init()' "$KSU_KERNEL/ksu_main.c" || {
  echo "::error::Nova backend has no susfs_init() lifecycle call."
  exit 1
}
grep -q 'CONFIG_KSU_SUSFS' "$KSU_KERNEL/feature/sucompat.c" || {
  echo "::error::Nova sucompat.c is missing its SUSFS integration path."
  exit 1
}
grep -q 'SUSFS_INLINE_HOOK' "$KSU_KERNEL/Makefile" || {
  echo "::error::Nova Makefile does not identify its SUSFS inline-hook build path."
  exit 1
}

ln -sfn "$(realpath --relative-to="$DRIVER_DIR" "$KSU_KERNEL")" "$DRIVER_DIR/kernelsu"

DRIVER_MAKEFILE="$DRIVER_DIR/Makefile"
DRIVER_KCONFIG="$DRIVER_DIR/Kconfig"

grep -Fq 'obj-$(CONFIG_KSU) += kernelsu/' "$DRIVER_MAKEFILE" ||
  printf '\nobj-$(CONFIG_KSU) += kernelsu/\n' >> "$DRIVER_MAKEFILE"

grep -Fq 'source "drivers/kernelsu/Kconfig"' "$DRIVER_KCONFIG" ||
  sed -i '/^endmenu/i source "drivers/kernelsu/Kconfig"' "$DRIVER_KCONFIG"

{
  echo "SukiSU Nova repository: $REPO_URL"
  echo "Requested backend ref: $SUKISU_REF"
  echo "Installed backend commit: $(git -C "$KSU_ROOT" rev-parse HEAD)"
  echo "Native CONFIG_KSU_SUSFS: present"
  echo "Native SUSFS init and sucompat integration: present"
  echo "KPM Kconfig: present"
} | tee "$ROOT/integration-versions.txt"

echo "[SukiSU Nova] Native SUSFS-capable backend integration completed."
