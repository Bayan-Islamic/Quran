import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/bookmark.dart';
import '../../domain/entities/mushaf_bookmark.dart';

abstract class BookmarkLocalDataSource {
  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  });

  Future<Bookmark?> getLastRead();

  Future<void> saveMushafPage(int? pageNumber);

  Future<MushafBookmark?> getMushafPage();
}

class BookmarkLocalDataSourceImpl implements BookmarkLocalDataSource {
  static const String keySurahId = 'last_read_surah_id';
  static const String keySurahNameAr = 'last_read_surah_name_ar';
  static const String keyVerseNumber = 'last_read_verse_number';
  static const String keyUpdatedAt = 'last_read_updated_at';
  static const String keyMushafPage = 'mushaf_bookmark_page';
  static const String keyMushafUpdatedAt = 'mushaf_bookmark_updated_at';

  final SharedPreferences sharedPreferences;

  BookmarkLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  }) async {
    final updatedAt = DateTime.now().toIso8601String();
    await sharedPreferences.setInt(keySurahId, surahId);
    await sharedPreferences.setString(keySurahNameAr, surahNameAr);
    await sharedPreferences.setInt(keyVerseNumber, verseNumber);
    await sharedPreferences.setString(keyUpdatedAt, updatedAt);
  }

  @override
  Future<Bookmark?> getLastRead() async {
    final surahId = sharedPreferences.getInt(keySurahId);
    final surahNameAr = sharedPreferences.getString(keySurahNameAr);
    final verseNumber = sharedPreferences.getInt(keyVerseNumber);
    final updatedAt = sharedPreferences.getString(keyUpdatedAt);

    if (surahId != null && surahNameAr != null && verseNumber != null) {
      return Bookmark(
        surahId: surahId,
        surahNameAr: surahNameAr,
        verseNumber: verseNumber,
        updatedAt: updatedAt ?? '',
      );
    }
    return null;
  }

  @override
  Future<void> saveMushafPage(int? pageNumber) async {
    if (pageNumber == null) {
      await sharedPreferences.remove(keyMushafPage);
      await sharedPreferences.remove(keyMushafUpdatedAt);
      return;
    }
    await sharedPreferences.setInt(keyMushafPage, pageNumber);
    await sharedPreferences.setString(
      keyMushafUpdatedAt,
      DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<MushafBookmark?> getMushafPage() async {
    final pageNumber = sharedPreferences.getInt(keyMushafPage);
    if (pageNumber == null) return null;
    return MushafBookmark(
      pageNumber: pageNumber,
      updatedAt: sharedPreferences.getString(keyMushafUpdatedAt) ?? '',
    );
  }
}
