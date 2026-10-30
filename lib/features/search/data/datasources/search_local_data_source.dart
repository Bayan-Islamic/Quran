import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../quran_reader/data/models/ayah_model.dart';
import '../../../surah_index/data/models/surah_model.dart';
import '../../domain/entities/search_result.dart';

abstract class SearchLocalDataSource {
  Future<List<SearchResult>> searchAyahs(String query);
}

class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  final DatabaseHelper databaseHelper;

  SearchLocalDataSourceImpl({required this.databaseHelper});

  static const int maxResults = 200;

  /// Escapes SQLite `LIKE` metacharacters so a user query is matched literally.
  static String escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  @override
  Future<List<SearchResult>> searchAyahs(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final normalizedQuery = ArabicNormalizer.normalize(cleanQuery);
    if (normalizedQuery.isEmpty) return [];

    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT
        a.id AS ayah_id,
        a.surah_id,
        a.verse_number,
        a.text_uthmani,
        a.text_search_normalised,
        a.page_number AS ayah_page_number,
        a.juz,
        a.hizb,
        s.id AS s_id,
        s.name_ar,
        s.name_en,
        s.type,
        s.total_verses,
        s.start_page AS surah_page_number
      FROM ayahs a
      JOIN surahs s ON a.surah_id = s.id
      WHERE a.text_search_normalised LIKE ? ESCAPE '\\'
      ORDER BY a.surah_id ASC, a.verse_number ASC
      LIMIT ?
      ''',
      ['%${escapeLike(normalizedQuery)}%', maxResults],
    );

    return maps.map((map) {
      final ayah = AyahModel(
        id: map['ayah_id'] as int,
        surahId: map['surah_id'] as int,
        verseNumber: map['verse_number'] as int,
        textUthmani: map['text_uthmani'] as String,
        textSearchNormalised: map['text_search_normalised'] as String,
        pageNumber: map['ayah_page_number'] as int,
        juz: map['juz'] as int,
        hizb: map['hizb'] as int,
      );

      final surah = SurahModel(
        id: map['s_id'] as int,
        nameAr: map['name_ar'] as String,
        nameEn: map['name_en'] as String,
        type: map['type'] as String,
        totalVerses: map['total_verses'] as int,
        pageNumber: map['surah_page_number'] as int,
      );

      return SearchResult(ayah: ayah, surah: surah);
    }).toList();
  }
}
