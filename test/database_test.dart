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

  test('Verify Al-Fatiha, At-Tawbah, and Al-Baqarah Basmala expectations', () async {
    final fatihaAyahs = await quranReaderRepository.getAyahsBySurahId(1);
    expect(fatihaAyahs.first.textUthmani, contains('بِسْمِ'));

    final tawbahAyahs = await quranReaderRepository.getAyahsBySurahId(9);
    expect(tawbahAyahs.first.textUthmani.contains('بِسْمِ ٱللَّهِ'), false);

    final baqarahAyahs = await quranReaderRepository.getAyahsBySurahId(2);
    expect(baqarahAyahs.first.textUthmani.contains('بِسْمِ'), false);
    expect(baqarahAyahs.first.textUthmani, equals('الٓمٓ'));
  });

  test('No surah other than 1 and 9 has a Basmala prefix on verse 1', () async {
    for (final surah in await surahRepository.getAllSurahs()) {
      if (surah.id == 1 || surah.id == 9) continue;
      final first = (await quranReaderRepository.getAyahsBySurahId(surah.id)).first;
      expect(
        first.textUthmani.startsWith('بِسْمِ ٱللَّهِ'),
        isFalse,
        reason: 'surah ${surah.id} still repeats the Basmala in verse 1',
      );
    }
  });

  test('Verify hizb, juz and page ranges', () async {
    final hizb = await db.rawQuery('SELECT MIN(hizb) AS lo, MAX(hizb) AS hi FROM ayahs');
    expect(hizb.first['lo'], equals(1));
    expect(hizb.first['hi'], equals(60));

    final juz = await db.rawQuery('SELECT MIN(juz) AS lo, MAX(juz) AS hi FROM ayahs');
    expect(juz.first['lo'], equals(1));
    expect(juz.first['hi'], equals(30));

    final pages = await db.rawQuery('SELECT COUNT(DISTINCT page_number) AS c FROM ayahs');
    expect(pages.first['c'], equals(604));
  });

  test('Verify surah start_page matches its first ayah page', () async {
    final rows = await db.rawQuery('''
      SELECT s.id AS id, s.start_page AS start_page, MIN(a.page_number) AS first_page
      FROM surahs s JOIN ayahs a ON a.surah_id = s.id
      GROUP BY s.id
    ''');
    for (final row in rows) {
      expect(row['start_page'], equals(row['first_page']), reason: 'surah ${row['id']}');
    }
  });

  test('Verify standard Unicode text with pause glyphs and no PUA', () async {
    final rows = await db.rawQuery('SELECT text_uthmani FROM ayahs');
    var pauseGlyphCount = 0;
    for (final row in rows) {
      final text = row['text_uthmani'] as String;
      for (final rune in text.runes) {
        expect(rune >= 0xE000 && rune <= 0xF8FF, isFalse,
            reason: 'PUA character U+${rune.toRadixString(16)} in $text');
        if (rune >= 0x06D6 && rune <= 0x06ED) pauseGlyphCount++;
      }
    }
    expect(pauseGlyphCount, greaterThan(0));
  });


  test('Verify surah revelation types match the source dataset', () async {
    final surahs = await surahRepository.getAllSurahs();
    final byId = {for (final s in surahs) s.id: s};

    // Meccan surahs (مكية): Al-Fatihah, Al-An'am, Al-A'raf, Al-Ikhlas, An-Nas.
    for (final id in [1, 6, 7, 112, 114]) {
      expect(byId[id]!.type, equals('مكية'), reason: 'surah $id should be Meccan');
      expect(byId[id]!.isMeccan, isTrue, reason: 'surah $id should be Meccan');
    }
    // Medinan surahs (مدنية): Al-Baqarah, At-Tawbah.
    for (final id in [2, 9]) {
      expect(byId[id]!.type, equals('مدنية'), reason: 'surah $id should be Medinan');
      expect(byId[id]!.isMeccan, isFalse, reason: 'surah $id should be Medinan');
    }

    final meccan = surahs.where((s) => s.isMeccan).length;
    expect(meccan, equals(86));
    expect(surahs.length - meccan, equals(28));
  });

  test('Verify no unsupported Quranic glyphs remain in the text', () async {
    // The bundled font draws these five marks as one oversized filled circle
    // (the "black dot" bug); the builder must map or drop them all.
    final rows = await db.rawQuery('SELECT text_uthmani FROM ayahs');
    for (final row in rows) {
      final text = row['text_uthmani'] as String;
      for (final rune in text.runes) {
        expect(
          const {0x06DF, 0x06E3, 0x06EA, 0x06EB, 0x06ED}.contains(rune),
          isFalse,
          reason: 'unsupported glyph U+${rune.toRadixString(16)} in $text',
        );
      }
    }
  });

  test('Verify Al-Baqarah 2:5 uses the rendered zero, not the black dot', () async {
    final rows = await db.rawQuery(
      'SELECT text_uthmani FROM ayahs WHERE surah_id = 2 AND verse_number = 5',
    );
    final text = rows.first['text_uthmani'] as String;
    expect(text.contains('\u06df'), isFalse, reason: 'U+06DF black dot remains');
    expect(text.contains('\u06e0'), isTrue, reason: 'U+06E0 upright zero missing');
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
