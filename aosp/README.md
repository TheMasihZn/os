# Holy Cart OS (AOSP)

Recipe to build and boot an Android (AOSP) image with your own apps and VLC preinstalled.
First target: **Cuttlefish x86_64**, Google's virtual phone that runs on any Linux PC with KVM.

## What you need

* Ubuntu 22.04 or 24.04, x86_64, with KVM (`ls /dev/kvm`)
* About 400 GB free disk, 32 GB RAM (64 GB recommended), many CPU cores
* A git identity (`git config --global user.name/user.email`)

## Steps

```bash
cd aosp/scripts
sudo -E ./setup-host.sh --with-cuttlefish   # apt packages, repo, JDK 17, adb/fastboot, Cuttlefish host tools
# reboot so the kvm/cvdnetwork groups apply
./sync-platform.sh                          # AOSP platform into ~/aosp (+ vendor/holycart)
./fetch-prebuilts.sh                        # latest VLC APK for the target ABI
./build-platform.sh                         # lunch holycart_cf_x86_64_phone-trunk_staging-userdebug && m
./run-emulator.sh                           # boot; open https://localhost:8443 or `adb connect 0.0.0.0:6520`
```

Optional, the Android kernel (GKI, built with Kleaf/Bazel):

```bash
./sync-kernel.sh build                      # ~/android-kernel, branch common-android16-6.12
./run-emulator.sh -kernel_path=$HOME/android-kernel/out/dist/bzImage \
                  -initramfs_path=$HOME/android-kernel/out/dist/initramfs.img
```

The platform build already ships a prebuilt kernel, so this is only needed to change the kernel.

## Settings

All in `scripts/env.sh`, overridable from the environment, e.g. `AOSP_DIR=/data/aosp ./sync-platform.sh`.
`AOSP_BRANCH` defaults to `android-latest-release`; set `KERNEL_BRANCH` to the GKI branch that matches it.

## Layout

| Path | Purpose |
|---|---|
| `scripts/` | host setup, sync, build, emulator |
| `local_manifests/holycart.xml` | extra repos (your GitHub projects) pulled into the tree by `repo sync` |
| `vendor/holycart/` | product definition and preinstalled apps, copied to `<aosp>/vendor/holycart` |
| `vendor/holycart/Android.bp` | `VLC` prebuilt app; slot for the AI keyboard APK |
| `vendor/holycart/products/` | `holycart_cf_x86_64_phone` = Cuttlefish phone + Holy Cart apps |

## Adding apps

* **APK**: put it in `vendor/holycart/prebuilt/apps/<Name>/<Name>.apk`, add an `android_app_import` in
  `Android.bp` and the name to `PRODUCT_PACKAGES` in `holycart.mk`.
* **From source**: add the repo to `local_manifests/holycart.xml` (needs an `Android.bp` with `android_app`).

## Going to a phone later

Add a product in `vendor/holycart/products/` that inherits that device's AOSP product (e.g. a Pixel or
the arm64 GSI `aosp_arm64`), list it in `AndroidProducts.mk`, and build with `ARCH=aarch64` for the kernel.
