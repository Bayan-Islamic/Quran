import '../../domain/entities/ayah_content.dart';
import '../../domain/repositories/tafsir_repository.dart';
import '../datasources/tafsir_local_data_source.dart';

class TafsirRepositoryImpl implements TafsirRepository {
  final TafsirLocalDataSource localDataSource;

  TafsirRepositoryImpl({required this.localDataSource});

  @override
  Future<AyahContent?> getAyahContent(int ayahId) {
    return localDataSource.getAyahContent(ayahId);
  }
}
