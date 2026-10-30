import 'package:flutter_test/flutter_test.dart';

import 'package:bayan_quran/features/duaa_khatm/data/duaa_khatm_content.dart';
import 'package:bayan_quran/features/duaa_khatm/domain/entities/duaa_section.dart';
import 'package:bayan_quran/features/mushaf/data/datasources/mushaf_navigation_data_source.dart';
import 'package:bayan_quran/features/mushaf/domain/entities/juz_info.dart';
import 'package:bayan_quran/features/mushaf/presentation/cubit/mushaf_navigation_cubit.dart';
import 'package:bayan_quran/features/mushaf/presentation/cubit/mushaf_navigation_state.dart';
import 'package:bayan_quran/features/surah_index/domain/entities/surah.dart';
import 'package:bayan_quran/features/surah_index/domain/repositories/surah_repository.dart';

class _FakeSurahRepository implements SurahRepository {
  final List<Surah> surahs;

  _FakeSurahRepository(this.surahs);

  @override
  Future<List<Surah>> getAllSurahs() async => surahs;

  @override
  Future<List<Surah>> searchSurahs(String query) async => surahs;
}

class _FakeNavigationDataSource implements MushafNavigationDataSource {
  final List<JuzInfo> juzList;

  _FakeNavigationDataSource(this.juzList);

  @override
  Future<List<JuzInfo>> getJuzList() async => juzList;
}

class _ThrowingSurahRepository implements SurahRepository {
  @override
  Future<List<Surah>> getAllSurahs() async => throw Exception('db down');

  @override
  Future<List<Surah>> searchSurahs(String query) async =>
      throw Exception('db down');
}

const _fatiha = Surah(
  id: 1,
  nameAr: 'الفاتحة',
  nameEn: 'Al-Fatihah',
  type: 'Meccan',
  totalVerses: 7,
  pageNumber: 1,
);

void main() {
  group('MushafNavigationCubit', () {
    test('loads surahs and juz list', () async {
      final cubit = MushafNavigationCubit(
        surahRepository: _FakeSurahRepository([_fatiha]),
        navigationDataSource: _FakeNavigationDataSource(
          const [JuzInfo(number: 1, startPage: 1)],
        ),
      );

      final states = <MushafNavigationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.load();

      expect(states.first, isA<MushafNavigationLoading>());
      final loaded = cubit.state as MushafNavigationLoaded;
      expect(loaded.surahs, [_fatiha]);
      expect(loaded.juzList.length, 1);
      expect(loaded.juzList.first.startPage, 1);

      await sub.cancel();
      await cubit.close();
    });

    test('emits an error state when the repository throws', () async {
      final cubit = MushafNavigationCubit(
        surahRepository: _ThrowingSurahRepository(),
        navigationDataSource: _FakeNavigationDataSource(const []),
      );

      await cubit.load();

      expect(cubit.state, isA<MushafNavigationError>());
      await cubit.close();
    });
  });

  group('DuaaKhatmContent', () {
    test('ships several non-empty Arabic sections', () {
      expect(DuaaKhatmContent.sections, isNotEmpty);
      for (final section in DuaaKhatmContent.sections) {
        expect(section, isA<DuaaSection>());
        expect(section.titleAr, isNotEmpty);
        expect(section.textAr, isNotEmpty);
      }
    });
  });
}
