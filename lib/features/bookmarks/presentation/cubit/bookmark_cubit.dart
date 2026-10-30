import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/bookmark_repository.dart';
import 'bookmark_state.dart';

class BookmarkCubit extends Cubit<BookmarkState> {
  final BookmarkRepository bookmarkRepository;

  BookmarkCubit({required this.bookmarkRepository})
      : super(const BookmarkInitial());

  Future<void> loadLastRead() async {
    emit(const BookmarkLoading());
    try {
      final bookmark = await bookmarkRepository.getLastRead();
      final mushafBookmark = await bookmarkRepository.getMushafPage();
      emit(BookmarkLoaded(
        bookmark: bookmark,
        mushafBookmark: mushafBookmark,
      ));
    } catch (_) {
      emit(const BookmarkLoaded(bookmark: null));
    }
  }

  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  }) async {
    try {
      await bookmarkRepository.saveLastRead(
        surahId: surahId,
        surahNameAr: surahNameAr,
        verseNumber: verseNumber,
      );
      final bookmark = await bookmarkRepository.getLastRead();
      final mushafBookmark = await bookmarkRepository.getMushafPage();
      emit(BookmarkLoaded(
        bookmark: bookmark,
        mushafBookmark: mushafBookmark,
      ));
    } catch (_) {}
  }

  /// Saves (or clears, when [pageNumber] is null) the Mushaf page bookmark.
  Future<void> saveMushafPage(int? pageNumber) async {
    try {
      await bookmarkRepository.saveMushafPage(pageNumber);
      final bookmark = await bookmarkRepository.getLastRead();
      final mushafBookmark = await bookmarkRepository.getMushafPage();
      emit(BookmarkLoaded(
        bookmark: bookmark,
        mushafBookmark: mushafBookmark,
      ));
    } catch (_) {}
  }
}
