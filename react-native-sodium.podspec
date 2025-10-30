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
  
  # Use the simplified header location
  s.public_header_files = "include/**/*.h"
  
  # Directly specify the vendored libraries for simulator builds
  s.vendored_libraries = 'libsodium/libsodium-apple/tmp/ios-simulator-arm64/lib/libsodium.a'
  
  # Configure framework linking
  s.frameworks = 'Security'
  
  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/include'
  }

  s.dependency 'React-Core'
end
