#!/usr/bin/env bash
# Check out and build the Android Common Kernel (GKI) with Kleaf (Bazel).
# Usage: ./sync-kernel.sh [build]   (ARCH=x86_64 for Cuttlefish, aarch64 for phones)
set -euo pipefail
. "$(dirname "$0")/env.sh"
: "${ARCH:=$([[ "$HOLY_PRODUCT" == *x86_64* ]] && echo x86_64 || echo aarch64)}"

mkdir -p "$KERNEL_DIR" && cd "$KERNEL_DIR"
[[ -d .repo ]] || repo init -u "$KERNEL_MANIFEST" -b "$KERNEL_BRANCH" --partial-clone --clone-filter=blob:limit=10M
repo sync -c -j"$JOBS" --no-tags

if [[ "${1:-}" == "build" ]]; then
  if [[ "$ARCH" == x86_64 ]]; then
    # GKI kernel + Cuttlefish virtual-device modules + initramfs in one dist.
    tools/bazel run //common-modules/virtual-device:virtual_device_x86_64_dist -- --destdir="$KERNEL_DIR/out/dist"
  else
    tools/bazel run //common:kernel_aarch64_dist -- --destdir="$KERNEL_DIR/out/dist"
  fi
  echo "Kernel in $KERNEL_DIR/out/dist. Boot it in Cuttlefish with:"
  echo "  ./run-emulator.sh -kernel_path=$KERNEL_DIR/out/dist/bzImage -initramfs_path=$KERNEL_DIR/out/dist/initramfs.img"
fi
