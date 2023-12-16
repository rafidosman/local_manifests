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

repopick 340916 # SystemUI: add burnIn protection
repopick 342860 # codec2: Use numClientBuffers to control the pipeline
repopick 342861 # CCodec: Control the inputs to avoid pipeline overflow
repopick 342862 # [WA] Codec2: queue a empty work to HAL to wake up allocation thread
repopick 342863 # CCodec: Use pipelineRoom only for HW decoder
repopick 342864 # codec2: Change a Info print into Verbose

# Temporarily revert "13-firewall" changes
#(cd frameworks/base; git revert e91d98e3327a805d1914e7fb1617f3ac081c0689^..cfd9c1e4c8ea855409db5a1ed8f84f4287a37d75 --no-edit)
#(cd packages/apps/Settings; git revert 406607e0c16ed23d918c68f14eb4576ce411bb73 --no-edit)
#(cd packages/modules/Connectivity; git revert 386950b4ea592f2a8e4937444955c9b91ff1f277^..1fa42c03891ba203a321b597fb5709e3a9131f0e --no-edit)
#(cd system/netd; git revert dbf5d67951a0cd6e9b76ca2c08cf2b39ae6d708d^..5c89ab94a797fce13bf858be0f96541bf9f3bfe7 --no-edit)

cd build/patches
bash apply-patches.sh
cd ../../
echo
}

signBuild()  {
echo "-->> signing build" 
rm -rf /home/fido/test/keys
bash /home/fido/init.sh
cp -r /home/fido/test/keys lineageos20/vendor/extra/ 
sed -i "1s;^;PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/extra/keys/releasekey\nPRODUCT_OTA_PUBLIC_KEYS := vendor/extra/keys/releasekey\n\n;" "vendor/lineage/config/common.mk"
sed -i "1s;^;PRODUCT_DEFAULT_DEV_CERTIFICATE := vendor/extra/keys/releasekey\nPRODUCT_OTA_PUBLIC_KEYS := vendor/extra/keys/releasekey\n\n;" "vendor/extra/product.mk" 
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
