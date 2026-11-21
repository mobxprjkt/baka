#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
DEFCONFIG="$COMMON/arch/arm64/configs/gki_defconfig"
CONFIG_TOOL="$COMMON/scripts/config"

test -f "$DEFCONFIG"
test -x "$CONFIG_TOOL" || chmod +x "$CONFIG_TOOL"

echo "Enabling GKI ARM64 + SukiSU + SUSFS + KPM options in gki_defconfig"

"$CONFIG_TOOL" --file "$DEFCONFIG" \
  --enable KPROBES \
  --enable KRETPROBES \
  --enable EXT4_FS \
  --enable KALLSYMS \
  --enable KALLSYMS_ALL \
  --enable KSU \
  --enable KSU_SUSFS \
  --enable KPM

# Confirm that the required symbols are represented in the defconfig.
for symbol in KPROBES KRETPROBES EXT4_FS KALLSYMS KALLSYMS_ALL KSU KSU_SUSFS KPM; do
  if ! grep -qE "^CONFIG_${symbol}=y$" "$DEFCONFIG"; then
    echo "::error::CONFIG_${symbol}=y was not written to gki_defconfig."
    exit 1
  fi
done

echo "Defconfig updated. build/build.sh will generate the final .config."
