/// Platform-specific SQLite bootstrap.
///
/// Native/desktop builds use the `sqflite` plugin or `sqflite_common_ffi`;
/// the web build uses `sqflite_common_ffi_web` with a wasm SQLite engine.
library;

export 'database_bootstrap_io.dart'
    if (dart.library.js_interop) 'database_bootstrap_web.dart';
