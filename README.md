# flutter_litert

A Flutter plugin for on-device ML inference using LiteRT (formerly TensorFlow Lite), with native libraries bundled automatically on every platform.

## Background

This project started as a fork of [`tflite_flutter`](https://pub.dev/packages/tflite_flutter), the official TensorFlow Lite plugin for Flutter. TensorFlow Lite has since been discontinued by Google and rebranded as [LiteRT](https://ai.google.dev/edge/litert).

`flutter_litert` picks up where `tflite_flutter` left off. It maintains the same Dart API while migrating the underlying native libraries from TensorFlow Lite to LiteRT. Android has already moved to LiteRT. Other platforms are in the process of being migrated.

## Why this package?

The biggest pain point with `tflite_flutter` was native library setup. You had to manually build `.so`, `.dll`, or `.dylib` files and place them in the right directories for each platform. This was tedious, error-prone, and easy to get wrong.

**`flutter_litert` bundles all native libraries automatically.** Add the dependency, and it works. No manual downloads, no copying files around, no platform-specific setup steps.

Other improvements over `tflite_flutter`:

- Native libraries are kept up to date across all platforms
- Custom ops are built and bundled automatically (e.g. MediaPipe model support)
- GPU delegate libraries are included where available

## Installation

```yaml
dependencies:
  flutter_litert: ^0.1.7
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
| Linux | TensorFlow Lite (C API) | Pre-built | Shared library bundled via CMake |
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

## Credits

Based on [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) by the TensorFlow team and contributors.
