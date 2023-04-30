#!/bin/bash

# Build script for my build "for personal usage only"
set -e

devices=(
    "pstar"
)

initRepos() {
## Sync
LOS_VERSION=20.0
LOS_VERSION_SHORT=20
# Init Evolution-X repos
echo "-->> repo init"
repo init -u https://github.com/LineageOS/android.git --depth=1 -b lineage-${LOS_VERSION} --git-lfs
git lfs install
echo

echo "-->> Resync Webview"
#Resync Webview
rm -rf external/chromium-webview/prebuilt/*
rm -rf .repo/projects/external/chromium-webview/prebuilt/*.git
rm -rf .repo/project-objects/LineageOS/android_external_chromium-webview_prebuilt_*.git
echo
#remove sync project from Evolution-X manifest
#echo "remove unwanted project"
#sed -i "/\platform\/hardware\/qcom\/sm7250\/media/d" .repo/manifests/default.xml
#sed -i "/\platform\/hardware\/qcom\/sm7250\/display/d" .repo/manifests/default.xml
#sed -i "/\platform\/hardware\/qcom\/sm8150\/media/d" .repo/manifests/default.xml
#sed -i "/\platform\/hardware\/qcom\/sm8150\/display/d" .repo/manifests/default.xml
#sed -i "/\platform\/hardware\/qcom\/sm8150\/data\/ipacfg-mgr/d" .repo/manifests/default.xml
#sed -i "/\hardware\/qcom\/sm8150\/Android.mk/d" .repo/manifests/default.xml
#sed -i "/\hardware\/qcom\/sm8150\/Android.bp.*/{N;/\n<*/d}" .repo/manifests/default.xml
#sed -i "/\platform\/hardware\/google\/pixel/d" .repo/manifests/default.xml
#sed -i "/\platform\/hardware\/google\/pixel-sepolicy/d" .repo/manifests/default.xml

echo "-->> Add local_manifests"
# Add local_manifests
rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
curl https://raw.githubusercontent.com/rafidosman/local_manifests/main/lineage-20.xml -o .repo/local_manifests/lineage.xml
echo
}


syncRepos() {
# Sync
echo "-->> syncing repos"
repo sync -c --force-sync --no-tags --no-clone-bundle -j$(nproc --all) --optimized-fetch --prune
repo forall external/chromium-webview/prebuilt/* -c "git lfs pull"
echo
}

setupEnv() {
## Build
echo "-->> setting up envsetup"
#. vendor/extra/build/envsetup.sh -p
source build/envsetup.sh
echo
}

applyPatches() {
echo "-->> Applying personal patches"

repopick 321337 -f # Deprioritize important developer notifications
repopick 321338 -f # Allow disabling important developer notifications
repopick 321339 -f # Allow disabling USB notifications
repopick 340916 # SystemUI: add burnIn protection
repopick 342860 # codec2: Use numClientBuffers to control the pipeline
repopick 342861 # CCodec: Control the inputs to avoid pipeline overflow
repopick 342862 # [WA] Codec2: queue a empty work to HAL to wake up allocation thread
repopick 342863 # CCodec: Use pipelineRoom only for HW decoder
repopick 342864 # codec2: Change a Info print into Verbose

cd build/patches
bash apply-patches.sh
cd ../../
echo
}
  
buildRom() {
echo "-->> Building rom"
lunch lineage_${devices}-userdebug
m installclean
mka bacon -j8
echo
}
# Build
#for device in ${devices[@]}; do
#    echo "Build for ${device}"
#    sleep 3
#    mka_build ${device} -r
#done

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"

initRepos
syncRepos
setupEnv
applyPatches
buildRom


END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Build script for $devices completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
