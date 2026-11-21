#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
COMMON="$ROOT/common"
DEFCONFIG="$COMMON/arch/arm64/configs/gki_defconfig"
CONFIG_TOOL="$COMMON/scripts/config"
KSU_KCONFIG="$ROOT/KernelSU/kernel/Kconfig"

[[ -f "$DEFCONFIG" ]] || { echo "::error::gki_defconfig missing"; exit 1; }
[[ -f "$CONFIG_TOOL" ]] || { echo "::error::scripts/config missing"; exit 1; }
[[ -f "$KSU_KCONFIG" ]] || { echo "::error::SukiSU Kconfig missing"; exit 1; }

for symbol in KSU KPM KSU_SUSFS; do
  grep -qE "^[[:space:]]*config ${symbol}$" "$KSU_KCONFIG" ||
    { echo "::error::${symbol} is not defined in SukiSU Kconfig"; exit 1; }
done

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

for symbol in KPROBES EXT4_FS KALLSYMS KALLSYMS_ALL KSU KPM KSU_SUSFS; do
  grep -qE "^CONFIG_${symbol}=y$" "$DEFCONFIG" ||
    { echo "::error::CONFIG_${symbol}=y was not written"; exit 1; }
done

echo "[Kconfig] GKI baseline updated. Device-specific configuration remains to be validated."
