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
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.15'
  
  # Platform-specific configurations
  s.ios.vendored_libraries = 'libsodium/libsodium-apple/tmp/ios64/lib/libsodium.a'
  s.ios.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios64/include',
    'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios64/lib',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'SODIUM_STATIC=1',
    'OTHER_LDFLAGS[sdk=iphoneos*]' => '$(inherited) -force_load "$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios64/lib/libsodium.a"',
    'OTHER_LDFLAGS[sdk=iphonesimulator*]' => '$(inherited) -force_load "$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/ios-simulator-arm64/lib/libsodium.a"'
  }
  
  s.osx.vendored_libraries = 'libsodium/libsodium-apple/tmp/macos-arm64/lib/libsodium.a'
  s.osx.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/macos-arm64/include',
    'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/macos-arm64/lib',
    'GCC_PREPROCESSOR_DEFINITIONS' => 'SODIUM_STATIC=1',
    'OTHER_LDFLAGS' => '$(inherited) -force_load "$(PODS_TARGET_SRCROOT)/libsodium/libsodium-apple/tmp/macos-arm64/lib/libsodium.a"'
  }
  
  s.pod_target_xcconfig = {
    'VALID_ARCHS[sdk=iphonesimulator*]' => 'arm64',
    'VALID_ARCHS[sdk=iphoneos*]' => 'arm64',
    'VALID_ARCHS[sdk=macosx*]' => 'arm64 x86_64'
  }
  s.dependency 'React-Core'
end
