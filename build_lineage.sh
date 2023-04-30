#!/bin/bash

# Build script for my build "for personal usage only"

devices=(
    "pstar"
)

## Sync
LOS_VERSION=20.0
LOS_VERSION_SHORT=20
# Init LineageOS repos
repo init -u https://github.com/LineageOS/android.git --depth=1 -b lineage-${LOS_VERSION} --git-lfs
git lfs install
# Resync webview
rm -rf external/chromium-webview/prebuilt/*
rm -rf .repo/projects/external/chromium-webview/prebuilt/*.git
rm -rf .repo/project-objects/LineageOS/android_external_chromium-webview_prebuilt_*.git
# Add local_manifests
rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
curl https://raw.githubusercontent.com/rafidosman/local_manifests/main/lineage-20.xml -o .repo/local_manifests/lineage.xml

# Sync
repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune
repo forall external/chromium-webview/prebuilt/* -c "git lfs pull"

## Build
# Init envsetup
#. vendor/extra/build/envsetup.sh -p
# Build
#for device in ${devices[@]}; do
#    echo "Build for ${device}"
#    sleep 3
#    mka_build ${device} -r
#done

