#!/usr/bin/env bash
# Build the Holy Cart OS image.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$AOSP_DIR"
rsync -a --delete --exclude VLC.apk "$OS_REPO_DIR/aosp/vendor/holycart/" vendor/holycart/
[[ -f vendor/holycart/prebuilt/apps/VLC/VLC.apk ]] || "$OS_REPO_DIR/aosp/scripts/fetch-prebuilts.sh"

set +u   # envsetup.sh is not nounset-clean
source build/envsetup.sh
lunch "${HOLY_PRODUCT}-${HOLY_RELEASE}-${HOLY_VARIANT}"
set -u
m -j"$JOBS"
echo "Images are in $ANDROID_PRODUCT_OUT"
