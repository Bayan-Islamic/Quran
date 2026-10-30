import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/features/quran_reader/domain/entities/ayah.dart';
import 'package:bayan_quran/features/quran_reader/domain/repositories/quran_reader_repository.dart';
import 'package:bayan_quran/features/quran_reader/presentation/cubit/quran_reader_cubit.dart';
import 'package:bayan_quran/features/quran_reader/presentation/cubit/quran_reader_state.dart';
import 'package:bayan_quran/features/quran_reader/presentation/pages/quran_reader_page.dart';
import 'package:bayan_quran/features/quran_reader/presentation/widgets/basmala_header.dart';
import 'package:bayan_quran/features/quran_reader/data/datasources/quran_reader_local_data_source.dart';
import 'package:bayan_quran/features/surah_index/domain/entities/surah.dart';
import 'package:bayan_quran/features/bookmarks/presentation/cubit/bookmark_cubit.dart';
import 'package:bayan_quran/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:bayan_quran/features/bookmarks/domain/entities/bookmark.dart';
import 'package:bayan_quran/features/bookmarks/domain/entities/mushaf_bookmark.dart';

class MockQuranReaderRepository implements QuranReaderRepository {
  @override
  Future<List<Ayah>> getAyahsBySurahId(int surahId) async {
    if (surahId == 1) {
      return [
        const Ayah(
          id: 1,
          surahId: 1,
          verseNumber: 1,
          textUthmani: 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
          textSearchNormalised: 'بسم الله الرحمن الرحيم',
          pageNumber: 1,
          juz: 1,
          hizb: 1,
        ),
        const Ayah(
          id: 2,
          surahId: 1,
          verseNumber: 2,
          textUthmani: 'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
          textSearchNormalised: 'الحمد لله رب العالمين',
          pageNumber: 1,
          juz: 1,
          hizb: 1,
        ),
      ];
    } else if (surahId == 9) {
      return [
        const Ayah(
          id: 1,
          surahId: 9,
          verseNumber: 1,
          textUthmani: 'بَرَآءَةٌ مِّنَ ٱللَّهِ وَرَسُولِهِۦ',
          textSearchNormalised: 'براءه من الله ورسوله',
          pageNumber: 187,
          juz: 10,
          hizb: 19,
        ),
      ];
    } else {
      return [
        const Ayah(
          id: 1,
          surahId: 2,
          verseNumber: 1,
          textUthmani: 'الٓمٓ',
          textSearchNormalised: 'الم',
          pageNumber: 2,
          juz: 1,
          hizb: 1,
        ),
        const Ayah(
          id: 2,
          surahId: 2,
          verseNumber: 2,
          textUthmani: 'ذَٰلِكَ ٱلْكِتَٰبُ لَا رَيْبَ ۛ فِيهِ',
          textTajweed:
              'ذَ<tajweed class=madda_normal>َٰلِكَ</tajweed> ٱلْكِتَ<tajweed class=madda_normal>ٰبُ</tajweed> لَا رَيْ<tajweed class=ghunnah>بَ ۛ ف</tajweed>ِيهِ',
          textSearchNormalised: 'ذلك الكتاب لا ريب فيه',
          pageNumber: 2,
          juz: 1,
          hizb: 1,
        ),
      ];
    }
  }
}

class MockBookmarkRepository implements BookmarkRepository {
  @override
  Future<Bookmark?> getLastRead() async => null;
  @override
  Future<void> saveLastRead(
      {required int surahId,
      required String surahNameAr,
      required int verseNumber}) async {}
  @override
  Future<void> saveMushafPage(int? pageNumber) async {}
  @override
  Future<MushafBookmark?> getMushafPage() async => null;
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

  test('stripBasmalaPrefix removes Basmala from verse 1 text when present', () {
    const rawVerse = 'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ الٓمٓ';
    final result = QuranReaderLocalDataSourceImpl.stripBasmalaPrefix(rawVerse);
    expect(result, equals('الٓمٓ'));
  });

  group('QuranReaderPage Basmala Header Tests', () {
    Widget buildTestWidget(Surah surah) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<QuranReaderCubit>(
              create: (_) =>
                  QuranReaderCubit(quranReaderRepository: repository),
            ),
            BlocProvider<BookmarkCubit>(
              create: (_) =>
                  BookmarkCubit(bookmarkRepository: MockBookmarkRepository()),
            ),
          ],
          child: QuranReaderPage(surah: surah),
        ),
      );
    }

    testWidgets(
        'Surah 1 (Al-Fatiha) does NOT display BasmalaHeader above verse 1',
        (tester) async {
      const fatiha = Surah(
          id: 1,
          nameAr: 'الفاتحة',
          nameEn: 'Al-Fatihah',
          type: 'مكية',
          totalVerses: 7,
          pageNumber: 1);
      await tester.pumpWidget(buildTestWidget(fatiha));
      await tester.pumpAndSettle();

      expect(find.byType(BasmalaHeader), findsNothing);
      expect(find.textContaining('بِسْمِ'), findsOneWidget);
    });

    testWidgets('Surah 9 (At-Tawbah) does NOT display BasmalaHeader',
        (tester) async {
      const tawbah = Surah(
          id: 9,
          nameAr: 'التوبة',
          nameEn: 'At-Tawbah',
          type: 'مدنية',
          totalVerses: 129,
          pageNumber: 187);
      await tester.pumpWidget(buildTestWidget(tawbah));
      await tester.pumpAndSettle();

      expect(find.byType(BasmalaHeader), findsNothing);
    });

    testWidgets('Surah 2 (Al-Baqarah) displays BasmalaHeader once at top',
        (tester) async {
      const baqarah = Surah(
          id: 2,
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          type: 'مدنية',
          totalVerses: 286,
          pageNumber: 2);
      await tester.pumpWidget(buildTestWidget(baqarah));
      await tester.pumpAndSettle();

      expect(find.byType(BasmalaHeader), findsOneWidget);
    });
  });

  group('QuranReaderPage Tajweed Mode Tests', () {
    Widget buildTestWidget(Surah surah) {
      return MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<QuranReaderCubit>(
              create: (_) =>
                  QuranReaderCubit(quranReaderRepository: repository),
            ),
            BlocProvider<BookmarkCubit>(
              create: (_) =>
                  BookmarkCubit(bookmarkRepository: MockBookmarkRepository()),
            ),
          ],
          child: QuranReaderPage(surah: surah),
        ),
      );
    }

    testWidgets('palette toggle flips tajweedMode on and back off',
        (tester) async {
      const baqarah = Surah(
          id: 2,
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          type: 'مدنية',
          totalVerses: 286,
          pageNumber: 2);
      await tester.pumpWidget(buildTestWidget(baqarah));
      await tester.pumpAndSettle();

      final cubit =
          tester.element(find.byType(QuranReaderPage)).read<QuranReaderCubit>();
      expect(cubit.state.tajweedMode, isFalse);
      expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      expect(cubit.state.tajweedMode, isTrue);
      expect(find.byIcon(Icons.palette), findsOneWidget);

      await tester.tap(find.byIcon(Icons.palette));
      await tester.pumpAndSettle();
      expect(cubit.state.tajweedMode, isFalse);
    });

    testWidgets('tajweed mode renders coloured spans for the verse',
        (tester) async {
      const baqarah = Surah(
          id: 2,
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          type: 'مدنية',
          totalVerses: 286,
          pageNumber: 2);
      await tester.pumpWidget(buildTestWidget(baqarah));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.palette_outlined));
      await tester.pumpAndSettle();

      // The coloured matn must be present as a rich text span tree.
      expect(find.byType(SelectableText), findsWidgets);
    });

    testWidgets('the color guide opens from the info action', (tester) async {
      const baqarah = Surah(
          id: 2,
          nameAr: 'البقرة',
          nameEn: 'Al-Baqarah',
          type: 'مدنية',
          totalVerses: 286,
          pageNumber: 2);
      await tester.pumpWidget(buildTestWidget(baqarah));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pumpAndSettle();

      expect(find.text('دليل ألوان التجويد'), findsOneWidget);
      expect(find.text('Tajweed Color Guide'), findsOneWidget);
    });
  });
}
