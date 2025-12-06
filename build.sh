#!/bin/bash

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
    
    # Extract major version (e.g., "28.0.12674087" -> "28")
    NDK_MAJOR=$(echo "$NDK_VERSION" | cut -d'.' -f1)
    
    if [ "$NDK_MAJOR" -lt 27 ]; then
        echo "Warning: NDK version $NDK_VERSION is older than r27."
        echo "For best 16KB support, please upgrade to NDK r28 or later."
        echo "Continuing with manual 16KB flags..."
        USE_MANUAL_16KB_FLAGS=true
    else
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
curl https://download.libsodium.org/libsodium/releases/$sigfile > $sigfile

minisign -V -P RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3 -m $srcfile || exit 1

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
    IOS_VERSION_MIN=12.0.0 dist-build/apple-xcframework.sh
  fi

  # --------------------------
  # Android build
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
  mv $srcdir/libsodium-apple libsodium/
fi

# --------------------------
# Update precompiled.tgz
# --------------------------
echo "Creating precompiled.tgz"
tar -cvzf precompiled.tgz libsodium


# --------------------------
# Cleanup
# --------------------------
echo "Cleaning up temporary files..."
[ -e $srcdir ] && rm -Rf $srcdir
[ -e $srcfile ] && rm $srcfile

echo "Cleanup completed."
