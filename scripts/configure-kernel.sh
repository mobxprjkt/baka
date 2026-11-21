#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
DEFCONFIG="$COMMON/arch/arm64/configs/gki_defconfig"
CONFIG_TOOL="$COMMON/scripts/config"
KSU_KCONFIG="$ROOT/KernelSU/kernel/Kconfig"

test -f "$DEFCONFIG"
test -f "$CONFIG_TOOL"
test -f "$KSU_KCONFIG"

# Refuse to silently build without the requested integrations.
for symbol in KSU KPM; do
  if ! grep -qE "^[[:space:]]*config ${symbol}$" "$KSU_KCONFIG"; then
    echo "::error::${symbol} is missing from SukiSU kernel Kconfig."
    exit 1
  fi
done

if ! grep -qE '^[[:space:]]*config KSU_SUSFS$' "$KSU_KCONFIG"; then
  echo "::error::SUSFS Kconfig is missing. Integration did not complete."
  exit 1
fi

chmod +x "$CONFIG_TOOL"

"$CONFIG_TOOL" --file "$DEFCONFIG" \
  --enable KPROBES \
  --enable KRETPROBES \
  --enable EXT4_FS \
  --enable KALLSYMS \
  --enable KALLSYMS_ALL \
  --enable KSU \
  --enable KPM \
  --enable KSU_SUSFS

# Verify the requested symbols are present in the base defconfig.
for symbol in KPROBES EXT4_FS KALLSYMS KALLSYMS_ALL KSU KPM KSU_SUSFS; do
  if ! grep -qE "^CONFIG_${symbol}=y$" "$DEFCONFIG"; then
    echo "::error::CONFIG_${symbol}=y was not written to gki_defconfig."
    exit 1
  fi
done

echo "Base GKI defconfig updated."
