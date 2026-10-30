import 'dart:typed_data';

import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web bootstrap.
///
/// `sqflite` has no web implementation, so the browser runs SQLite compiled to
/// wasm via `sqflite_common_ffi_web`. Databases live in the browser's IndexedDB
/// virtual file system, so a plain file name is enough — there is no directory
/// to create.
Future<DatabaseFactory> resolveDatabaseFactory() async {
  return databaseFactoryFfiWeb;
}

/// Returns the database file name; the wasm VFS owns the storage location.
Future<String> resolveDatabasePath(
  DatabaseFactory factory,
  String fileName,
) async {
  return fileName;
}

/// Seeds the wasm virtual file system with [bytes] the first time it is needed.
Future<void> seedDatabaseFromAsset(
  DatabaseFactory factory,
  String path,
  Uint8List bytes,
) async {
  if (await factory.databaseExists(path)) return;
  await factory.writeDatabaseBytes(path, bytes);
}
