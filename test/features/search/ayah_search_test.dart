import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bayan_quran/core/database/database_helper.dart';
import 'package:bayan_quran/features/search/data/datasources/search_local_data_source.dart';
import 'package:bayan_quran/features/search/data/repositories/search_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SearchLocalDataSourceImpl dataSource;
  late SearchRepositoryImpl repository;

  setUpAll(() async {
    final absoluteDbPath = p.join(Directory.current.path, 'assets', 'quran.db');
    expect(File(absoluteDbPath).existsSync(), true, reason: 'assets/quran.db must exist');

    db = await databaseFactoryFfi.openDatabase(
      absoluteDbPath,
      options: OpenDatabaseOptions(readOnly: true),
    );

    final dbHelper = DatabaseHelper.instance;
    dbHelper.setTestDatabase(db);

    dataSource = SearchLocalDataSourceImpl(databaseHelper: dbHelper);
    repository = SearchRepositoryImpl(localDataSource: dataSource);
  });

  tearDownAll(() async {
    await db.close();
  });

  group('SearchRepository Integration Test', () {
    test('searchAyahs returns matching Ayahs for الرحمن', () async {
      final results = await repository.searchAyahs('الرحمن');
      expect(results, isNotEmpty);
      expect(results.length, equals(48));
      expect(results.first.surah.nameAr, equals('الفاتحة'));
      expect(results.first.ayah.verseNumber, equals(1));
    });

    test('searchAyahs normalises diacritics in the query', () async {
      final withDiacritics = await repository.searchAyahs('ٱلرَّحْمَٰنِ');
      final withoutDiacritics = await repository.searchAyahs('الرحمن');
      expect(withDiacritics.length, equals(withoutDiacritics.length));
      expect(withDiacritics.first.ayah.surahId, equals(1));
    });

    test('searchAyahs matches on the precomputed normalised column', () async {
      final results = await repository.searchAyahs('موسي');
      expect(results, isNotEmpty);
      expect(
        results.every((r) => r.ayah.textSearchNormalised.contains('موسي')),
        isTrue,
      );
    });

    test('searchAyahs treats LIKE metacharacters literally', () async {
      final results = await repository.searchAyahs('%');
      expect(results, isEmpty);
    });

    test('searchAyahs returns empty list for empty query', () async {
      final results = await repository.searchAyahs('   ');
      expect(results, isEmpty);
    });

    test('every ayah carries a non-empty normalised search text', () async {
      final count = await db.rawQuery(
        "SELECT COUNT(*) AS c FROM ayahs WHERE text_search_normalised IS NULL "
        "OR text_search_normalised = ''",
      );
      expect(count.first['c'], equals(0));
    });
  });
}
