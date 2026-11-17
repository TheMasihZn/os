# Shared settings. Override any of these in the environment before running a script.
: "${AOSP_DIR:=$HOME/aosp}"                 # platform checkout
: "${KERNEL_DIR:=$HOME/android-kernel}"     # kernel checkout
: "${AOSP_MANIFEST:=https://android.googlesource.com/platform/manifest}"
: "${AOSP_BRANCH:=android-latest-release}"  # Google's current public AOSP release branch
: "${KERNEL_MANIFEST:=https://android.googlesource.com/kernel/manifest}"
: "${KERNEL_BRANCH:=common-android16-6.12}" # GKI branch matching the platform release
: "${HOLY_PRODUCT:=holycart_cf_x86_64_phone}"
: "${HOLY_RELEASE:=trunk_staging}"
: "${HOLY_VARIANT:=userdebug}"
: "${JOBS:=$(nproc)}"
OS_REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export AOSP_DIR KERNEL_DIR AOSP_MANIFEST AOSP_BRANCH KERNEL_MANIFEST KERNEL_BRANCH \
  HOLY_PRODUCT HOLY_RELEASE HOLY_VARIANT JOBS OS_REPO_DIR
