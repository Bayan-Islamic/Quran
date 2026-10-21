import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bayan_quran/core/database/database_helper.dart';
import 'package:bayan_quran/features/surah_index/data/datasources/surah_local_data_source.dart';
import 'package:bayan_quran/features/surah_index/data/repositories/surah_repository_impl.dart';
import 'package:bayan_quran/features/quran_reader/data/datasources/quran_reader_local_data_source.dart';
import 'package:bayan_quran/features/quran_reader/data/repositories/quran_reader_repository_impl.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SurahRepositoryImpl surahRepository;
  late QuranReaderRepositoryImpl quranReaderRepository;

  setUpAll(() async {
    final absoluteDbPath = p.join(Directory.current.path, 'assets', 'quran.db');
    expect(File(absoluteDbPath).existsSync(), true, reason: 'assets/quran.db must exist');

    db = await databaseFactoryFfi.openDatabase(
      absoluteDbPath,
      options: OpenDatabaseOptions(readOnly: true),
    );

    final dbHelper = DatabaseHelper.instance;
    dbHelper.setTestDatabase(db);

    final surahDataSource = SurahLocalDataSourceImpl(databaseHelper: dbHelper);
    surahRepository = SurahRepositoryImpl(localDataSource: surahDataSource);

    final readerDataSource = QuranReaderLocalDataSourceImpl(databaseHelper: dbHelper);
    quranReaderRepository = QuranReaderRepositoryImpl(localDataSource: readerDataSource);
  });

  tearDownAll(() async {
    await db.close();
  });

  test('Verify total Surahs count is 114', () async {
    final surahs = await surahRepository.getAllSurahs();
    expect(surahs.length, equals(114));
    expect(surahs.first.id, equals(1));
    expect(surahs.first.nameAr, equals('الفاتحة'));
    expect(surahs.last.id, equals(114));
    expect(surahs.last.nameAr, equals('الناس'));
  });

  test('Verify total Ayahs count in database is 6236', () async {
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ayahs');
    final totalAyahs = result.first['count'] as int;
    expect(totalAyahs, equals(6236));
  });

  test('Verify Ayahs sum across all 114 Surahs equals 6236', () async {
    final surahs = await surahRepository.getAllSurahs();
    int fetchedAyahsCount = 0;
    for (final surah in surahs) {
      final ayahs = await quranReaderRepository.getAyahsBySurahId(surah.id);
      expect(ayahs.length, equals(surah.totalVerses));
      fetchedAyahsCount += ayahs.length;
    }
    expect(fetchedAyahsCount, equals(6236));
  });

  test('Verify search surahs by name and ID', () async {
    final searchFatiha = await surahRepository.searchSurahs('الفاتحة');
    expect(searchFatiha.length, equals(1));
    expect(searchFatiha.first.id, equals(1));

    final searchBaqarahEn = await surahRepository.searchSurahs('Baqarah');
    expect(searchBaqarahEn.length, equals(1));
    expect(searchBaqarahEn.first.id, equals(2));

    final searchByNum = await surahRepository.searchSurahs('114');
    expect(searchByNum.length, equals(1));
    expect(searchByNum.first.nameAr, equals('الناس'));
  });
}
