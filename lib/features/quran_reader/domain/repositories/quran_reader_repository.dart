import '../entities/ayah.dart';

abstract class QuranReaderRepository {
  Future<List<Ayah>> getAyahsBySurahId(int surahId);
}
