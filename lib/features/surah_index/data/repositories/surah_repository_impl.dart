import '../../domain/entities/surah.dart';
import '../../domain/repositories/surah_repository.dart';
import '../datasources/surah_local_data_source.dart';

class SurahRepositoryImpl implements SurahRepository {
  final SurahLocalDataSource localDataSource;

  SurahRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Surah>> getAllSurahs() async {
    return await localDataSource.getAllSurahs();
  }

  @override
  Future<List<Surah>> searchSurahs(String query) async {
    return await localDataSource.searchSurahs(query);
  }
}
