import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/features/surah_index/domain/entities/surah.dart';
import 'package:bayan_quran/features/surah_index/domain/repositories/surah_repository.dart';
import 'package:bayan_quran/features/surah_index/presentation/cubit/surah_index_cubit.dart';
import 'package:bayan_quran/features/surah_index/presentation/cubit/surah_index_state.dart';

class MockSurahRepository implements SurahRepository {
  final List<Surah> _mockSurahs = [
    const Surah(id: 1, nameAr: 'الفاتحة', nameEn: 'Al-Fatihah', type: 'Meccan', totalVerses: 7, pageNumber: 1),
    const Surah(id: 2, nameAr: 'البقرة', nameEn: 'Al-Baqarah', type: 'Medinan', totalVerses: 286, pageNumber: 2),
  ];

  @override
  Future<List<Surah>> getAllSurahs() async => _mockSurahs;

  @override
  Future<List<Surah>> searchSurahs(String query) async {
    if (query.isEmpty) return _mockSurahs;
    return _mockSurahs
        .where((s) => s.nameAr.contains(query) || s.nameEn.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

void main() {
  group('Surah revelation type', () {
    test('isMeccan recognises the Arabic labels stored in the database', () {
      const fatiha = Surah(id: 1, nameAr: 'الفاتحة', nameEn: 'Al-Fatihah', type: 'مكية', totalVerses: 7, pageNumber: 1);
      const baqarah = Surah(id: 2, nameAr: 'البقرة', nameEn: 'Al-Baqarah', type: 'مدنية', totalVerses: 286, pageNumber: 2);
      expect(fatiha.isMeccan, isTrue);
      expect(baqarah.isMeccan, isFalse);
    });

    test('isMeccan still accepts the legacy English spellings', () {
      const meccan = Surah(id: 6, nameAr: 'الأنعام', nameEn: "Al-An'am", type: 'Meccan', totalVerses: 165, pageNumber: 128);
      const medinan = Surah(id: 2, nameAr: 'البقرة', nameEn: 'Al-Baqarah', type: 'Medinan', totalVerses: 286, pageNumber: 2);
      expect(meccan.isMeccan, isTrue);
      expect(medinan.isMeccan, isFalse);
    });
  });

  late MockSurahRepository repository;
  late SurahIndexCubit cubit;

  setUp(() {
    repository = MockSurahRepository();
    cubit = SurahIndexCubit(surahRepository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  test('Initial state is SurahIndexInitial', () {
    expect(cubit.state, equals(SurahIndexInitial()));
  });

  test('loadSurahs emits SurahIndexLoading then SurahIndexLoaded', () async {
    final expectedStates = [
      SurahIndexLoading(),
      SurahIndexLoaded(surahs: await repository.getAllSurahs()),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));
    await cubit.loadSurahs();
  });

  test('searchSurahs filters surahs by query', () async {
    final expectedStates = [
      const SurahIndexLoaded(
        surahs: [
          Surah(id: 1, nameAr: 'الفاتحة', nameEn: 'Al-Fatihah', type: 'Meccan', totalVerses: 7, pageNumber: 1)
        ],
        searchQuery: 'Fatihah',
      ),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));
    await cubit.searchSurahs('Fatihah');
  });
}
