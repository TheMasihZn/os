#!/usr/bin/env bash
# Builds the GKI kernel + virtual device modules for x86_64 with Kleaf (Bazel),
# then copies them into the AOSP tree so the image boots your kernel.
#   ./30-build-kernel.sh            build and install into $AOSP_DIR
#   NO_INSTALL=1 ./30-build-kernel.sh   build only (output in $KERNEL_DIR/out/holy_dist)
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config.env"

cd "$KERNEL_DIR"
DIST="$KERNEL_DIR/out/holy_dist"
tools/bazel run //common-modules/virtual-device:virtual_device_x86_64_dist -- --destdir="$DIST"
echo "Kernel artifacts in $DIST"
[ -n "${NO_INSTALL:-}" ] && exit 0

# The emulator/Cuttlefish products pick up prebuilts from these AOSP dirs,
# keyed by kernel version (e.g. 6.12). Detect it from the built kernel.
kver="$(sed -n 's/^VERSION = //p' common/Makefile).$(sed -n 's/^PATCHLEVEL = //p' common/Makefile)"
kdst="$AOSP_DIR/kernel/prebuilts/$kver/x86_64"
mdst="$AOSP_DIR/kernel/prebuilts/common-modules/virtual-device/$kver/x86-64"
if [ ! -d "$kdst" ] || [ ! -d "$mdst" ]; then
  echo "AOSP has no prebuilt dirs for kernel $kver ($kdst, $mdst)."
  echo "Your AOSP release expects a different kernel; set KERNEL_BRANCH to match, or boot with:"
  echo "  emulator -kernel $DIST/bzImage"
  exit 1
fi
cp -v "$DIST/bzImage" "$kdst/kernel-$kver"
find "$DIST" -maxdepth 1 -name '*.ko' -exec cp -v {} "$mdst/" \;
echo "Installed kernel $kver into AOSP. Rebuild the image with 50-build-aosp.sh."
