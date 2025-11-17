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
  s.preserve_paths = ["libsodium/**/*"]
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  
  # Configure libraries and headers directly in pod_target_xcconfig
  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '"$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios64/include" "$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios-simulator-arm64/include" "$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/macos-arm64/include"',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'SODIUM_STATIC=1',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '"$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios64/lib/libsodium.a"',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '"$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios-simulator-arm64/lib/libsodium.a"',
    'OTHER_LDFLAGS[sdk=macosx*]' => '"$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/macos-arm64/lib/libsodium.a"',
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphoneos*]' => 'arm64',
    'VALID_ARCHS[sdk=macosx*]' => 'arm64 x86_64'
  }
  s.dependency 'React-Core'
end
