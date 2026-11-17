#!/usr/bin/env bash
# Boots the last build. Classic emulator opens a window; Cuttlefish prints a
# URL (https://localhost:8443) where you see the screen in a browser.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config.env"
cd "$AOSP_DIR"
set +u
source build/envsetup.sh
lunch "holy_$BASE_PRODUCT-$RELEASE-$VARIANT" >/dev/null
set -u
case "$BASE_PRODUCT" in
  aosp_cf_*) launch_cvd --daemon "$@" && echo "Open https://localhost:8443";;
  *)         emulator "$@";;
esac
