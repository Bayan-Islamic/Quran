import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bayan_quran/features/bookmark/data/datasources/bookmark_local_data_source.dart';
import 'package:bayan_quran/features/bookmark/data/repositories/bookmark_repository_impl.dart';

void main() {
  group('BookmarkRepository', () {
    late BookmarkLocalDataSourceImpl dataSource;
    late BookmarkRepositoryImpl repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      dataSource = BookmarkLocalDataSourceImpl(sharedPreferences: prefs);
      repository = BookmarkRepositoryImpl(localDataSource: dataSource);
    });

    test('getLastRead returns null when no bookmark stored', () async {
      final bookmark = await repository.getLastRead();
      expect(bookmark, isNull);
    });

    test('saveLastRead persists bookmark and getLastRead retrieves it', () async {
      await repository.saveLastRead(
        surahId: 2,
        surahNameAr: 'البقرة',
        verseNumber: 255,
      );

      final bookmark = await repository.getLastRead();
      expect(bookmark, isNotNull);
      expect(bookmark!.surahId, equals(2));
      expect(bookmark.surahNameAr, equals('البقرة'));
      expect(bookmark.verseNumber, equals(255));
      expect(bookmark.updatedAt, isNotEmpty);
    });
  });
}
