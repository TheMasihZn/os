#!/usr/bin/env bash
# Boot the built image in Cuttlefish and print how to connect.
set -euo pipefail
. "$(dirname "$0")/env.sh"
cd "$AOSP_DIR"
set +u; source build/envsetup.sh; lunch "${HOLY_PRODUCT}-${HOLY_RELEASE}-${HOLY_VARIANT}"; set -u
launch_cvd --daemon --cpus 4 --memory_mb 8192 "$@"
echo "Booting. Web UI: https://localhost:8443   adb: adb connect 0.0.0.0:6520"
