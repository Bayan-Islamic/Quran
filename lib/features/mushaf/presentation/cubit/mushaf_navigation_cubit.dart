import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../surah_index/domain/repositories/surah_repository.dart';
import '../../data/datasources/mushaf_navigation_data_source.dart';
import 'mushaf_navigation_state.dart';

/// Supplies the surah and juz' jump lists shown in the Mushaf navigation sheet.
class MushafNavigationCubit extends Cubit<MushafNavigationState> {
  final SurahRepository surahRepository;
  final MushafNavigationDataSource navigationDataSource;

  MushafNavigationCubit({
    required this.surahRepository,
    required this.navigationDataSource,
  }) : super(const MushafNavigationInitial());

  Future<void> load() async {
    emit(const MushafNavigationLoading());
    try {
      final surahs = await surahRepository.getAllSurahs();
      final juzList = await navigationDataSource.getJuzList();
      emit(MushafNavigationLoaded(surahs: surahs, juzList: juzList));
    } catch (e) {
      emit(MushafNavigationError('تعذّر تحميل الفهرس: ${e.toString()}'));
    }
  }
}
