export 'unsupported/version.dart'
    if (dart.library.io) 'native/version.dart'
    if (dart.library.js_interop) 'web/version.dart';
