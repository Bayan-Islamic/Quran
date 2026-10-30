import '../../../../core/database/database_helper.dart';
import '../../domain/entities/juz_info.dart';

abstract class MushafNavigationDataSource {
  /// Start page of every juz', ordered by juz' number.
  Future<List<JuzInfo>> getJuzList();
}

class MushafNavigationDataSourceImpl implements MushafNavigationDataSource {
  final DatabaseHelper databaseHelper;

  MushafNavigationDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<JuzInfo>> getJuzList() async {
    final db = await databaseHelper.database;
    final maps = await db.rawQuery(
      'SELECT juz, MIN(page_number) AS start_page '
      'FROM ayahs GROUP BY juz ORDER BY juz ASC',
    );
    return maps
        .map((map) => JuzInfo(
              number: map['juz'] as int,
              startPage: map['start_page'] as int,
            ))
        .toList();
  }
}
