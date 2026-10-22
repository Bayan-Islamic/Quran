import '../../domain/entities/ayah.dart';
import '../../domain/repositories/quran_reader_repository.dart';
import '../datasources/quran_reader_local_data_source.dart';

class QuranReaderRepositoryImpl implements QuranReaderRepository {
  final QuranReaderLocalDataSource localDataSource;

  QuranReaderRepositoryImpl({required this.localDataSource});

  @override
  Future<List<Ayah>> getAyahsBySurahId(int surahId) async {
    return await localDataSource.getAyahsBySurahId(surahId);
  }
}
