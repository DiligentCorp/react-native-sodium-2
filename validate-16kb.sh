#!/bin/bash

# Script to validate 16KB page size compatibility
# Run this after building your APK

set -e

APK_PATH="${1:-app/build/outputs/apk/release/app-release.apk}"
SDK_ROOT="${ANDROID_HOME:-$ANDROID_SDK_ROOT}"

if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK file not found at $APK_PATH"
    echo "Usage: $0 [path_to_apk]"
    exit 1
fi

if [ -z "$SDK_ROOT" ]; then
    echo "Error: ANDROID_HOME or ANDROID_SDK_ROOT environment variable not set"
    exit 1
fi

echo "Validating 16KB compatibility for: $APK_PATH"

# Create temporary directory
TEMP_DIR=$(mktemp -d)
echo "Using temp directory: $TEMP_DIR"

# Extract APK
echo "Extracting APK..."
unzip -q "$APK_PATH" -d "$TEMP_DIR"

# Check if lib directory exists
if [ ! -d "$TEMP_DIR/lib" ]; then
    echo "✅ No native libraries found - app should be 16KB compatible"
    rm -rf "$TEMP_DIR"
    exit 0
fi

echo "Found native libraries. Checking alignment..."

# Find the latest build-tools version
BUILD_TOOLS_VERSION=$(ls "$SDK_ROOT/build-tools" | sort -V | tail -1)
ZIPALIGN="$SDK_ROOT/build-tools/$BUILD_TOOLS_VERSION/zipalign"

if [ ! -f "$ZIPALIGN" ]; then
    echo "Error: zipalign not found at $ZIPALIGN"
    exit 1
fi

# Check APK alignment
echo "Checking APK alignment..."
if "$ZIPALIGN" -c -P 16 -v 4 "$APK_PATH"; then
    echo "✅ APK is properly 16KB aligned"
    APK_ALIGNED=true
else
    echo "❌ APK is NOT properly 16KB aligned"
    APK_ALIGNED=false
fi

# Check individual .so files
echo "Checking individual shared libraries..."
NDK_PATH="${ANDROID_NDK_HOME:-$ANDROID_HOME/ndk/28.0.12674087}"
OBJDUMP="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump"

if [ ! -f "$OBJDUMP" ]; then
    echo "Warning: llvm-objdump not found at $OBJDUMP"
    echo "Cannot verify ELF segment alignment"
else
    ALL_ALIGNED=true
    for so_file in $(find "$TEMP_DIR/lib" -name "*.so"); do
        echo "Checking $(basename $so_file)..."
        
        # Check LOAD segment alignment
        LOAD_SEGMENTS=$("$OBJDUMP" -p "$so_file" | grep "LOAD.*align" || true)
        
        if [ -n "$LOAD_SEGMENTS" ]; then
            while IFS= read -r line; do
                # Extract alignment value (e.g., "align 2**14" -> 14)
                ALIGN=$(echo "$line" | grep -o 'align 2\*\*[0-9]*' | grep -o '[0-9]*$')
                if [ -n "$ALIGN" ] && [ "$ALIGN" -lt 14 ]; then
                    echo "  ❌ $(basename $so_file): Segment alignment 2**$ALIGN is less than 2**14 (16KB)"
                    ALL_ALIGNED=false
                else
                    echo "  ✅ $(basename $so_file): Segment alignment 2**$ALIGN is 16KB compatible"
                fi
            done <<< "$LOAD_SEGMENTS"
        else
            echo "  ⚠️  $(basename $so_file): No LOAD segments found"
        fi
    done
    
    if [ "$ALL_ALIGNED" = true ]; then
        echo "✅ All shared libraries have proper 16KB ELF alignment"
    else
        echo "❌ Some shared libraries need to be rebuilt with 16KB alignment"
    fi
fi

# Cleanup
rm -rf "$TEMP_DIR"

# Final result
if [ "$APK_ALIGNED" = true ] && [ "$ALL_ALIGNED" = true ]; then
    echo ""
    echo "🎉 Your app appears to be 16KB page size compatible!"
    echo "Consider testing on a 16KB emulator to verify functionality."
else
    echo ""
    echo "❌ Your app needs updates for 16KB page size compatibility."
    echo "Please follow the steps in the README to fix the issues."
fi