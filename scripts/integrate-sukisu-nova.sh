#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
SETUP_URL="https://raw.githubusercontent.com/SukiSU-Nova/SukiSU-Nova/main/kernel/setup.sh"
SETUP_FILE="$(mktemp)"

: "${SUKISU_REF:=main}"

echo "[SukiSU Nova] Downloading the official integration script"
curl -fsSL "$SETUP_URL" -o "$SETUP_FILE"
chmod +x "$SETUP_FILE"

echo "[SukiSU Nova] Integrating kernel backend ref: $SUKISU_REF"
# The official Nova setup script installs the kernel backend under ./KernelSU
# and registers common/drivers/kernelsu.
bash "$SETUP_FILE" "$SUKISU_REF"
rm -f "$SETUP_FILE"

KSU_ROOT="$ROOT/KernelSU"
KSU_KERNEL="$KSU_ROOT/kernel"

if [[ ! -d "$KSU_KERNEL" ]]; then
  echo "::error::SukiSU Nova setup did not create KernelSU/kernel."
  echo "Check the upstream setup script and backend repository availability."
  exit 1
fi

if [[ ! -L "$ROOT/common/drivers/kernelsu" && ! -d "$ROOT/common/drivers/kernelsu" ]]; then
  echo "::error::drivers/kernelsu was not registered."
  exit 1
fi

if ! grep -q 'config KPM' "$KSU_KERNEL/Kconfig"; then
  echo "::error::KPM Kconfig symbol was not found in the installed backend."
  exit 1
fi

if ! grep -q 'CONFIG_KSU' "$ROOT/common/drivers/Makefile"; then
  echo "::error::KSU driver entry was not found."
  exit 1
fi

{
  echo "SukiSU Nova manager repository: https://github.com/SukiSU-Nova/SukiSU-Nova"
  echo "Official setup script: $SETUP_URL"
  echo "Requested backend ref: $SUKISU_REF"
  echo "Installed backend commit: $(git -C "$KSU_ROOT" rev-parse HEAD 2>/dev/null || echo unknown)"
  echo "KPM Kconfig: present"
} | tee "$ROOT/integration-versions.txt"

echo "[SukiSU Nova] Kernel backend integration completed."
