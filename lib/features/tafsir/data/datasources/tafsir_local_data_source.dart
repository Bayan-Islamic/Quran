import '../../../../core/database/database_helper.dart';
import '../../domain/entities/ayah_content.dart';
import '../models/ayah_content_model.dart';

abstract class TafsirLocalDataSource {
  Future<AyahContent?> getAyahContent(int ayahId);
}

class TafsirLocalDataSourceImpl implements TafsirLocalDataSource {
  final DatabaseHelper databaseHelper;

  TafsirLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<AyahContent?> getAyahContent(int ayahId) async {
    final db = await databaseHelper.database;
    final maps = await db.query(
      'ayah_content',
      where: 'ayah_id = ?',
      whereArgs: [ayahId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return AyahContentModel.fromMap(maps.first);
  }
}
