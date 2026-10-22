import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/surah_repository.dart';
import 'surah_index_state.dart';

class SurahIndexCubit extends Cubit<SurahIndexState> {
  final SurahRepository surahRepository;

  SurahIndexCubit({required this.surahRepository}) : super(SurahIndexInitial());

  Future<void> loadSurahs() async {
    emit(SurahIndexLoading());
    try {
      final surahs = await surahRepository.getAllSurahs();
      emit(SurahIndexLoaded(surahs: surahs));
    } catch (e) {
      emit(SurahIndexError('Failed to load Surahs: ${e.toString()}'));
    }
  }

  Future<void> searchSurahs(String query) async {
    try {
      final surahs = await surahRepository.searchSurahs(query);
      emit(SurahIndexLoaded(surahs: surahs, searchQuery: query));
    } catch (e) {
      emit(SurahIndexError('Search failed: ${e.toString()}'));
    }
  }
}
