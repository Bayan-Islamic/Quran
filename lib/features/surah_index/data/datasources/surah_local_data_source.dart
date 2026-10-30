import '../../../../core/database/database_helper.dart';
import '../models/surah_model.dart';

abstract class SurahLocalDataSource {
  Future<List<SurahModel>> getAllSurahs();
  Future<List<SurahModel>> searchSurahs(String query);
}

class SurahLocalDataSourceImpl implements SurahLocalDataSource {
  final DatabaseHelper databaseHelper;

  SurahLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<SurahModel>> getAllSurahs() async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'surahs',
      orderBy: 'id ASC',
    );
    return maps.map((map) => SurahModel.fromMap(map)).toList();
  }

  @override
  Future<List<SurahModel>> searchSurahs(String query) async {
    final db = await databaseHelper.database;
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getAllSurahs();
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'surahs',
      where: 'name_ar LIKE ? OR name_en LIKE ? OR id = ?',
      whereArgs: [
        '%$cleanQuery%',
        '%$cleanQuery%',
        int.tryParse(cleanQuery) ?? -1
      ],
      orderBy: 'id ASC',
    );
    return maps.map((map) => SurahModel.fromMap(map)).toList();
  }
}
