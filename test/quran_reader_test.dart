import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/features/quran_reader/domain/entities/ayah.dart';
import 'package:bayan_quran/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:bayan_quran/features/quran_reader/presentation/cubit/quran_reader_cubit.dart';
import 'package:bayan_quran/features/quran_reader/presentation/cubit/quran_reader_state.dart';

class MockQuranReaderRepository implements QuranReaderRepository {
  @override
  Future<List<Ayah>> getAyahsBySurahId(int surahId) async {
    return [
      const Ayah(id: 1, surahId: 1, verseNumber: 1, textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ', pageNumber: 1, juz: 1),
      const Ayah(id: 2, surahId: 1, verseNumber: 2, textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ', pageNumber: 1, juz: 1),
    ];
  }
}

void main() {
  late MockQuranReaderRepository repository;
  late QuranReaderCubit cubit;

  setUp(() {
    repository = MockQuranReaderRepository();
    cubit = QuranReaderCubit(quranReaderRepository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  test('Initial state is QuranReaderInitial with default fontSize 24.0', () {
    expect(cubit.state, equals(const QuranReaderInitial(fontSize: 24.0)));
  });

  test('loadSurahVerses loads ayahs correctly', () async {
    final ayahs = await repository.getAyahsBySurahId(1);
    final expectedStates = [
      const QuranReaderLoading(fontSize: 24.0),
      QuranReaderLoaded(ayahs: ayahs, fontSize: 24.0),
    ];

    expectLater(cubit.stream, emitsInOrder(expectedStates));
    await cubit.loadSurahVerses(1);
  });

  test('updateFontSize changes font size state', () async {
    await cubit.loadSurahVerses(1);
    cubit.updateFontSize(30.0);
    expect(cubit.state.fontSize, equals(30.0));
  });
}
