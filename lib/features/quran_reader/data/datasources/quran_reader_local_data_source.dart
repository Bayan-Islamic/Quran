import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../models/ayah_model.dart';

abstract class QuranReaderLocalDataSource {
  Future<List<AyahModel>> getAyahsBySurahId(int surahId);
}

class QuranReaderLocalDataSourceImpl implements QuranReaderLocalDataSource {
  final DatabaseHelper databaseHelper;

  QuranReaderLocalDataSourceImpl({required this.databaseHelper});

  static const String _basmala = 'بسم الله الرحمن الرحيم';

  /// Surah 1 keeps the Basmala as its first verse; Surah 9 has none.
  static bool shouldStripBasmala(int surahId) => surahId != 1 && surahId != 9;

  /// Removes a leading Basmala from a first verse, preserving the rest of the
  /// text (including its diacritics). Matching is done on the normalised form
  /// so the exact diacritic spelling does not matter, but the returned slice
  /// comes from the original string.
  static String stripBasmalaPrefix(String text) {
    final stripped = text.trim();
    if (!ArabicNormalizer.normalize(stripped).startsWith(_basmala)) {
      return stripped;
    }
    final words = stripped.split(RegExp(r'\s+'));
    for (int i = 0; i < words.length; i++) {
      if (ArabicNormalizer.normalize(words.sublist(0, i + 1).join(' ')) ==
          _basmala) {
        return words.sublist(i + 1).join(' ').trim();
      }
    }
    return stripped;
  }

  @override
  Future<List<AyahModel>> getAyahsBySurahId(int surahId) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'verse_number ASC',
    );
    final list = maps.map((map) => AyahModel.fromMap(map)).toList();

    if (shouldStripBasmala(surahId) &&
        list.isNotEmpty &&
        list.first.verseNumber == 1) {
      final first = list.first;
      final strippedText = stripBasmalaPrefix(first.textUthmani);
      if (strippedText != first.textUthmani) {
        list[0] = AyahModel(
          id: first.id,
          surahId: first.surahId,
          verseNumber: first.verseNumber,
          textUthmani: strippedText,
          textSearchNormalised: ArabicNormalizer.normalize(strippedText),
          pageNumber: first.pageNumber,
          juz: first.juz,
          hizb: first.hizb,
        );
      }
    }
    return list;
  }
}
