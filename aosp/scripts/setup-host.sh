#!/usr/bin/env bash
# Prepare an Ubuntu 22.04/24.04 (x86_64) machine to build AOSP and the Android kernel.
# Installs: APT build dependencies, Google's `repo` tool, a JDK, adb/fastboot (platform-tools),
# and optionally the Cuttlefish host packages used to boot the emulator image.
#
# Usage: sudo -E ./setup-host.sh [--with-cuttlefish]
set -euo pipefail

WITH_CF=0
[[ "${1:-}" == "--with-cuttlefish" ]] && WITH_CF=1

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo -E $0 $*" >&2
  exit 1
fi
TARGET_USER="${SUDO_USER:-root}"

. /etc/os-release
if [[ "${ID}" != "ubuntu" && "${ID_LIKE:-}" != *ubuntu* && "${ID}" != "debian" ]]; then
  echo "Warning: only Ubuntu/Debian are tested; continuing anyway." >&2
fi

# Space and memory sanity checks (AOSP wants ~400 GB disk and 32+ GB RAM, 64 GB is better).
avail_gb=$(df --output=avail -BG "${AOSP_DIR:-$HOME}" | tail -1 | tr -dc 0-9)
mem_gb=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
echo "Free disk: ${avail_gb} GB, RAM: ${mem_gb} GB"
(( avail_gb < 400 )) && echo "Warning: less than 400 GB free; a full AOSP checkout plus build may not fit." >&2
(( mem_gb < 32 )) && echo "Warning: less than 32 GB RAM; build with fewer jobs (m -j8) and add swap." >&2

export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386 || true
apt-get update

# AOSP platform build dependencies (from source.android.com "Establish a build environment").
APT_PLATFORM=(
  git git-core git-lfs gnupg flex bison build-essential zip unzip curl wget
  zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev
  libgl1-mesa-dev libxml2-utils xsltproc fontconfig python3 python-is-python3
  rsync ccache libncurses-dev
)
# Extra packages the Android kernel (Kleaf/Bazel) and mkbootimg tooling need.
APT_KERNEL=(bc cpio kmod libssl-dev libelf-dev dwarves lz4 xz-utils pahole)
# JDK for Gradle-built apps (the platform build uses its own prebuilt JDK).
APT_JAVA=(openjdk-17-jdk-headless)

apt-get install -y --no-install-recommends "${APT_PLATFORM[@]}" "${APT_JAVA[@]}"
# pahole/dwarves names differ between releases; install what exists.
for p in "${APT_KERNEL[@]}"; do
  apt-get install -y --no-install-recommends "$p" || echo "skip: $p not available"
done

# Google's repo launcher.
install -d /usr/local/bin
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o /usr/local/bin/repo
chmod a+rx /usr/local/bin/repo
repo --version >/dev/null 2>&1 || true

# Android SDK platform-tools (adb, fastboot): latest from Google, not the stale APT package.
PT_DIR=/opt/android-platform-tools
tmp=$(mktemp -d)
curl -fsSL https://dl.google.com/android/repository/platform-tools-latest-linux.zip -o "$tmp/pt.zip"
rm -rf "$PT_DIR" && unzip -q "$tmp/pt.zip" -d /opt && mv /opt/platform-tools "$PT_DIR"
ln -sf "$PT_DIR/adb" /usr/local/bin/adb
ln -sf "$PT_DIR/fastboot" /usr/local/bin/fastboot
rm -rf "$tmp"

# udev rules so adb/fastboot can talk to phones without root.
apt-get install -y --no-install-recommends android-sdk-platform-tools-common || true
usermod -aG plugdev "$TARGET_USER" || true

# git identity is required by repo.
if ! sudo -u "$TARGET_USER" git config --global user.email >/dev/null; then
  echo "Note: set git identity: git config --global user.name 'You'; git config --global user.email you@example.com"
fi

# ccache in the user's shell.
PROFILE="$(getent passwd "$TARGET_USER" | cut -d: -f6)/.bashrc"
grep -q USE_CCACHE "$PROFILE" 2>/dev/null || cat >>"$PROFILE" <<'RC'
# AOSP build cache
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
RC
sudo -u "$TARGET_USER" ccache -M 50G >/dev/null || true

if (( WITH_CF )); then
  # Cuttlefish host tools: build the .deb packages from google/android-cuttlefish.
  apt-get install -y --no-install-recommends devscripts equivs config-package-dev debhelper-compat golang
  cf=$(mktemp -d)
  git clone --depth 1 https://github.com/google/android-cuttlefish "$cf/android-cuttlefish"
  (cd "$cf/android-cuttlefish" && tools/buildutils/build_packages.sh)
  apt-get install -y "$cf"/android-cuttlefish/cuttlefish-base_*.deb "$cf"/android-cuttlefish/cuttlefish-user_*.deb
  usermod -aG kvm,cvdnetwork,render "$TARGET_USER"
  echo "Cuttlefish installed. Reboot (or log out/in) so the new groups apply."
fi

echo
echo "Host ready. Next: ./sync-platform.sh   (and ./sync-kernel.sh for the kernel)"
