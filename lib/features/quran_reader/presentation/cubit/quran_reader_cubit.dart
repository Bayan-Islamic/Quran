import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/quran_reader_repository.dart';
import 'quran_reader_state.dart';

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final QuranReaderRepository quranReaderRepository;

  QuranReaderCubit({required this.quranReaderRepository})
      : super(const QuranReaderInitial());

  Future<void> loadSurahVerses(int surahId) async {
    emit(QuranReaderLoading(fontSize: state.fontSize));
    try {
      final ayahs = await quranReaderRepository.getAyahsBySurahId(surahId);
      emit(QuranReaderLoaded(ayahs: ayahs, fontSize: state.fontSize));
    } catch (e) {
      emit(QuranReaderError('Failed to load verses: ${e.toString()}',
          fontSize: state.fontSize));
    }
  }

  void updateFontSize(double newSize) {
    if (state is QuranReaderLoaded) {
      final loadedState = state as QuranReaderLoaded;
      emit(loadedState.copyWith(fontSize: newSize));
    } else {
      emit(QuranReaderInitial(fontSize: newSize));
    }
  }
}
