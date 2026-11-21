#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
KSU_ROOT="$ROOT/KernelSU"
SUSFS_DIR="$ROOT/susfs4ksu"

: "${SUSFS_REPO:=https://gitlab.com/simonpunk/susfs4ksu.git}"
: "${SUSFS_COMMIT:=c1d1da42b74771944207ec45aaceff9c57e84985}"

fail() { echo "::error::$*" >&2; exit 1; }

[[ -d "$COMMON" ]] || fail "Google common/ tree missing."
[[ -d "$KSU_ROOT/kernel" ]] || fail "SukiSU Nova backend missing."
[[ "$SUSFS_COMMIT" =~ ^[0-9a-f]{40}$ ]] || fail "SUSFS_COMMIT must be a full SHA."

rm -rf "$SUSFS_DIR"
git clone --filter=blob:none "$SUSFS_REPO" "$SUSFS_DIR"
git -C "$SUSFS_DIR" fetch --depth=1 origin "$SUSFS_COMMIT"
git -C "$SUSFS_DIR" checkout --detach FETCH_HEAD
[[ "$(git -C "$SUSFS_DIR" rev-parse HEAD)" == "$SUSFS_COMMIT" ]] || fail "SUSFS pin mismatch."

PATCH_DIR="$SUSFS_DIR/kernel_patches"
KERNEL_PATCH="$PATCH_DIR/50_add_susfs_in_gki-android13-5.15.patch"
KSU_PATCH="$PATCH_DIR/KernelSU/10_enable_susfs_for_ksu.patch"

[[ -s "$KERNEL_PATCH" ]] || fail "Missing GKI patch: $KERNEL_PATCH"
[[ -s "$KSU_PATCH" ]] || fail "Missing KSU integration patch: $KSU_PATCH"
[[ -s "$PATCH_DIR/fs/susfs.c" ]] || fail "Missing fs/susfs.c."
[[ -s "$PATCH_DIR/include/linux/susfs.h" ]] || fail "Missing include/linux/susfs.h."

cp -a "$PATCH_DIR/fs/." "$COMMON/fs/"
cp -a "$PATCH_DIR/include/linux/." "$COMMON/include/linux/"

apply_patch_strict() {
  local tree="$1" patch_file="$2" label="$3"
  if (cd "$tree" && git apply --check "$patch_file"); then
    (cd "$tree" && git apply "$patch_file")
    echo "[$label] applied cleanly"
  elif (cd "$tree" && git apply --reverse --check "$patch_file"); then
    echo "[$label] already applied"
  else
    echo "::error::$label patch does not apply cleanly to the pinned source."
    echo "Do not delete .rej files or skip this step. Update the compatibility"
    echo "recovery against the exact upstream patch and SukiSU source revision."
    exit 1
  fi
}

# Both halves are required: the GKI patch adds Linux-side SUSFS; the KSU patch
# adds CONFIG_KSU_SUSFS and connects SukiSU's own hooks/lifecycle to SUSFS.
apply_patch_strict "$COMMON" "$KERNEL_PATCH" "SUSFS GKI 5.15"
apply_patch_strict "$KSU_ROOT" "$KSU_PATCH" "SUSFS SukiSU backend"

grep -q 'susfs.o' "$COMMON/fs/Makefile" || fail "susfs.o not registered in fs/Makefile."
grep -q 'SUSFS_VERSION' "$COMMON/include/linux/susfs.h" || fail "SUSFS header verification failed."
grep -Rqs 'config KSU_SUSFS' "$KSU_ROOT/kernel" || fail "CONFIG_KSU_SUSFS missing after KSU patch."

{
  echo "SUSFS repository: $SUSFS_REPO"
  echo "SUSFS commit: $(git -C "$SUSFS_DIR" rev-parse HEAD)"
  echo "SUSFS GKI patch: $(basename "$KERNEL_PATCH")"
  echo "SUSFS KSU patch: applied and verified"
} | tee -a "$ROOT/integration-versions.txt"

echo "[SUSFS] Both kernel and SukiSU-side integrations verified."
