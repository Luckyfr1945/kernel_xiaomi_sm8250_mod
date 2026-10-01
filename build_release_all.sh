#!/bin/bash
set -e

DEVICE="munch"
RELEASE_DIR="release"

mkdir -p "$RELEASE_DIR"
rm -f rilis
ln -sfn "$RELEASE_DIR" rilis

echo "=========================================================="
echo "Starting Full Release Build for: $DEVICE"
echo "Output directory: $RELEASE_DIR/ (or rilis/)"
echo "=========================================================="

build_variant() {
    local type="$1"     # miui or aosp
    local variant="$2"  # noksu, nosusfs, or ksu
    local desc="$3"
    
    echo ""
    echo ">>> Building [$type] [$variant] - $desc <<<"
    
    if [ "$type" == "miui" ]; then
        bash build_miui.sh "$DEVICE" "$variant"
    else
        bash build_aosp.sh "$DEVICE" "$variant"
    fi
    
    # Move newly created zip to release folder
    LATEST_ZIP=$(ls -t *Ki-kernel-${type^^}-*.zip 2>/dev/null | head -n 1)
    if [ -n "$LATEST_ZIP" ] && [ -f "$LATEST_ZIP" ]; then
        echo "Moving $LATEST_ZIP to $RELEASE_DIR/"
        mv "$LATEST_ZIP" "$RELEASE_DIR/"
    else
        echo "Warning: Could not find newly built zip matching *Ki-kernel-${type^^}-*.zip in root"
    fi
}

# 1. MIUI / HyperOS Builds (noksu and nosusfs already completed)
# build_variant miui noksu "Vanilla (No KernelSU, No SuSFS)"
# build_variant miui nosusfs "ReSukiSU Standard"
build_variant miui ksu "ReSukiSU (v4.2.0-rc3) + SuSFS v2.3.0"

# 2. AOSP / Custom ROM Builds
build_variant aosp noksu "Vanilla (No KernelSU, No SuSFS)"
build_variant aosp nosusfs "ReSukiSU Standard"
build_variant aosp ksu "ReSukiSU (v4.2.0-rc3) + SuSFS v2.3.0"

echo ""
echo "=========================================================="
echo "ALL BUILDS COMPLETED SUCCESSFULLY!"
echo "Generated release packages in ./$RELEASE_DIR:"
ls -lh "$RELEASE_DIR"/*v1.3*.zip 2>/dev/null || ls -lh "$RELEASE_DIR"

echo ""
echo "Calculating SHA256 checksums for today's v1.3 release..."
cd "$RELEASE_DIR"
TODAY=$(date +'%Y%m%d')
sha256sum *Ki-kernel-*-v1.3_${TODAY}_*.zip 2>/dev/null | tee sha256_v1.3_${TODAY}.txt
cd ..
echo "=========================================================="
