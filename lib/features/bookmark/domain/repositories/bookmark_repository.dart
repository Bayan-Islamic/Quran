import '../entities/bookmark.dart';

abstract class BookmarkRepository {
  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  });

  Future<Bookmark?> getLastRead();
}
