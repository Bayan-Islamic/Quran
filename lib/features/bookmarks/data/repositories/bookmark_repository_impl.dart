import '../../domain/entities/bookmark.dart';
import '../../domain/entities/mushaf_bookmark.dart';
import '../../domain/repositories/bookmark_repository.dart';
import '../datasources/bookmark_local_data_source.dart';

class BookmarkRepositoryImpl implements BookmarkRepository {
  final BookmarkLocalDataSource localDataSource;

  BookmarkRepositoryImpl({required this.localDataSource});

  @override
  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  }) async {
    await localDataSource.saveLastRead(
      surahId: surahId,
      surahNameAr: surahNameAr,
      verseNumber: verseNumber,
    );
  }

  @override
  Future<Bookmark?> getLastRead() async {
    return await localDataSource.getLastRead();
  }

  @override
  Future<void> saveMushafPage(int? pageNumber) async {
    await localDataSource.saveMushafPage(pageNumber);
  }

  @override
  Future<MushafBookmark?> getMushafPage() async {
    return await localDataSource.getMushafPage();
  }
}
