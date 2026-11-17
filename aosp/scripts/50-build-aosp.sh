#!/usr/bin/env bash
# Builds the Holy OS image: the chosen emulator product + vendor/holy apps.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config.env"

"$here/scripts/gen-vendor.sh"
cd "$AOSP_DIR"
set +u
source build/envsetup.sh
# Resolve the stock product's makefile so holy_<base> can inherit it, whatever
# directory this AOSP release keeps it in.
lunch "$BASE_PRODUCT-$RELEASE-$VARIANT" >/dev/null
base_mk="$(get_build_var INTERNAL_PRODUCT)"
set -u
"$here/scripts/gen-vendor.sh" "$base_mk"

set +u
lunch "holy_$BASE_PRODUCT-$RELEASE-$VARIANT"
set -u
m -j"$JOBS"
echo
echo "Built holy_$BASE_PRODUCT. Boot it with ./scripts/60-run-emulator.sh"
