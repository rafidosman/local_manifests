#!/bin/bash

# Build script for my build "for personal usage only"

devices=(
    "pstar"
)

## Sync
# Init Evolution-X repos
repo init -u https://github.com/Evolution-X/manifest -b tiramisu

#remove sync project from Evolution-X manifest
sed -i "/\platform\/hardware\/qcom\/sm7250\/media/d" .repo/manifests/default.xml
sed -i "/\platform\/hardware\/qcom\/sm7250\/display/d" .repo/manifests/default.xml
sed -i "/\platform\/hardware\/qcom\/sm8150\/media/d" .repo/manifests/default.xml
sed -i "/\platform\/hardware\/qcom\/sm8150\/display/d" .repo/manifests/default.xml
sed -i "/\platform\/hardware\/qcom\/sm8150\/data\/ipacfg-mgr/d" .repo/manifests/default.xml
sed -i "/\platform\/hardware\/google\/pixel/d" .repo/manifests/default.xml
sed -i "/\platform\/hardware\/google\/pixel-sepolicy/d" .repo/manifests/default.xml

# Add local_manifests
rm -rf .repo/local_manifests
mkdir -p .repo/local_manifests
curl https://raw.githubusercontent.com/rafidosman/local_manifests/main/evo.xml -o .repo/local_manifests/evo.xml

# Sync
repo sync -c --force-sync --no-clone-bundle --no-tags -j$(nproc --all)

## Build
# Init envsetup
#. vendor/extra/build/envsetup.sh -p
. build/envsetup.sh
lunch evolution_redfin_userdebug
make -j$(nproc --all) installclean
mka evolution
# Build
#for device in ${devices[@]}; do
#    echo "Build for ${device}"
#    sleep 3
#    mka_build ${device} -r
#done

START=`date +%s`
BUILD_DATE="$(date +%Y%m%d)"


END=`date +%s`
ELAPSEDM=$(($(($END-$START))/60))
ELAPSEDS=$(($(($END-$START))-$ELAPSEDM*60))

echo "--> Build script completed in $ELAPSEDM minutes and $ELAPSEDS seconds"
echo
