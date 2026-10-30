import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/quran_reader_preferences.dart';
import '../../domain/repositories/quran_reader_repository.dart';
import 'quran_reader_state.dart';

class QuranReaderCubit extends Cubit<QuranReaderState> {
  final QuranReaderRepository quranReaderRepository;
  final QuranReaderPreferences? preferences;

  QuranReaderCubit({
    required this.quranReaderRepository,
    this.preferences,
  }) : super(const QuranReaderInitial());

  /// Restores the persisted Tajweed preference, if one is configured.
  Future<void> loadPreferences() async {
    if (preferences == null) return;
    final enabled = await preferences!.getTajweedMode();
    if (state is QuranReaderLoaded) {
      emit((state as QuranReaderLoaded).copyWith(tajweedMode: enabled));
    } else {
      emit(QuranReaderInitial(fontSize: state.fontSize, tajweedMode: enabled));
    }
  }

  Future<void> loadSurahVerses(int surahId) async {
    emit(QuranReaderLoading(
      fontSize: state.fontSize,
      tajweedMode: state.tajweedMode,
    ));
    try {
      final ayahs = await quranReaderRepository.getAyahsBySurahId(surahId);
      emit(QuranReaderLoaded(
        ayahs: ayahs,
        fontSize: state.fontSize,
        tajweedMode: state.tajweedMode,
      ));
    } catch (e) {
      emit(QuranReaderError(
        'Failed to load verses: ${e.toString()}',
        fontSize: state.fontSize,
        tajweedMode: state.tajweedMode,
      ));
    }
  }

  void updateFontSize(double newSize) {
    if (state is QuranReaderLoaded) {
      emit((state as QuranReaderLoaded).copyWith(fontSize: newSize));
    } else {
      emit(QuranReaderInitial(
        fontSize: newSize,
        tajweedMode: state.tajweedMode,
      ));
    }
  }

  /// Flips the colour-coded Tajweed mode and persists the new value.
  void toggleTajweedMode() {
    final enabled = !state.tajweedMode;
    if (state is QuranReaderLoaded) {
      emit((state as QuranReaderLoaded).copyWith(tajweedMode: enabled));
    } else {
      emit(QuranReaderInitial(
        fontSize: state.fontSize,
        tajweedMode: enabled,
      ));
    }
    preferences?.setTajweedMode(enabled);
  }
}
