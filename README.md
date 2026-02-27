# flutter_litert

[![pub points](https://img.shields.io/pub/points/flutter_litert?color=2E8B57&label=pub%20points)](https://pub.dev/packages/flutter_litert/score)
[![pub package](https://img.shields.io/pub/v/flutter_litert.svg)](https://pub.dev/packages/flutter_litert)

A Flutter plugin for on-device ML inference using LiteRT (formerly TensorFlow Lite), with native libraries bundled automatically on every platform.

## Background  

This project started as a fork of [`tflite_flutter`](https://pub.dev/packages/tflite_flutter), the official TensorFlow Lite plugin for Flutter. TensorFlow Lite has since been discontinued by Google and rebranded as [LiteRT](https://ai.google.dev/edge/litert).
 
`flutter_litert` maintains the same API as `tflite_flutter` while pre-bundling native libraries for all platforms. 

## Why this package?

The biggest pain point with `tflite_flutter` was native library setup. You had to manually build `.so`, `.dll`, or `.dylib` files and place them in the right directories for each platform. This was tedious, error-prone, and easy to get wrong.

**`flutter_litert` bundles all native libraries automatically.** Simply add the dependency, and it works out of the box.

Main improvements over `tflite_flutter`:

- Native libraries bundled automatically
  - Prebuilt binaries for MacOS/Windows/Linux are served automatically. Manuel steps no longer necessasry.
- Native libraries are kept up to date across all platforms — [See library info](#platform-support)
- [Custom ops support](#custom-ops)
- [Web support](#web-support)

## Installation

```yaml
dependencies:
  flutter_litert: ^1.0.3
```

That's it for native platforms. For web, call `initializeWeb()` before creating an interpreter (see [Web support](#web-support)).

## Usage

```dart
import 'package:flutter_litert/flutter_litert.dart';

final interpreter = await Interpreter.fromAsset('model.tflite');

// Prepare input and output buffers
var input = [/* your input data */];
var output = List.filled(outputSize, 0.0).reshape([1, outputSize]);

interpreter.run(input, output);
```

For inference off the main thread (native platforms):

```dart
final interpreter = await Interpreter.fromAsset('model.tflite');
final isolateInterpreter = await IsolateInterpreter.create(address: interpreter.address);

await isolateInterpreter.run(input, output);
```

## Platform support

| Platform | Runtime | Version   | Bundling |
|----------|---------|-----------|----------|
| Android | LiteRT | 1.4.1     | Maven dependency, built automatically via Gradle |
| iOS | TensorFlow Lite | 2.20.0    | Vendored xcframeworks, linked via CocoaPods |
| macOS | TensorFlow Lite (C API) | 2.20.0    | Pre-built dylib, bundled via CocoaPods |
| Windows | TensorFlow Lite (C API) | 2.20.0    | DLL bundled via CMake |
| Linux | TensorFlow Lite (C API) | 2.20.0    | Shared library bundled via CMake |
| Web | TFLite.js (WASM via TensorFlow.js) | `tflite-js@v0.0.1-alpha.10` (default CDN) | JS runtime loaded at startup via `initializeWeb()` |

iOS and macOS will be migrated to LiteRT as official CocoaPods artifacts become available.

## Web support

`flutter_litert` supports Flutter Web, but there are a few differences from native platforms.

### Quick start (web)

Call `initializeWeb()` before creating any interpreter in a browser. It is a no-op on native, so you can call it unconditionally.

```dart
import 'package:flutter_litert/flutter_litert.dart';

await initializeWeb();

final interpreter = await Interpreter.fromAsset('assets/model.tflite');
// or: final interpreter = await Interpreter.fromBytes(modelBytes);

interpreter.run(input, output);
```

By default, `initializeWeb()` loads the TFLite.js / TensorFlow.js scripts from a CDN. You can pass custom script URLs to self-host the files (for offline use or stricter CSP).

### Web-specific API differences

- Call `initializeWeb()` before `Interpreter.fromAsset(...)` or `Interpreter.fromBytes(...)`.
- `Interpreter.fromAsset(...)` and `Interpreter.fromBytes(...)` are the supported model-loading APIs on web.
- `Interpreter.fromFile(...)`, `Interpreter.fromBuffer(...)`, and `Interpreter.fromAddress(...)` are not supported on web.
- `IsolateInterpreter.create(address: ...)` is not supported on web. Use the regular `Interpreter` directly (or `IsolateInterpreter.createFromInterpreter(...)`).
- Delegate and interpreter tuning options (GPU/XNNPACK/CoreML/threads) are accepted for API compatibility but are effectively no-ops on web.

### Using this from a web app or plugin

- Avoid `dart:io`-only code paths in the browser.
- Load files/images/models as bytes (`Uint8List`) using Flutter assets, HTTP, file picker, or drag-and-drop.
- Run your app with `flutter run -d chrome` and build with `flutter build web`.
- If you are writing a plugin on top of `flutter_litert`, add a web code path that works with bytes instead of file paths / native handles.

## Features

- **Same API as tflite_flutter.** Drop-in replacement with no code changes needed.
- **Auto-bundled native libraries.** Works out of the box on Android, iOS, macOS, Windows, and Linux (plus web support via `initializeWeb()`).
- **GPU acceleration.** Metal delegate on iOS, GPU delegate on Android, XNNPACK on supported native platforms.
- **CoreML delegate.** Available on iOS and macOS for Neural Engine acceleration.
- **Custom ops.** MediaPipe's `Convolution2DTransposeBias` op is built and included on all platforms.
- **Isolate support.** Run inference on a background thread with `IsolateInterpreter` on native platforms (web provides a compatibility wrapper).

## Custom ops

`flutter_litert` bundles MediaPipe's `Convolution2DTransposeBias` custom op out of the box. To use it, call `addMediaPipeCustomOps()` on your interpreter options before creating the interpreter:

```dart
final options = InterpreterOptions();
options.addMediaPipeCustomOps();
final interpreter = await Interpreter.fromAsset('model.tflite', options: options);
```

This is required for models like MediaPipe Selfie Segmentation (the binary `selfie_segmenter.tflite` and `selfie_segmenter_landscape.tflite` variants). The [`face_detection_tflite`](https://pub.dev/packages/face_detection_tflite) package uses this for its selfie segmentation feature.

### Adding your own custom ops

If your TFLite model uses a custom op that isn't already bundled, you need to provide three things: a C implementation, per-platform native builds, and Dart FFI registration. The bundled `Convolution2DTransposeBias` op (in `src/custom_ops/`) serves as a complete working example.

#### 1. Write the C implementation

Implement the four TFLite op callbacks and export a registration function:

```c
#include "tensorflow_lite/common.h"
#include "tensorflow_lite/c_api.h"

static void* MyOpInit(TfLiteContext* context, const char* buffer, size_t length) {
    // Parse custom_options, allocate state. Return a pointer to your state.
}

static void MyOpFree(TfLiteContext* context, void* buffer) {
    // Free state allocated in Init.
}

static TfLiteStatus MyOpPrepare(TfLiteContext* context, TfLiteNode* node) {
    // Validate input/output tensor shapes, types, and dimensions.
    // Do NOT call context->ResizeTensor for custom ops — validate
    // against the shapes the model graph already defines.
    return kTfLiteOk;
}

static TfLiteStatus MyOpEval(TfLiteContext* context, TfLiteNode* node) {
    // Run the actual computation.
    return kTfLiteOk;
}

static TfLiteRegistration g_registration = {
    MyOpInit,
    MyOpFree,
    MyOpPrepare,
    MyOpEval,
    NULL,                   // profiling_string
    kTfLiteBuiltinCustom,   // builtin_code
    "MyCustomOpName",       // custom_name (must match the op name in your .tflite model)
    1,                      // version
    NULL,                   // registration_external
};

// Export with visibility so the linker doesn't strip it and FFI can find it
__attribute__((used, visibility("default")))
TfLiteRegistration* MyPlugin_RegisterMyCustomOp(void) {
    return &g_registration;
}
```

#### 2. Build and bundle per platform

Each platform needs to compile your C code and make the resulting library available at runtime.

**Android** — Add a CMakeLists.txt that compiles your `.c` into a shared library, and point to it from your plugin's `android/build.gradle`:

```gradle
android {
    externalNativeBuild {
        cmake { path "../src/CMakeLists.txt" }
    }
}
```

**Linux / Windows** — In your plugin's `linux/CMakeLists.txt` or `windows/CMakeLists.txt`, add your source directory as a subdirectory and include the resulting library in `bundled_libraries`:

```cmake
add_subdirectory("../src" "${CMAKE_CURRENT_BINARY_DIR}/my_custom_ops")
set(my_plugin_bundled_libraries $<TARGET_FILE:my_custom_ops> PARENT_SCOPE)
```

**macOS** — Either pre-build a universal `.dylib` and ship it as a CocoaPods resource in your `.podspec`:

```ruby
s.resources = ['my_custom_ops.dylib']
```

Or compile from source using a script phase.

**iOS** — Static linking is required. Create a forwarder `.c` file in `ios/Classes/` that `#include`s your implementation:

```c
// ios/Classes/my_custom_ops.c
#include "../../src/my_custom_op.c"

// Force-load so the linker doesn't strip the symbol
__attribute__((used))
void MyPlugin_ForceLoadCustomOps(void) {
    (void)MyPlugin_RegisterMyCustomOp;
}
```

Then call the force-load function from your Swift/ObjC plugin registration to prevent dead code elimination.

#### 3. Register from Dart via FFI

Load the native library and register the op with the interpreter options:

```dart
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_litert/flutter_litert.dart';

// Load the native library (platform-specific)
final DynamicLibrary customOpsLib = Platform.isIOS
    ? DynamicLibrary.process()  // iOS: statically linked
    : DynamicLibrary.open('libmy_custom_ops.so');  // Android/Linux/etc.

// Look up the registration function
final registerFn = customOpsLib.lookupFunction<
    Pointer<TfLiteRegistration> Function(),
    Pointer<TfLiteRegistration> Function()
>('MyPlugin_RegisterMyCustomOp');

final registration = registerFn();

// Keep this alive for the lifetime of the interpreter — TFLite stores
// the pointer, not a copy
final opName = 'MyCustomOpName'.toNativeUtf8().cast<Char>();

// Register before creating the interpreter
final options = InterpreterOptions();
tfliteBinding.TfLiteInterpreterOptionsAddCustomOp(
    options.base,  // the underlying native pointer
    opName,
    registration,
    1,  // min_version
    1,  // max_version
);
final interpreter = await Interpreter.fromAsset('model.tflite', options: options);
```

### Gotchas

- **The op name string must outlive the interpreter.** `TfLiteInterpreterOptionsAddCustomOp` stores the pointer, not a copy. Allocate it once with `toNativeUtf8()` and keep it alive statically (e.g. as a `static Pointer<Char>?` field).
- **iOS linker stripping.** Even if the C symbol is compiled in, the linker will strip it if nothing references it. You need a force-load function called from your plugin's Swift/ObjC registration code.
- **Windows CRT heap mismatch.** If your custom op DLL calls `malloc` but TFLite frees with its own `free` (from a different DLL), you get heap corruption. Resolve `TfLiteIntArrayCreate` from the TFLite DLL at runtime so allocations use TFLite's heap. See `src/custom_ops/transpose_conv_bias.c` for a working example.
- **Web is not supported.** The TFLite.js/WASM runtime does not have a custom op registration API.

## Credits

Based on [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) by the TensorFlow team and contributors.
