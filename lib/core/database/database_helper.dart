import 'package:flutter/services.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'platform/database_bootstrap.dart';

/// Opens the bundled, read-only Quran database.
///
/// The database ships as an asset and is copied into a writable location the
/// first time the app runs. A read-only connection is used, so the schema
/// version is never written back (`OpenDatabaseOptions.version` would fail on a
/// read-only connection with "attempt to write a readonly database").
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String assetPath = 'assets/quran.db';
  static const String _databaseFileName = 'bayan_quran.db';

  Database? _database;
  Future<Database>? _opening;

  DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    return _opening ??= _initDatabase().then((db) {
      _database = db;
      return db;
    });
  }

  /// Injects an already-open database (used by tests).
  void setTestDatabase(Database db) {
    _database = db;
    _opening = null;
  }

  Future<Database> _initDatabase() async {
    final factory = await resolveDatabaseFactory();
    final path = await resolveDatabasePath(factory, _databaseFileName);
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await seedDatabaseFromAsset(factory, path, bytes);
    return factory.openDatabase(path, options: OpenDatabaseOptions(readOnly: true));
  }
}
