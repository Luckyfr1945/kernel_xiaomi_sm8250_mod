#!/bin/bash
set -e

# Universal Builder for Ki-kernel SM8250 (munch)
# Builds both AOSP and MIUI/HyperOS kernels and packs into a Single Universal AnyKernel3 Zip

TARGET_DEVICE="munch"
KERNEL_NAME="Ki-kernel"
KERNEL_VERSION="v1.3"
BUILD_DATETIME=$(date +'%Y%m%d_%H%M')

export ARCH=arm64
export SUBARCH=arm64
export HEADER_ARCH=arm64
export KBUILD_BUILD_USER="build-user"
export KBUILD_BUILD_HOST="build-host 4.19.404R"

# Set up Clang toolchain
export PATH="/home/kiki/kernel/neutron-clang/bin:$PATH"

MAKE_ARGS="O=out ARCH=arm64 CC=clang \
CLANG_TRIPLE=aarch64-linux-gnu- \
CROSS_COMPILE=aarch64-linux-gnu- \
CROSS_COMPILE_ARM32=arm-linux-gnueabi- \
LLVM=1 LLVM_IAS=1"

VARIANT_ARG="${1:-ksu}"
KSU_ENABLE=1
SUSFS_ENABLE=1
VARIANT_TAG="ReSukiSU+SUSFS"

case "$VARIANT_ARG" in
    ksu|ksu-susfs|susfs)
        KSU_ENABLE=1
        SUSFS_ENABLE=1
        VARIANT_TAG="ReSukiSU+SUSFS"
        ;;
    ksu-nosusfs|nosusfs|plain)
        KSU_ENABLE=1
        SUSFS_ENABLE=0
        VARIANT_TAG="ReSukiSU"
        ;;
    noksu|vanilla|none)
        KSU_ENABLE=0
        SUSFS_ENABLE=0
        VARIANT_TAG="NoKSU"
        ;;
    *)
        echo "Unknown variant: $VARIANT_ARG. Defaulting to ReSukiSU+SUSFS."
        ;;
esac

echo "=========================================================="
echo "Starting Universal Build: $KERNEL_NAME $KERNEL_VERSION"
echo "Variant: $VARIANT_TAG"
echo "=========================================================="

rm -rf build_artifacts
mkdir -p build_artifacts/aosp build_artifacts/miui

# ------------------------------------------------------------
# 1. BUILD FOR AOSP
# ------------------------------------------------------------
echo ""
echo ">>> [1/2] Compiling AOSP Kernel <<<"
rm -rf out/

local_version_date_str="-${BUILD_DATETIME}-${KERNEL_NAME}-${KERNEL_VERSION}"
sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"${local_version_date_str}\"/" arch/arm64/configs/${TARGET_DEVICE}_defconfig

make $MAKE_ARGS ${TARGET_DEVICE}_defconfig

if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config -e KSU -e THREAD_INFO_IN_TASK
    if [ $SUSFS_ENABLE -eq 1 ]; then
        scripts/config --file out/.config -e KSU_SUSFS
    else
        scripts/config --file out/.config -d KSU_SUSFS
    fi
else
    scripts/config --file out/.config -d KSU -d KSU_SUSFS
fi

make $MAKE_ARGS olddefconfig
make $MAKE_ARGS KCFLAGS="-O2" -j$(nproc)

# DTB Extreme & Stock for AOSP
cp -f arch/arm64/boot/dts/gpu_profiles/kona-v2-gpu-extreme.dtsi arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi
rm -rf out/arch/arm64/boot/dts
make $MAKE_ARGS dtbs -j$(nproc)
find out/arch/arm64/boot/dts -name '*.dtb' | sort | xargs cat > out/arch/arm64/boot/dtb_extreme
cp -f out/arch/arm64/boot/dtb_extreme out/arch/arm64/boot/dtb

cp -f arch/arm64/boot/dts/gpu_profiles/kona-v2-gpu-stock.dtsi arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi
rm -rf out/arch/arm64/boot/dts
make $MAKE_ARGS dtbs -j$(nproc)
find out/arch/arm64/boot/dts -name '*.dtb' | sort | xargs cat > out/arch/arm64/boot/dtb_stock
cp -f out/arch/arm64/boot/dtb_stock out/arch/arm64/boot/dtb

# Save AOSP artifacts
cp out/arch/arm64/boot/Image build_artifacts/aosp/Image
cp out/arch/arm64/boot/dtb build_artifacts/aosp/dtb
cp out/arch/arm64/boot/dtbo.img build_artifacts/aosp/dtbo.img
cp out/arch/arm64/boot/dtb_extreme build_artifacts/aosp/dtb_extreme
cp out/arch/arm64/boot/dtb_stock build_artifacts/aosp/dtb_stock
echo ">>> AOSP Kernel Built Successfully! <<<"

# ------------------------------------------------------------
# 2. BUILD FOR MIUI / HyperOS
# ------------------------------------------------------------
echo ""
echo ">>> [2/2] Compiling MIUI / HyperOS Kernel <<<"
rm -rf out/

# Apply MIUI display panel DTS patch
dts_source="arch/arm64/boot/dts/vendor/qcom"
rm -rf .dts.bak 2>/dev/null || true
cp -r ${dts_source} .dts.bak

sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 00 00 00 00 00 05 51 0F 8F 00 00/39 00 00 00 00 00 05 51 0F 8F 00 00/g' ${dts_source}/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 00 00/39 01 00 00 00 00 03 51 00 00/g' ${dts_source}/dsi-panel-j2-38-0c-0a-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 03 FF/39 01 00 00 00 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j9-38-0a-0a-fhd-video.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 07 FF/39 01 00 00 00 00 03 51 07 FF/g' ${dts_source}/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j1u-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j2-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 03 51 0F FF/39 01 00 00 00 00 03 51 0F FF/g' ${dts_source}/dsi-panel-j2-p1-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j1s-42-02-0a-mp-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2-mp-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2-p2-1-42-02-0b-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 00 00 05 51 07 FF 00 00/39 01 00 00 00 00 05 51 07 FF 00 00/g' ${dts_source}/dsi-panel-j2s-mp-42-02-0a-dsc-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 01 00 03 51 03 FF/39 01 00 00 01 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j11-38-08-0a-fhd-cmd.dtsi 2>/dev/null || true
sed -i 's/\/\/39 01 00 00 11 00 03 51 03 FF/39 01 00 00 11 00 03 51 03 FF/g' ${dts_source}/dsi-panel-j2-p2-1-38-0c-0a-dsc-cmd.dtsi 2>/dev/null || true

make $MAKE_ARGS ${TARGET_DEVICE}_defconfig

if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config -e KSU -e THREAD_INFO_IN_TASK
    if [ $SUSFS_ENABLE -eq 1 ]; then
        scripts/config --file out/.config -e KSU_SUSFS
    else
        scripts/config --file out/.config -d KSU_SUSFS
    fi
else
    scripts/config --file out/.config -d KSU -d KSU_SUSFS
fi

scripts/config --file out/.config \
    --set-str STATIC_USERMODEHELPER_PATH /system/bin/micd \
    -e PERF_CRITICAL_RT_TASK \
    -e SF_BINDER \
    -e OVERLAY_FS \
    -d DEBUG_FS \
    -e MIGT \
    -e MIGT_ENERGY_MODEL \
    -e MIHW \
    -e PACKAGE_RUNTIME_INFO \
    -e BINDER_OPT \
    -e KPERFEVENTS \
    -e MILLET \
    -e PERF_HUMANTASK \
    -d LTO_CLANG \
    -d LOCALVERSION_AUTO \
    -e SF_BINDER \
    -e XIAOMI_MIUI \
    -d MI_MEMORY_SYSFS \
    -e TASK_DELAY_ACCT \
    -e MIUI_ZRAM_MEMORY_TRACKING \
    -d CONFIG_MODULE_SIG_SHA512 \
    -d CONFIG_MODULE_SIG_HASH \
    -e MI_FRAGMENTION \
    -e PERF_HELPER \
    -e BOOTUP_RECLAIM \
    -e MI_RECLAIM \
    -e RTMM \
    -e SCHED_HRTICK \
    -d CORESIGHT \
    -d IPC_LOGGING \
    -d SCHEDSTATS \
    -d DEBUG_INFO

make $MAKE_ARGS olddefconfig
make $MAKE_ARGS KCFLAGS="-O2" -j$(nproc)

# DTB Extreme & Stock for MIUI
cp -f arch/arm64/boot/dts/gpu_profiles/kona-v2-gpu-extreme.dtsi arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi
rm -rf out/arch/arm64/boot/dts
make $MAKE_ARGS dtbs -j$(nproc)
find out/arch/arm64/boot/dts -name '*.dtb' | sort | xargs cat > out/arch/arm64/boot/dtb_extreme
cp -f out/arch/arm64/boot/dtb_extreme out/arch/arm64/boot/dtb

cp -f arch/arm64/boot/dts/gpu_profiles/kona-v2-gpu-stock.dtsi arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi
rm -rf out/arch/arm64/boot/dts
make $MAKE_ARGS dtbs -j$(nproc)
find out/arch/arm64/boot/dts -name '*.dtb' | sort | xargs cat > out/arch/arm64/boot/dtb_stock

# Restore DTS source
rm -rf ${dts_source}
mv .dts.bak ${dts_source}

# Save MIUI artifacts
cp out/arch/arm64/boot/Image build_artifacts/miui/Image
cp out/arch/arm64/boot/dtb_stock build_artifacts/miui/dtb
cp out/arch/arm64/boot/dtbo.img build_artifacts/miui/dtbo.img
cp out/arch/arm64/boot/dtb_extreme build_artifacts/miui/dtb_extreme
cp out/arch/arm64/boot/dtb_stock build_artifacts/miui/dtb_stock
echo ">>> MIUI / HyperOS Kernel Built Successfully! <<<"

# ------------------------------------------------------------
# 3. PACKAGING UNIVERSAL ANYKERNEL3 ZIP
# ------------------------------------------------------------
echo ""
echo ">>> [3/3] Assembling Universal Dual-OS AnyKernel3 Zip <<<"
rm -rf anykernel/
git clone https://github.com/AstideLabs/AnyKernel3 -b kona --single-branch --depth=1 anykernel

mkdir -p anykernel/kernels/aosp anykernel/kernels/miui

cp -r build_artifacts/aosp/* anykernel/kernels/aosp/
cp -r build_artifacts/miui/* anykernel/kernels/miui/

cp -f anykernel_template/anykernel.sh anykernel/anykernel.sh

cd anykernel
UNIVERSAL_ZIP="${VARIANT_TAG}_Ki-kernel-Universal-${KERNEL_VERSION}_$(date +'%Y%m%d_%H%M%S').zip"
zip -r9 "$UNIVERSAL_ZIP" ./* -x .git .gitignore out/ ./*.zip
mv "$UNIVERSAL_ZIP" ../
cd ..

echo "=========================================================="
echo "UNIVERSAL DUAL-OS BUILD COMPLETED SUCCESSFULLY!"
echo "Flashable on BOTH AOSP (crDroid, Lunaris, Lineage) and MIUI / HyperOS!"
echo "Package: [./$UNIVERSAL_ZIP]"
echo "=========================================================="
