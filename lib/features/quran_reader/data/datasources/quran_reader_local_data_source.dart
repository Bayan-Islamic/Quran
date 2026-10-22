import '../../../../core/database/database_helper.dart';
import '../models/ayah_model.dart';

abstract class QuranReaderLocalDataSource {
  Future<List<AyahModel>> getAyahsBySurahId(int surahId);
}

class QuranReaderLocalDataSourceImpl implements QuranReaderLocalDataSource {
  final DatabaseHelper databaseHelper;

  QuranReaderLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<AyahModel>> getAyahsBySurahId(int surahId) async {
    final db = await databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ayahs',
      where: 'surah_id = ?',
      whereArgs: [surahId],
      orderBy: 'verse_number ASC',
    );
    return maps.map((map) => AyahModel.fromMap(map)).toList();
  }
}
