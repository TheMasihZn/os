#!/usr/bin/env bash
# Checks out the Android Common Kernel (GKI) plus the virtual-device modules
# used by the x86_64 emulator and Cuttlefish.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config.env"
export PATH="$HOME/bin:$PATH"

mkdir -p "$KERNEL_DIR"; cd "$KERNEL_DIR"
if [ ! -d .repo ]; then
  repo init -u "$KERNEL_MANIFEST_URL" -b "$KERNEL_BRANCH" --depth=1
else
  repo init -b "$KERNEL_BRANCH"
fi
repo sync -c -j"$JOBS" --no-tags --optimized-fetch --fail-fast
echo "Kernel $KERNEL_BRANCH synced to $KERNEL_DIR"
