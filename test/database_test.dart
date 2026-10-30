import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:bayan_quran/core/database/database_helper.dart';
import 'package:bayan_quran/core/utils/arabic_normalizer.dart';
import 'package:bayan_quran/features/quran_reader/presentation/widgets/tajweed_text_span.dart';
import 'package:bayan_quran/features/surah_index/data/datasources/surah_local_data_source.dart';
import 'package:bayan_quran/features/surah_index/data/repositories/surah_repository_impl.dart';
import 'package:bayan_quran/features/quran_reader/data/datasources/quran_reader_local_data_source.dart';
import 'package:bayan_quran/features/quran_reader/data/repositories/quran_reader_repository_impl.dart';
import 'package:bayan_quran/features/mushaf/data/datasources/mushaf_navigation_data_source.dart';

/// Mirrors the parser's definition of an Arabic combining mark (Unicode Mn).
bool _startsWithCombiningMark(String text) {
  if (text.isEmpty) return false;
  final c = text.codeUnitAt(0);
  return (c >= 0x0610 && c <= 0x061A) ||
      (c >= 0x064B && c <= 0x065F) ||
      c == 0x0670 ||
      (c >= 0x06D6 && c <= 0x06DC) ||
      (c >= 0x06DF && c <= 0x06E4) ||
      (c >= 0x06E7 && c <= 0x06E8) ||
      (c >= 0x06EA && c <= 0x06ED);
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late Database db;
  late SurahRepositoryImpl surahRepository;
  late QuranReaderRepositoryImpl quranReaderRepository;

  setUpAll(() async {
    final absoluteDbPath = p.join(Directory.current.path, 'assets', 'quran.db');
    expect(File(absoluteDbPath).existsSync(), true,
        reason: 'assets/quran.db must exist');

    db = await databaseFactoryFfi.openDatabase(
      absoluteDbPath,
      options: OpenDatabaseOptions(readOnly: true),
    );

    final dbHelper = DatabaseHelper.instance;
    dbHelper.setTestDatabase(db);

    final surahDataSource = SurahLocalDataSourceImpl(databaseHelper: dbHelper);
    surahRepository = SurahRepositoryImpl(localDataSource: surahDataSource);

    final readerDataSource =
        QuranReaderLocalDataSourceImpl(databaseHelper: dbHelper);
    quranReaderRepository =
        QuranReaderRepositoryImpl(localDataSource: readerDataSource);
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

  test('Verify Al-Fatiha, At-Tawbah, and Al-Baqarah Basmala expectations',
      () async {
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
      final first =
          (await quranReaderRepository.getAyahsBySurahId(surah.id)).first;
      expect(
        first.textUthmani.startsWith('بِسْمِ ٱللَّهِ'),
        isFalse,
        reason: 'surah ${surah.id} still repeats the Basmala in verse 1',
      );
    }
  });

  test('Verify hizb, juz and page ranges', () async {
    final hizb =
        await db.rawQuery('SELECT MIN(hizb) AS lo, MAX(hizb) AS hi FROM ayahs');
    expect(hizb.first['lo'], equals(1));
    expect(hizb.first['hi'], equals(60));

    final juz =
        await db.rawQuery('SELECT MIN(juz) AS lo, MAX(juz) AS hi FROM ayahs');
    expect(juz.first['lo'], equals(1));
    expect(juz.first['hi'], equals(30));

    final pages =
        await db.rawQuery('SELECT COUNT(DISTINCT page_number) AS c FROM ayahs');
    expect(pages.first['c'], equals(604));
  });

  test('Verify surah start_page matches its first ayah page', () async {
    final rows = await db.rawQuery('''
      SELECT s.id AS id, s.start_page AS start_page, MIN(a.page_number) AS first_page
      FROM surahs s JOIN ayahs a ON a.surah_id = s.id
      GROUP BY s.id
    ''');
    for (final row in rows) {
      expect(row['start_page'], equals(row['first_page']),
          reason: 'surah ${row['id']}');
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
      expect(byId[id]!.type, equals('مكية'),
          reason: 'surah $id should be Meccan');
      expect(byId[id]!.isMeccan, isTrue, reason: 'surah $id should be Meccan');
    }
    // Medinan surahs (مدنية): Al-Baqarah, At-Tawbah.
    for (final id in [2, 9]) {
      expect(byId[id]!.type, equals('مدنية'),
          reason: 'surah $id should be Medinan');
      expect(byId[id]!.isMeccan, isFalse,
          reason: 'surah $id should be Medinan');
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

  test('Verify Al-Baqarah 2:5 uses the rendered zero, not the black dot',
      () async {
    final rows = await db.rawQuery(
      'SELECT text_uthmani FROM ayahs WHERE surah_id = 2 AND verse_number = 5',
    );
    final text = rows.first['text_uthmani'] as String;
    expect(text.contains('\u06df'), isFalse,
        reason: 'U+06DF black dot remains');
    expect(text.contains('\u06e0'), isTrue,
        reason: 'U+06E0 upright zero missing');
  });

  test('Verify every ayah has non-empty Tajweed markup', () async {
    final rows = await db.rawQuery(
      "SELECT COUNT(*) AS count FROM ayahs "
      "WHERE text_tajweed IS NULL OR text_tajweed = ''",
    );
    expect(rows.first['count'], equals(0));
  });

  test('Verify no stray markup survives in the Tajweed column', () async {
    // The source has a malformed tag (32:3) and <span class=end> markers; the
    // builder must strip both, leaving only well-formed <tajweed> tags.
    final rows = await db
        .rawQuery('SELECT surah_id, verse_number, text_tajweed FROM ayahs');
    final tagPattern = RegExp(r'</?tajweed[^>]*>');
    for (final row in rows) {
      final markup = row['text_tajweed'] as String;
      expect(markup.contains('<span'), isFalse,
          reason:
              '${row['surah_id']}:${row['verse_number']} has a <span> marker');
      // Everything that is not a well-formed <tajweed> tag must be text.
      final remainder = markup.replaceAll(tagPattern, '');
      expect(remainder.contains('<'), isFalse,
          reason:
              '${row['surah_id']}:${row['verse_number']} has an opening tag left over');
      expect(remainder.contains('>'), isFalse,
          reason: '${row['surah_id']}:${row['verse_number']} has a stray ">"');
    }
  });

  test('Verify Tajweed markup parses into the expected palette', () async {
    // Al-Ikhlas 112:1: "... أَحَدٌ" with a qalqalah on the dal.
    final rows = await db.rawQuery(
      "SELECT text_tajweed FROM ayahs WHERE surah_id = 112 AND verse_number = 1",
    );
    final markup = rows.first['text_tajweed'] as String;
    expect(markup, contains('<tajweed class='));

    final span = TajweedTextSpan.build(
      markup,
      fontSize: 24,
      defaultColor: const Color(0xFF000000),
    );
    final colors = <Color?>{};
    void walk(InlineSpan s) {
      if (s is TextSpan) {
        if (s.text != null) colors.add(s.style?.color);
        for (final c in s.children ?? const <InlineSpan>[]) {
          walk(c);
        }
      }
    }

    walk(span);
    // The qalqalah colour must appear, and some text must remain untagged
    // (rendered with the default/ambient colour).
    expect(colors, contains(TajweedColors.qalqalah));
    expect(colors, contains(null));
  });

  test('Verify the Tajweed plain text matches the Uthmani plain text',
      () async {
    // Both columns come from the same verse, so stripping the markup must yield
    // text with the same normalised form (diacritic-independent).
    for (final verse in ['1:1', '2:1', '9:1', '112:1']) {
      final rows = await db.rawQuery(
        'SELECT text_uthmani, text_tajweed FROM ayahs '
        'WHERE surah_id = ? AND verse_number = ?',
        verse.split(':').map(int.parse).toList(),
      );
      final uthmani = rows.first['text_uthmani'] as String;
      final tajweed = rows.first['text_tajweed'] as String;
      final plain = tajweed.replaceAll(RegExp(r'<[^>]*>'), '');
      expect(
        ArabicNormalizer.normalize(plain),
        equals(ArabicNormalizer.normalize(uthmani)),
        reason: 'verse $verse plain Tajweed text should match Uthmani text',
      );
    }
  });

  test(
      'Verify no Tajweed span starts with a combining mark (dotted-circle bug)',
      () async {
    // A span that begins with a combining mark is shaped in isolation and the
    // engine draws the U+25CC dotted-circle fallback. The parser must bind each
    // such mark back to its base character across the whole corpus.
    final rows = await db.rawQuery('SELECT text_tajweed FROM ayahs');
    var spans = 0;
    for (final row in rows) {
      final span = TajweedTextSpan.build(
        row['text_tajweed'] as String,
        fontSize: 24,
        defaultColor: const Color(0xFF000000),
      );
      void walk(InlineSpan s) {
        if (s is! TextSpan) return;
        final text = s.text;
        if (text != null && text.isNotEmpty) {
          spans++;
          expect(
            _startsWithCombiningMark(text),
            isFalse,
            reason: 'span "$text" starts with a combining mark',
          );
        }
        for (final child in s.children ?? const <InlineSpan>[]) {
          walk(child);
        }
      }

      walk(span);
    }
    expect(spans, greaterThan(rows.length));
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

  test('Verify every ayah has a Tafsir and an English translation', () async {
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM ayah_content');
    expect(rows.first['c'], equals(6236));

    final empty = await db.rawQuery(
      "SELECT COUNT(*) AS c FROM ayah_content "
      "WHERE tafsir_muyassar IS NULL OR tafsir_muyassar = '' "
      "OR translation_en IS NULL OR translation_en = ''",
    );
    expect(empty.first['c'], equals(0));
  });

  test('Verify the juz navigation data source lists 30 juz from page 1',
      () async {
    final dataSource = MushafNavigationDataSourceImpl(
      databaseHelper: DatabaseHelper.instance,
    );
    final juzList = await dataSource.getJuzList();

    expect(juzList.length, equals(30));
    expect(juzList.first.number, equals(1));
    expect(juzList.first.startPage, equals(1));
    expect(juzList.last.number, equals(30));
    expect(
      juzList.map((j) => j.startPage).toList(),
      orderedEquals(
        juzList.map((j) => j.startPage).toList()..sort(),
      ),
    );
  });
}
