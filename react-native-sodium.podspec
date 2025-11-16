require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = package['name']
  s.version      = package['version']
  s.summary      = package['description']
  s.license      = package['license']

  s.authors      = package['author']
  s.homepage     = package['homepage']
  s.platform     = :ios, "9.0"

  s.source       = { :git => "https://github.com/lyubo/react-native-sodium.git", :tag => "v#{s.version}" }
  s.source_files = ["ios/**/*.{h,m}"]
  s.public_header_files = "include/**/*.h"
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  
  s.script_phase = {
    :name => 'Setup libsodium for platform',
    :script => %{
      LIBSODIUM_BASE="${PODS_TARGET_SRCROOT}/libsodium/libsodium-apple/tmp"
      
      # Select the appropriate library based on platform
      if [[ "$PLATFORM_NAME" == "iphonesimulator" ]]; then
        LIBSODIUM_LIB="${LIBSODIUM_BASE}/ios-simulator-arm64/lib/libsodium.a"
        LIBSODIUM_HEADERS="${LIBSODIUM_BASE}/ios-simulator-arm64/include"
        echo "Setting up iOS Simulator library: ${LIBSODIUM_LIB}"
      elif [[ "$PLATFORM_NAME" == "iphoneos" ]]; then
        LIBSODIUM_LIB="${LIBSODIUM_BASE}/ios64/lib/libsodium.a"
        LIBSODIUM_HEADERS="${LIBSODIUM_BASE}/ios64/include"
        echo "Setting up iOS Device library: ${LIBSODIUM_LIB}"
      elif [[ "$PLATFORM_NAME" == "macosx" ]]; then
        LIBSODIUM_LIB="${LIBSODIUM_BASE}/macos-arm64/lib/libsodium.a"
        LIBSODIUM_HEADERS="${LIBSODIUM_BASE}/macos-arm64/include"
        echo "Setting up macOS library: ${LIBSODIUM_LIB}"
      fi
      
      # Copy the correct library to the root directory
      if [[ -f "${LIBSODIUM_LIB}" ]]; then
        cp "${LIBSODIUM_LIB}" "${PODS_TARGET_SRCROOT}/libsodium.a"
        echo "Copied library: ${LIBSODIUM_LIB} -> ${PODS_TARGET_SRCROOT}/libsodium.a"
        
        if [[ -d "${LIBSODIUM_HEADERS}" ]]; then
          ln -sf "${LIBSODIUM_HEADERS}" "${PODS_TARGET_SRCROOT}/platform-headers"
          echo "Created header symlink: ${PODS_TARGET_SRCROOT}/platform-headers -> ${LIBSODIUM_HEADERS}"
        fi
      else
        echo "Warning: libsodium library not found at: ${LIBSODIUM_LIB}"
      fi
    },
    :execution_position => :before_compile
  }
  s.vendored_libraries = 'libsodium.a'
  s.pod_target_xcconfig = {
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphoneos*]' => 'arm64',
    'VALID_ARCHS[sdk=macosx*]' => 'arm64 x86_64'
  }
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/include $(PODS_TARGET_SRCROOT)/platform-headers',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'SODIUM_STATIC=1'
  }
  s.dependency 'React-Core'
end
