import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Native/desktop bootstrap.
///
/// Android/iOS keep the default `sqflite` plugin factory; Linux/Windows/macOS
/// switch to the FFI factory because the plugin has no desktop implementation.
Future<DatabaseFactory> resolveDatabaseFactory() async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    sqfliteFfiInit();
    return databaseFactoryFfi;
  }
  return sqflite.databaseFactory;
}

/// Returns the writable location for the database on this platform.
Future<String> resolveDatabasePath(
  DatabaseFactory factory,
  String fileName,
) async {
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    final support = await getApplicationSupportDirectory();
    return p.join(support.path, fileName);
  }
  return p.join(await factory.getDatabasesPath(), fileName);
}

/// Writes [bytes] to [path] when no database exists yet.
Future<void> seedDatabaseFromAsset(
  DatabaseFactory factory,
  String path,
  Uint8List bytes,
) async {
  if (await factory.databaseExists(path)) return;
  await Directory(p.dirname(path)).create(recursive: true);
  await File(path).writeAsBytes(bytes, flush: true);
}
