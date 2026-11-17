#!/usr/bin/env bash
# Installs everything a Ubuntu/Debian host needs to sync and build AOSP, the
# Android Common Kernel, and the Holy Android apps:
#   - apt build dependencies for AOSP and the kernel
#   - Google's `repo` tool (signature-checked)
#   - JDK 17 + Android SDK command-line tools for the Gradle app builds
#   - adb/fastboot (platform-tools)
#   - KVM access for the x86_64 emulator
# Safe to re-run. Tested target: Ubuntu 22.04 / 24.04 (x86_64).
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=../config.env
source "$here/config.env"

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

echo "==> apt packages"
$SUDO apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  `# AOSP build deps (source.android.com/docs/setup/start/requirements)` \
  git git-core git-lfs gnupg flex bison build-essential zip unzip curl ca-certificates \
  zlib1g-dev libc6-dev-i386 x11proto-core-dev libx11-dev lib32z1-dev \
  libgl1-mesa-dev libxml2-utils xsltproc fontconfig rsync python3 python-is-python3 \
  libncurses-dev ccache file procps \
  `# kernel tooling (Kleaf is hermetic; these cover the legacy build and modules)` \
  bc cpio kmod libelf-dev libssl-dev dwarves lz4 \
  `# app builds` \
  openjdk-17-jdk-headless \
  `# emulator / Cuttlefish` \
  qemu-kvm cpu-checker libpulse0 libnss3 libxcomposite1 libxcursor1 libxi6 libxtst6

echo "==> repo tool"
mkdir -p "$HOME/bin"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o "$tmp/repo"
curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo.asc -o "$tmp/repo.asc"
# Google's repo release key fingerprint, from source.android.com.
REPO_KEY=8BB9AD793E8E6153AF0F9A4416530D5E920F5C65
export GNUPGHOME="$tmp/gnupg"; mkdir -m 700 "$GNUPGHOME"
if gpg --batch --quiet --keyserver hkps://keyserver.ubuntu.com --recv-keys "$REPO_KEY" 2>/dev/null; then
  gpg --batch --verify "$tmp/repo.asc" "$tmp/repo"
else
  echo "   (keyserver unreachable, skipping repo signature check)"
fi
install -m 0755 "$tmp/repo" "$HOME/bin/repo"
unset GNUPGHOME
case ":$PATH:" in *":$HOME/bin:"*) ;; *)
  grep -qs 'HOME/bin' "$HOME/.profile" || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.profile"
  export PATH="$HOME/bin:$PATH";;
esac

if [ -z "${SKIP_ANDROID_SDK:-}" ]; then
echo "==> Android SDK (cmdline-tools + platform-tools)"
: "${ANDROID_HOME:=$HOME/Android/Sdk}"
CMDLINE_TOOLS_ZIP="${CMDLINE_TOOLS_ZIP:-commandlinetools-linux-13114758_latest.zip}"
if [ ! -x "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  curl -fsSL "https://dl.google.com/android/repository/$CMDLINE_TOOLS_ZIP" -o "$tmp/clt.zip"
  unzip -q "$tmp/clt.zip" -d "$tmp/clt"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$tmp/clt/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
fi
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses >/dev/null || true
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" "platform-tools"
grep -qs 'ANDROID_HOME=' "$HOME/.profile" || cat >> "$HOME/.profile" <<EOF
export ANDROID_HOME="$ANDROID_HOME"
export PATH="\$ANDROID_HOME/platform-tools:\$PATH"
EOF
fi

echo "==> git identity (repo refuses to sync without one)"
git config --global user.name  >/dev/null || git config --global user.name  "Holy OS Builder"
git config --global user.email >/dev/null || git config --global user.email "builder@localhost"
git config --global color.ui false 2>/dev/null || true
git lfs install --skip-repo >/dev/null

echo "==> KVM"
if [ -e /dev/kvm ]; then
  getent group kvm >/dev/null && $SUDO usermod -aG kvm "$(id -un)" || true
  echo "   /dev/kvm present (log out and back in if you were just added to 'kvm')"
else
  echo "   WARNING: /dev/kvm missing; enable virtualization in BIOS or the emulator will not boot"
fi

echo "==> ccache (speeds up rebuilds; 50 GB cache)"
ccache -M 50G >/dev/null || true
grep -qs USE_CCACHE "$HOME/.profile" || echo 'export USE_CCACHE=1' >> "$HOME/.profile"

echo
echo "Host ready. Open a new shell (or 'source ~/.profile'), then run:"
echo "  ./scripts/10-sync-aosp.sh && ./scripts/20-sync-kernel.sh"
