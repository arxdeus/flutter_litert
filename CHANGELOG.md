## 0.1.7
* Improved documentation

## 0.1.6
* Upgrade macOS TFLite native library from 2.17.1 to 2.20.0 (latest stable, universal binary: arm64 + x86_64)
* Update all C API headers to TFLite 2.20.0
* Regenerate FFI bindings (`TfLiteOperatorCreate` now takes 4 params, `TfLiteOperatorCreateWithData` removed, new `kTfLiteOutputShapeNotKnown` status, new builtin ops)
* Rebuild macOS custom ops dylib against 2.20.0

## 0.1.5
* Upgrade macOS TFLite native library from 2.11.0 to 2.17.1 (universal binary: arm64 + x86_64)
* Update all C API headers to TFLite 2.17.1 (including new `TfLiteOperator` API replacing `TfLiteRegistrationExternal`)
* Regenerate FFI bindings with new APIs (SignatureRunner, TfLiteInterpreterCancel, and more)
* Rebuild macOS custom ops dylib as universal binary (arm64 + x86_64)

## 0.1.4
* Bundle `libtensorflowlite_c-win.dll` from flutter_litert Windows plugin instead of downstream packages

## 0.1.3
* Fix Windows: build and bundle custom ops DLL (tflite_custom_ops.dll) for MediaPipe models
* Fix heap corruption crash when switching between segmentation models (custom op name string was freed prematurely)

## 0.1.2
* Fix Linux: build and bundle custom ops library (libtflite_custom_ops.so) so MediaPipe models with custom ops (e.g. selfie segmentation) work on Linux

## 0.1.1
* Update AndroidManifest.xml

## 0.1.0
* Fix IsolateInterpreter thread-safety bug causing intermittent native crashes when hardware delegates are active

## 0.0.1
* Initial release, forked from tflite_flutter_custom v1.2.5
* Rebranded to flutter_litert for LiteRT ecosystem
* All native libraries bundled automatically
* Custom ops support (MediaPipe models)
* Full platform support: Android, iOS, macOS, Windows, Linux
