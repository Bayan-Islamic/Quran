import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/tafsir_repository.dart';
import 'tafsir_state.dart';

/// Loads the bundled Tafsir/translation for the ayah a sheet is showing.
class TafsirCubit extends Cubit<TafsirState> {
  final TafsirRepository tafsirRepository;

  TafsirCubit({required this.tafsirRepository}) : super(const TafsirInitial());

  Future<void> loadAyahContent(int ayahId) async {
    emit(const TafsirLoading());
    try {
      final content = await tafsirRepository.getAyahContent(ayahId);
      emit(TafsirLoaded(content));
    } catch (e) {
      emit(TafsirError('تعذّر تحميل التفسير: ${e.toString()}'));
    }
  }
}
