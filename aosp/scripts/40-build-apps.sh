#!/usr/bin/env bash
# Clones/updates each Holy app repo, builds its release APK with Gradle and
# drops it into vendor/holy/prebuilt/<Module>/<Module>.apk for the image.
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"
source "$here/config.env"
: "${ANDROID_HOME:=$HOME/Android/Sdk}"; export ANDROID_HOME
GRADLE_TASK="${GRADLE_TASK:-assembleRelease}"

mkdir -p "$APPS_DIR"
while read -r repo module; do
  [ -z "$repo" ] && continue
  dir="$APPS_DIR/${repo#*/}"
  echo "==> $repo -> $module"
  if [ -d "$dir/.git" ]; then git -C "$dir" pull --ff-only; else git clone "https://github.com/$repo" "$dir"; fi
  (cd "$dir" && chmod +x gradlew && ./gradlew --no-daemon ":app:$GRADLE_TASK")
  # Signed or unsigned both work: the AOSP build re-signs imported APKs.
  apk="$(find "$dir/app/build/outputs/apk" -name '*.apk' | head -1)"
  [ -n "$apk" ] || { echo "no APK produced for $repo"; exit 1; }
  mkdir -p "$here/vendor/holy/prebuilt/$module"
  cp -v "$apk" "$here/vendor/holy/prebuilt/$module/$module.apk"
done <<< "$HOLY_APPS"
"$here/scripts/gen-vendor.sh"
