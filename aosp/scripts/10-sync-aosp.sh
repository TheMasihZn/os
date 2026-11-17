#!/usr/bin/env bash
# Checks out the AOSP platform source into $AOSP_DIR and links in vendor/holy.
# First sync downloads ~100+ GB; later runs only fetch changes.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config.env"
export PATH="$HOME/bin:$PATH"

mkdir -p "$AOSP_DIR"; cd "$AOSP_DIR"
if [ ! -d .repo ]; then
  # --partial-clone + clone-filter keeps .repo small; -c later syncs one branch.
  repo init -u "$AOSP_MANIFEST_URL" -b "$AOSP_BRANCH" \
    --partial-clone --clone-filter=blob:limit=10M --no-use-superproject
else
  repo init -b "$AOSP_BRANCH"
fi
repo sync -c -j"$JOBS" --no-tags --optimized-fetch --fail-fast

# vendor/holy lives in this git repo; symlink it so edits here show up in the tree.
mkdir -p vendor
ln -sfn "$here/vendor/holy" vendor/holy
echo "AOSP $AOSP_BRANCH synced to $AOSP_DIR (vendor/holy -> $here/vendor/holy)"
