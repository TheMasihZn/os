#!/usr/bin/env bash
# Check out the AOSP platform source and add the Holy Cart vendor tree to it.
# Partial clone + no tags keeps the download around 100 GB instead of 300+.
set -euo pipefail
. "$(dirname "$0")/env.sh"

mkdir -p "$AOSP_DIR" && cd "$AOSP_DIR"
if [[ ! -d .repo ]]; then
  repo init -u "$AOSP_MANIFEST" -b "$AOSP_BRANCH" \
    --partial-clone --clone-filter=blob:limit=10M --no-use-superproject
fi

# Extra projects (your GitHub repos) on top of Google's manifest.
mkdir -p .repo/local_manifests
cp "$OS_REPO_DIR/aosp/local_manifests/"*.xml .repo/local_manifests/

repo sync -c -j"$JOBS" --no-tags --optimized-fetch --prune --fail-fast

# Copy (not symlink: Soong does not follow symlinked directories) the vendor tree in.
rsync -a --delete "$OS_REPO_DIR/aosp/vendor/holycart/" "$AOSP_DIR/vendor/holycart/"
echo "Platform synced to $AOSP_DIR. Next: ./fetch-prebuilts.sh && ./build-platform.sh"
