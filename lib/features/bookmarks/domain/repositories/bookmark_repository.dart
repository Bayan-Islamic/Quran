import '../entities/bookmark.dart';
import '../entities/mushaf_bookmark.dart';

abstract class BookmarkRepository {
  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  });

  Future<Bookmark?> getLastRead();

  /// Saves (or clears, when [pageNumber] is null) the Mushaf page bookmark.
  Future<void> saveMushafPage(int? pageNumber);

  Future<MushafBookmark?> getMushafPage();
}
