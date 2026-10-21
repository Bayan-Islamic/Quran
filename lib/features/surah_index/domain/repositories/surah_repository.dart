import '../entities/surah.dart';

abstract class SurahRepository {
  Future<List<Surah>> getAllSurahs();
  Future<List<Surah>> searchSurahs(String query);
}
