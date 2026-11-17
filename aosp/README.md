# Holy OS: AOSP + Android kernel build

Scripts to build an Android (AOSP) image for the **x86_64 emulator** with a
self-built Android Common Kernel and the Holy apps preinstalled as system apps.

Everything is driven by [`config.env`](config.env); override any value by
exporting it before a script runs.

## Requirements

| | Minimum | Recommended |
|---|---|---|
| OS | Ubuntu 22.04 / 24.04 x86_64 | Ubuntu 24.04 |
| Disk | 400 GB free (AOSP ~350 GB incl. build, kernel ~40 GB) | 1 TB SSD |
| RAM | 32 GB | 64 GB |
| CPU | 8 cores | 16+ cores |
| Virtualization | `/dev/kvm` (VT-x / AMD-V on in BIOS) | |

A first full build takes a few hours on a 16-core machine.

## Steps

```bash
cd aosp
./scripts/00-setup-host.sh     # apt packages, repo tool, JDK 17, Android SDK, adb/fastboot, KVM
source ~/.profile
./scripts/10-sync-aosp.sh      # AOSP platform source  -> $AOSP_DIR   (~100+ GB download)
./scripts/20-sync-kernel.sh    # Android Common Kernel -> $KERNEL_DIR
./scripts/30-build-kernel.sh   # GKI + virtual-device modules, installed into the AOSP tree
./scripts/40-build-apps.sh     # Gradle-build the Holy apps, drop APKs into vendor/holy
./scripts/50-build-aosp.sh     # build the image: lunch holy_<base>-trunk_staging-userdebug; m
./scripts/60-run-emulator.sh   # boot it
```

Steps 30 and 40 are optional: skip 30 to use AOSP's stock prebuilt kernel,
skip 40 to build a plain image.

## What each piece is

- **`repo`**: Google's multi-repository tool. AOSP is ~1000 git repos tied
  together by a manifest; `repo init` picks the manifest/branch and
  `repo sync` fetches them.
- **AOSP platform** (`AOSP_BRANCH`, default `android-latest-release`): the
  OS userspace, framework and build system. Pin a tag such as
  `android-16.0.0_r2` for reproducible builds.
- **Android Common Kernel** (`KERNEL_BRANCH`, default
  `common-android16-6.12`): Google's GKI kernel, built with Kleaf (Bazel,
  hermetic toolchain, so no host compiler setup is needed). The kernel
  branch must match the AOSP release (Android 16 uses 6.12); step 30 stops
  with a hint if they don't.
- **`vendor/holy`**: the layer that turns the stock emulator into Holy OS.
  `scripts/gen-vendor.sh` generates its `Android.bp` (one
  `android_app_import` per APK), `holy.mk` (the package list) and the
  `holy_<base>` product that inherits the stock emulator product. The
  generated files are git-ignored; edit the scripts, not the output.

## Targets

| `BASE_PRODUCT` | Runs as | Notes |
|---|---|---|
| `sdk_phone64_x86_64` (default) | Android Emulator window | Nothing extra to install |
| `aosp_cf_x86_64_phone` | Cuttlefish, view at `https://localhost:8443` | Install the host packages from [google/android-cuttlefish](https://github.com/google/android-cuttlefish) first |

A real phone (Pixel) would add device trees and vendor blobs; the same
`holy.mk` can be inherited from that device's product.

## Adding an app (e.g. the keyboard)

Add a line to `HOLY_APPS` in `config.env`:

```
TheMasihZn/<repo> Holy<Name>
```

then rerun `40-build-apps.sh` and `50-build-aosp.sh`. The repo must build
with `./gradlew :app:assembleRelease`. APKs are re-signed with the build's
key, so unsigned release APKs are fine. Apps land on the `product`
partition as system apps.

For the keyboard to be enabled by default, its input-method XML must set
`android:isDefault="true"`; a system IME marked default is enabled on first
boot. Two apps cannot share an `applicationId`, which is why only `Dirty7J`
(not `Dirty7`) is listed.

## Notes

- Use `JOBS=8 ./scripts/50-build-aosp.sh` if the build runs out of memory.
- `ccache` is enabled with a 50 GB cache; rebuilds after small changes take
  minutes.
- Set `SKIP_ANDROID_SDK=1` for `00-setup-host.sh` on a machine that only
  builds the OS, not the apps.
