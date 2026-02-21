#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_litert.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_litert'
  s.version          = '0.0.1'
  s.summary          = 'LiteRT (formerly TensorFlow Lite) for Flutter with custom ops support.'
  s.description      = <<-DESC
LiteRT (formerly TensorFlow Lite) Flutter plugin with MediaPipe custom operations support.
                       DESC
  s.homepage         = 'https://github.com/hugocornellier/flutter_litert'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Hugo Cornellier' => 'hugo@hugocornellier.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  # When dylibs are present locally (git clone / local dev), use s.resources.
  # When installed from pub.dev, they are excluded to stay under the 100 MB size limit
  # and are instead downloaded automatically during the first build.
  if File.exist?(File.join(__dir__, 'libtensorflowlite_c-mac.dylib'))
    s.resources = ['libtensorflowlite_c-mac.dylib', 'libtflite_custom_ops.dylib']
  else
    s.script_phases = [
      {
        :name => 'Download TFLite Libraries',
        :script => <<-SCRIPT
          if [ ! -f "${PODS_TARGET_SRCROOT}/libtensorflowlite_c-mac.dylib" ]; then
            echo "Downloading TensorFlow Lite macOS libraries..."
            curl -sL "https://github.com/hugocornellier/flutter_litert/releases/download/libs-v0.1.8/macos-libs.zip" -o "${PODS_TARGET_SRCROOT}/_tflite_macos.zip"
            if [ $? -ne 0 ]; then
              echo "error: Failed to download TFLite libraries. Check your internet connection."
              exit 1
            fi
            unzip -qo "${PODS_TARGET_SRCROOT}/_tflite_macos.zip" -d "${PODS_TARGET_SRCROOT}"
            rm -f "${PODS_TARGET_SRCROOT}/_tflite_macos.zip"
            echo "TensorFlow Lite macOS libraries installed successfully."
          fi
        SCRIPT
        :execution_position => :before_compile
      },
      {
        :name => 'Copy TFLite Libraries to Bundle',
        :script => <<-SCRIPT
          RESOURCES_DIR="${BUILT_PRODUCTS_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
          mkdir -p "${RESOURCES_DIR}"
          cp -f "${PODS_TARGET_SRCROOT}/libtensorflowlite_c-mac.dylib" "${RESOURCES_DIR}/"
          cp -f "${PODS_TARGET_SRCROOT}/libtflite_custom_ops.dylib" "${RESOURCES_DIR}/"
        SCRIPT
        :execution_position => :after_compile
      }
    ]
  end
end
