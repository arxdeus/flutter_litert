#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_litert.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_litert'
  s.version          = '0.0.1'
  s.summary          = 'LiteRT (formerly TensorFlow Lite) plugin for Flutter apps.'
  s.description      = <<-DESC
LiteRT (formerly TensorFlow Lite) plugin for Flutter apps.
                       DESC
  s.homepage         = 'https://github.com/hugocornellier/flutter_litert'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hugo Cornellier' => 'hugo@hugocornellier.com' }

  # This will ensure the source files in Classes/ are included in the native
  # builds of apps using this FFI plugin. Podspec does not support relative
  # paths, so Classes contains a forwarder C file that relatively imports
  # `../src/*` so that the C sources can be shared among all target platforms.
  s.source           = { :path => '.' }

  # Include Swift plugin and forwarder C file (which #includes the actual sources)
  s.source_files = 'Classes/**/*'

  # Preserve paths for header includes (these won't be compiled, just available for #include)
  s.preserve_paths = '../src/tensorflow_lite/**/*.h', '../src/custom_ops/**/*.h'

  s.dependency 'Flutter'

  # System frameworks required by TFLite and its delegates
  s.frameworks = 'Metal', 'CoreML', 'Accelerate'
  s.weak_frameworks = 'CoreML'

  s.platform = :ios, '12.0'
  s.static_framework = true

  # Common xcconfig shared between local and published builds
  common_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) TFLITE_USE_FRAMEWORK_HEADERS=1',
    'GCC_SYMBOLS_PRIVATE_EXTERN' => 'NO',
    'HEADER_SEARCH_PATHS' => '"${PODS_TARGET_SRCROOT}/../src" "${PODS_TARGET_SRCROOT}/../src/custom_ops"',
  }

  # Download iOS xcframeworks if not present (pub.dev packages exclude them to
  # stay under the 100 MB size limit; ~85 MB download, cached after first run).
  framework_dir = __dir__
  marker = File.join(framework_dir, 'TensorFlowLiteC.xcframework',
                     'ios-arm64', 'TensorFlowLiteC.framework', 'TensorFlowLiteC')
  unless File.exist?(marker)
    puts '[flutter_litert] Downloading TensorFlow Lite iOS frameworks...'
    zip = File.join(framework_dir, '_tflite_ios.zip')
    system("curl -sL 'https://github.com/hugocornellier/flutter_litert/releases/download/libs-v0.1.8/ios-frameworks.zip' -o '#{zip}'")
    abort '[flutter_litert] ERROR: Failed to download TFLite iOS frameworks. Check your internet connection.' unless $?.success?
    system("unzip -qo '#{zip}' -d '#{framework_dir}'")
    File.delete(zip) if File.exist?(zip)
    puts '[flutter_litert] TensorFlow Lite iOS frameworks installed.'
  end

  s.vendored_frameworks = 'TensorFlowLiteC.xcframework',
                           'TensorFlowLiteCMetal.xcframework',
                           'TensorFlowLiteCCoreML.xcframework'

  s.pod_target_xcconfig = common_xcconfig.merge({
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -all_load'
  })

  s.user_target_xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }
  s.swift_version = '5.0'
end
