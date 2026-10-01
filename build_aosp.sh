#!/bin/bash

# Build script specifically for AOSP / Custom ROM (LineageOS, AxionOS, etc.)
# Munch (POCO F4 / Redmi K40S) & other SM8250 devices

set -e


TARGET_DEVICE=$1

if [ -z "$1" ]; then
    echo "Error: No argument provided, please specify a target device." 
    echo "Usage: bash build_aosp.sh <target_device> [variant]"
    echo ""
    echo "Available variants:"
    echo "  1) ksu (or ksu-susfs)   : ReSukiSU (v4.2.0-rc3) + SuSFS v2.3.0 (Recommended for root stealth)"
    echo "  2) nosusfs (or plain)   : ReSukiSU Standard (No SuSFS)"
    echo "  3) noksu (or vanilla)   : Vanilla Kernel (No KernelSU, No SuSFS)"
    echo ""
    echo "Examples:"
    echo "    bash build_aosp.sh munch ksu"
    echo "    bash build_aosp.sh munch nosusfs"
    echo "    bash build_aosp.sh munch noksu"
    exit 1
fi

ZYC_PATH=$HOME/zyc-clang/bin
NEUTRON_PATH=$HOME/neutron-clang/bin
PROTON_PATH=$HOME/proton-clang/proton-clang-20210522/bin

if [ -d "$ZYC_PATH" ]; then
    export PATH="$ZYC_PATH:$PATH"
    echo "Using Toolchain: ZyCromerZ Clang 16 ($ZYC_PATH)"
elif [ -d "$NEUTRON_PATH" ]; then
    export PATH="$NEUTRON_PATH:$PATH"
    echo "Using Toolchain: Neutron Clang ($NEUTRON_PATH)"
elif [ -d "$PROTON_PATH" ]; then
    export PATH="$PROTON_PATH:$PATH"
    echo "Using Toolchain: Proton Clang ($PROTON_PATH)"
else
    echo "Error: Neither ZyCromerZ, Neutron, nor Proton Clang found."
    exit 1
fi

if ! command -v aarch64-linux-gnu-ld >/dev/null 2>&1; then
    echo "[aarch64-linux-gnu-ld] does not exist, please check your environment."
    exit 1
fi

if ! command -v arm-linux-gnueabi-ld >/dev/null 2>&1; then
    echo "[arm-linux-gnueabi-ld] does not exist, please check your environment."
    exit 1
fi

if ! command -v clang >/dev/null 2>&1; then
    echo "[clang] does not exist, please check your environment."
    exit 1
fi

# Enable ccache for fast compiling
export CCACHE_DIR="$HOME/.cache/ccache_mikernel" 
export CC="ccache gcc"
export CXX="ccache g++"
export PATH="/usr/lib/ccache/bin:/usr/lib/ccache:$PATH"
echo "CCACHE_DIR: [$CCACHE_DIR]"

export KBUILD_BUILD_USER="build-user"
export KBUILD_BUILD_HOST="build-host 4.19.404R"

MAKE_ARGS="ARCH=arm64 SUBARCH=arm64 O=out CC=clang HOSTCC=$PWD/tools/hostcc HOSTLD=/usr/bin/ld.bfd CROSS_COMPILE=aarch64-linux-gnu- CROSS_COMPILE_ARM32=arm-linux-gnueabi- CROSS_COMPILE_COMPAT=arm-linux-gnueabi- CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1"

if [ "$1" == "j1" ]; then
    make $MAKE_ARGS -j1
    exit 0
fi

if [ "$1" == "continue" ]; then
    make $MAKE_ARGS -j$(nproc)
    exit 0
fi

if [ ! -f "arch/arm64/configs/${TARGET_DEVICE}_defconfig" ]; then
    echo "No target device [${TARGET_DEVICE}] found."
    echo "Available defconfigs:"
    ls arch/arm64/configs/*_defconfig
    exit 1
fi

echo "[clang --version]:"
clang --version

KSU_ENABLE=0
SUSFS_ENABLE=0
VARIANT_TAG="NoKSU"

case "$2" in
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
    noksu|vanilla|none|"")
        KSU_ENABLE=0
        SUSFS_ENABLE=0
        VARIANT_TAG="NoKSU"
        ;;
    *)
        echo "Unknown variant: $2. Falling back to ReSukiSU+SUSFS."
        KSU_ENABLE=1
        SUSFS_ENABLE=1
        VARIANT_TAG="ReSukiSU+SUSFS"
        ;;
esac

echo "TARGET_DEVICE: $TARGET_DEVICE"
if [ $KSU_ENABLE -eq 1 ] && [ $SUSFS_ENABLE -eq 1 ]; then
    echo "Variant: ReSukiSU (v4.2.0-rc3) + SuSFS v2.3.0 is enabled"
elif [ $KSU_ENABLE -eq 1 ]; then
    echo "Variant: ReSukiSU (v4.2.0-rc3) Standard (Non-SUSFS) is enabled"
else
    echo "Variant: Vanilla (No KernelSU, No SuSFS) is enabled"
fi

echo "Cleaning..."
rm -rf out/
rm -rf anykernel/

echo "Clone AnyKernel3 for packing kernel (repo: https://github.com/AstideLabs/AnyKernel3)"
git clone https://github.com/AstideLabs/AnyKernel3 -b kona --single-branch --depth=1 anykernel

# Add date, time, kernel name, and version to local version
KERNEL_NAME="Ki-kernel"
KERNEL_VERSION="v1.4"
BUILD_DATETIME=$(date +'%Y%m%d_%H%M')


export KBUILD_BUILD_USER="build-user"
export KBUILD_BUILD_HOST="build-host 4.19.404R"

local_version_date_str="-${BUILD_DATETIME}-${KERNEL_NAME}-${KERNEL_VERSION}"

sed -i "s/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=\"${local_version_date_str}\"/" arch/arm64/configs/${TARGET_DEVICE}_defconfig

# ------------- Building for AOSP -------------

echo "Building for AOSP......"
make $MAKE_ARGS ${TARGET_DEVICE}_defconfig
if [ $KSU_ENABLE -eq 1 ]; then
    scripts/config --file out/.config \
        -e KSU \
        -e THREAD_INFO_IN_TASK \
        -d KSU_KPROBES_HOOK \
        -d KSU_DEBUG \
        -d KSU_TRACEPOINT_HOOK \
        -e KSU_THRONE_TRACKER_ALWAYS_THREADED \
        -d KSU_ALLOWLIST_WORKAROUND \
        -e KSU_LSM_SECURITY_HOOKS \
        -d KSU_MANUAL_HOOK \
        -e KSU_SUSFS

    if [ $SUSFS_ENABLE -eq 1 ]; then
        scripts/config --file out/.config \
            -e KSU_SUSFS_SUS_PATH \
            -e KSU_SUSFS_SUS_MAP \
            -e KSU_SUSFS_SUS_NETLINK \
            -e KSU_SUSFS_AUTO_ADD_SUS_KSURULES \
            -e KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT \
            -e KSU_SUSFS_SUS_SU \
            -e KSU_SUSFS_SUS_MOUNT \
            -e KSU_SUSFS_SUS_KSTAT \
            -e KSU_SUSFS_SPOOF_UNAME \
            -e KSU_SUSFS_ENABLE_LOG \
            -e KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
            -e KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
            -e KSU_SUSFS_OPEN_REDIRECT \
            -e KSU_SUSFS_SUS_OVERLAYFS
    else
        scripts/config --file out/.config \
            -d KSU_SUSFS_SUS_PATH \
            -d KSU_SUSFS_SUS_MAP \
            -d KSU_SUSFS_SUS_NETLINK \
            -d KSU_SUSFS_AUTO_ADD_SUS_KSURULES \
            -d KSU_SUSFS_AUTO_ADD_SUS_BIND_MOUNT \
            -d KSU_SUSFS_SUS_SU \
            -d KSU_SUSFS_SUS_MOUNT \
            -d KSU_SUSFS_SUS_KSTAT \
            -d KSU_SUSFS_SPOOF_UNAME \
            -d KSU_SUSFS_ENABLE_LOG \
            -d KSU_SUSFS_HIDE_KSU_SUSFS_SYMBOLS \
            -d KSU_SUSFS_SPOOF_CMDLINE_OR_BOOTCONFIG \
            -d KSU_SUSFS_OPEN_REDIRECT \
            -d KSU_SUSFS_SUS_OVERLAYFS
    fi
else
    scripts/config --file out/.config \
        -d KSU \
        -d KSU_MANUAL_HOOK \
        -d KSU_TRACEPOINT_HOOK \
        -d KSU_SUSFS
fi

make $MAKE_ARGS olddefconfig

make $MAKE_ARGS KCFLAGS="-O2" -j$(nproc)

if [ -f "out/arch/arm64/boot/Image" ]; then
    echo "The file [out/arch/arm64/boot/Image] exists. AOSP Build successfully."
else
    echo "The file [out/arch/arm64/boot/Image] does not exist. Seems AOSP build failed."
    exit 1
fi

echo "Generating [out/arch/arm64/boot/dtb] (150MHz - 683MHz OC + UV)......"
cp -f arch/arm64/boot/dts/gpu_profiles/kona-v2-gpu-extreme.dtsi arch/arm64/boot/dts/vendor/qcom/kona-v2-gpu.dtsi
rm -rf out/arch/arm64/boot/dts
make $MAKE_ARGS dtbs -j$(nproc)
find out/arch/arm64/boot/dts -name '*.dtb' | sort | xargs cat >out/arch/arm64/boot/dtb

rm -rf anykernel/kernels/ anykernel/dtbs/
mkdir -p anykernel/kernels/aosp/

cp out/arch/arm64/boot/Image anykernel/kernels/aosp/Image
cp out/arch/arm64/boot/dtb anykernel/kernels/aosp/dtb
cp -f out/arch/arm64/boot/Image anykernel/Image 2>/dev/null || true
cp -f out/arch/arm64/boot/dtb anykernel/dtb 2>/dev/null || true
# DO NOT include dtbo (preserve panel and touchscreen drivers)
rm -f anykernel/dtbo.img anykernel/kernels/aosp/dtbo.img 2>/dev/null
cp -f anykernel_template/anykernel.sh anykernel/anykernel.sh

cd anykernel 

ZIP_FILENAME="${VARIANT_TAG}_Ki-kernel-AOSP-${KERNEL_VERSION}_$(date +'%Y%m%d_%H%M%S').zip"

zip -r9 "$ZIP_FILENAME" ./* -x .git .gitignore out/ ./*.zip

mv "$ZIP_FILENAME" ../

cd ..

echo "=========================================================="
echo "AOSP Build Finished Successfully!"
echo "The flashable zip is: [./$ZIP_FILENAME]"
echo "=========================================================="
