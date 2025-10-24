#!/bin/bash

# Build script for react-native-sodium with 16KB page size support
# This ensures compatibility with Android's 16KB page size requirement

sigfile=`ls -1 libsodium-*-stable.tar.gz.minisig`
srcfile=`basename $sigfile .minisig`
srcdir='libsodium-stable'

# Check for required environment variables
if [ -z "$ANDROID_NDK_HOME" ] && [ -z "$ANDROID_HOME" ]; then
    echo "Error: ANDROID_NDK_HOME or ANDROID_HOME must be set"
    echo "Please set one of these environment variables to point to your Android SDK/NDK"
    exit 1
fi

# Set NDK path (prefer ANDROID_NDK_HOME, fallback to ANDROID_HOME/ndk/latest)
if [ -n "$ANDROID_NDK_HOME" ]; then
    NDK_PATH="$ANDROID_NDK_HOME"
else
    # Find the latest NDK version
    NDK_VERSIONS=$(ls -1 "$ANDROID_HOME/ndk" 2>/dev/null | sort -V)
    if [ -z "$NDK_VERSIONS" ]; then
        echo "Error: No NDK found in $ANDROID_HOME/ndk"
        exit 1
    fi
    LATEST_NDK=$(echo "$NDK_VERSIONS" | tail -1)
    NDK_PATH="$ANDROID_HOME/ndk/$LATEST_NDK"
fi

echo "Using NDK at: $NDK_PATH"

# Check NDK version for 16KB support
NDK_VERSION_FILE="$NDK_PATH/source.properties"
if [ -f "$NDK_VERSION_FILE" ]; then
    NDK_VERSION=$(grep "Pkg.Revision" "$NDK_VERSION_FILE" | cut -d'=' -f2 | tr -d ' ')
    echo "NDK Version: $NDK_VERSION"
    
    # Extract major version (e.g., "28.0.12674087" -> "28")
    NDK_MAJOR=$(echo "$NDK_VERSION" | cut -d'.' -f1)
    
    if [ "$NDK_MAJOR" -lt 27 ]; then
        echo "Warning: NDK version $NDK_VERSION is older than r27."
        echo "For best 16KB support, please upgrade to NDK r28 or later."
        echo "Continuing with manual 16KB flags..."
        USE_MANUAL_16KB_FLAGS=true
    else
        echo "NDK version $NDK_VERSION supports 16KB page sizes."
        USE_MANUAL_16KB_FLAGS=false
    fi
else
    echo "Warning: Could not determine NDK version. Assuming manual 16KB flags needed."
    USE_MANUAL_16KB_FLAGS=true
fi

# --------------------------
# Download and verify source
# --------------------------
[ -f $srcfile ] && rm -f $srcfile
curl https://download.libsodium.org/libsodium/releases/$srcfile > $srcfile
minisign -P "RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3" -Vm $srcfile || exit 1

# --------------------------
# Extract sources
# --------------------------
[ -e $srcdir ] && rm -Rf $srcdir
tar -xzf $srcfile
cd $srcdir

# Set up 16KB page size environment variables
export ANDROID_NDK_HOME="$NDK_PATH"

# Set 16KB linker flags
if [ "$USE_MANUAL_16KB_FLAGS" = true ]; then
    echo "Adding manual 16KB page size flags..."
    export LDFLAGS_16KB="-Wl,-z,max-page-size=16384"
    
    # For very old NDKs (r22 and below), also add common-page-size
    if [ "$NDK_MAJOR" -lt 23 ]; then
        export LDFLAGS_16KB="$LDFLAGS_16KB -Wl,-z,common-page-size=16384"
        echo "Adding common-page-size flag for NDK r22 and below"
    fi
else
    echo "Using NDK default 16KB support (r28+)"
    export LDFLAGS_16KB=""
fi

targetPlatforms="$@"
[ "$targetPlatforms" ] || targetPlatforms="arm x86 ios"

for targetPlatform in $targetPlatforms
do
  # --------------------------
  # iOS build
  # --------------------------
  platform=`uname`
  if [ "$platform" == 'Darwin' ] && [ "$targetPlatform" == 'ios' ]; then
    IOS_VERSION_MIN=10.0.0 dist-build/apple-xcframework.sh
  fi

  # --------------------------
  # Android build with 16KB page size support
  # --------------------------
  case $targetPlatform in
    "arm-old")
      echo "Building for arm-old with 16KB support..."
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-arm.sh
      ;;
    "arm")
      echo "Building for arm/arm64 with 16KB support..."
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-armv7-a.sh
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-armv8-a.sh
      ;;
    "mips")
      echo "Building for mips with 16KB support..."
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-mips32.sh
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-mips64.sh
      ;;
    "x86")
      echo "Building for x86/x86_64 with 16KB support..."
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-x86.sh
      NDK_PLATFORM=android-21 LDFLAGS="$LDFLAGS_16KB" dist-build/android-x86_64.sh
    ;;
  esac

done
cd ..


# --------------------------
# Move compiled libraries
# --------------------------
echo "Moving compiled libraries..."
mkdir -p libsodium
rm -Rf libsodium/*

for dir in $srcdir/libsodium-android-*
do
  if [ -d "$dir" ]; then
    echo "Moving $(basename $dir)..."
    mv $dir libsodium/
  fi
done

if [ "$platform" == 'Darwin' ] && [ -e $srcdir/libsodium-apple ]; then
  echo "Moving libsodium-apple..."
  echo $PWD
  mv $srcdir/libsodium-apple libsodium/
fi

# --------------------------
# Validate 16KB alignment
# --------------------------
echo "Validating 16KB alignment of compiled libraries..."
VALIDATION_FAILED=false

for so_file in $(find libsodium -name "*.so" 2>/dev/null); do
    if [ -f "$so_file" ]; then
        echo "Checking $(basename $so_file)..."
        
        # Use objdump to check alignment if available
        OBJDUMP="$NDK_PATH/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump"
        if [ -f "$OBJDUMP" ]; then
            LOAD_SEGMENTS=$("$OBJDUMP" -p "$so_file" | grep "LOAD.*align" || true)
            
            if [ -n "$LOAD_SEGMENTS" ]; then
                while IFS= read -r line; do
                    ALIGN=$(echo "$line" | grep -o 'align 2\*\*[0-9]*' | grep -o '[0-9]*$')
                    if [ -n "$ALIGN" ] && [ "$ALIGN" -lt 14 ]; then
                        echo "  ❌ WARNING: $(basename $so_file) has alignment 2**$ALIGN (less than 2**14 for 16KB)"
                        VALIDATION_FAILED=true
                    else
                        echo "  ✅ $(basename $so_file) has proper 16KB alignment (2**$ALIGN)"
                    fi
                done <<< "$LOAD_SEGMENTS"
            fi
        else
            echo "  ⚠️  Cannot validate alignment (llvm-objdump not found)"
        fi
    fi
done

if [ "$VALIDATION_FAILED" = true ]; then
    echo ""
    echo "❌ WARNING: Some libraries may not have proper 16KB alignment!"
    echo "This could cause issues on Android devices with 16KB page sizes."
    echo "Consider upgrading to NDK r28+ or check your build configuration."
else
    echo ""
    echo "✅ All libraries appear to have proper 16KB alignment."
fi

# --------------------------
# Update precompiled.tgz
# --------------------------
echo "Creating precompiled.tgz with 16KB-aligned libraries..."
tar -cvzf precompiled.tgz libsodium

echo ""
echo "🎉 Build completed successfully!"
echo "✅ Libraries compiled with 16KB page size support"
echo "📦 Precompiled libraries saved to precompiled.tgz"
echo ""
echo "Next steps:"
echo "1. Test your app on a 16KB emulator"
echo "2. Run validation: ./validate_16kb.sh path/to/your.apk"
echo "3. Ensure your React Native app uses the updated Android build configuration"

# --------------------------
# Cleanup
# --------------------------
echo "Cleaning up temporary files..."
[ -e $srcdir ] && rm -Rf $srcdir
[ -e $srcfile ] && rm $srcfile

echo "✅ Cleanup completed."
