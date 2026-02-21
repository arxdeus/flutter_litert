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

That's it. No additional setup required on any platform.

## Usage

```dart
import 'package:flutter_litert/flutter_litert.dart';

final interpreter = await Interpreter.fromAsset('model.tflite');

// Prepare input and output buffers
var input = [/* your input data */];
var output = List.filled(outputSize, 0.0).reshape([1, outputSize]);

interpreter.run(input, output);
```

For inference off the main thread:

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

iOS and macOS will be migrated to LiteRT as official CocoaPods artifacts become available.

## Features

- **Same API as tflite_flutter.** Drop-in replacement with no code changes needed.
- **Auto-bundled native libraries.** Works out of the box on Android, iOS, macOS, Windows, and Linux.
- **GPU acceleration.** Metal delegate on iOS, GPU delegate on Android, XNNPACK on all platforms.
- **CoreML delegate.** Available on iOS and macOS for Neural Engine acceleration.
- **Custom ops.** MediaPipe's `Convolution2DTransposeBias` op is built and included on all platforms.
- **Isolate support.** Run inference on a background thread with `IsolateInterpreter`.

## Credits

Based on [`tflite_flutter`](https://pub.dev/packages/tflite_flutter) by the TensorFlow team and contributors.
