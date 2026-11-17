#!/usr/bin/env bash
# Download prebuilt APKs that go into the image (VLC for now) into the vendor tree.
# VLC for Android is GPLv2/LGPLv2.1; the APK comes from VideoLAN's official mirror.
set -euo pipefail
. "$(dirname "$0")/env.sh"

: "${VLC_ABI:=}"   # arm64-v8a or x86_64; derived from the product when empty
if [[ -z "$VLC_ABI" ]]; then
  case "$HOLY_PRODUCT" in *x86_64*) VLC_ABI=x86_64 ;; *) VLC_ABI=arm64-v8a ;; esac
fi

base=https://get.videolan.org/vlc-android/last
apk=$(curl -fsSL "$base/" | grep -oE "VLC-Android-[0-9.]+-${VLC_ABI}\.apk" | sort -uV | tail -1)
[[ -n "$apk" ]] || { echo "Could not find a VLC $VLC_ABI APK at $base" >&2; exit 1; }

for dest in "$OS_REPO_DIR/aosp/vendor/holycart/prebuilt/apps/VLC" "$AOSP_DIR/vendor/holycart/prebuilt/apps/VLC"; do
  [[ -d "$(dirname "$dest")" ]] || continue
  mkdir -p "$dest"
  curl -fL "$base/$apk" -o "$dest/VLC.apk"
  echo "$apk  sha256=$(sha256sum "$dest/VLC.apk" | cut -d' ' -f1)" | tee "$dest/VERSION"
done
