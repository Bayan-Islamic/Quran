import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bayan_quran/features/bookmarks/domain/entities/bookmark.dart';
import 'package:bayan_quran/features/bookmarks/domain/entities/mushaf_bookmark.dart';
import 'package:bayan_quran/features/bookmarks/domain/repositories/bookmark_repository.dart';
import 'package:bayan_quran/features/bookmarks/presentation/cubit/bookmark_cubit.dart';
import 'package:bayan_quran/features/bookmarks/presentation/cubit/bookmark_state.dart';
import 'package:bayan_quran/features/mushaf/domain/entities/mushaf_edition.dart';
import 'package:bayan_quran/features/mushaf/presentation/cubit/mushaf_cubit.dart';
import 'package:bayan_quran/features/mushaf/presentation/pages/mushaf_page.dart';

/// In-memory [BookmarkRepository] so the Mushaf page can be built without a
/// real `shared_preferences` backend.
class _FakeBookmarkRepository implements BookmarkRepository {
  Bookmark? _bookmark;
  MushafBookmark? _mushafBookmark;

  @override
  Future<Bookmark?> getLastRead() async => _bookmark;

  @override
  Future<MushafBookmark?> getMushafPage() async => _mushafBookmark;

  @override
  Future<void> saveLastRead({
    required int surahId,
    required String surahNameAr,
    required int verseNumber,
  }) async {
    _bookmark = Bookmark(
      surahId: surahId,
      surahNameAr: surahNameAr,
      verseNumber: verseNumber,
      updatedAt: '2026-01-01T00:00:00.000Z',
    );
  }

  @override
  Future<void> saveMushafPage(int? pageNumber) async {
    _mushafBookmark = pageNumber == null
        ? null
        : MushafBookmark(
            pageNumber: pageNumber,
            updatedAt: '2026-01-01T00:00:00.000Z',
          );
  }
}

void main() {
  Widget buildTestWidget({int initialPage = 1}) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<MushafCubit>(create: (_) => MushafCubit()),
          BlocProvider<BookmarkCubit>(
            create: (_) =>
                BookmarkCubit(bookmarkRepository: _FakeBookmarkRepository())
                  ..loadLastRead(),
          ),
        ],
        child: MushafPage(initialPage: initialPage),
      ),
    );
  }

  testWidgets('opens at the requested page and shows the Arabic page counter',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 42));
    await tester.pump();

    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    expect(cubit.state.pageNumber, 42);
    // The counter appears both in the app bar ("صفحة ٤٢ / ٦٠٤") and in the
    // bottom control bar ("٤٢").
    expect(find.textContaining('٤٢'), findsWidgets);
    expect(find.textContaining('صفحة ٤٢'), findsOneWidget);
  });

  testWidgets('the bottom control bar exposes a page slider', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 1));
    await tester.pump();

    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.min, 1);
    expect(slider.max, MushafEdition.pageCount.toDouble());
    expect(slider.value, 1);

    // Dragging the slider moves the reader to a new page.
    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    await tester.drag(find.byType(Slider), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(cubit.state.pageNumber, greaterThan(1));
  });

  testWidgets('swiping forward advances the page', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 1));
    await tester.pump();

    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    expect(cubit.state.pageNumber, 1);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(cubit.state.pageNumber, 2);
  });

  testWidgets('the palette action toggles between the two editions',
      (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    final cubit = tester.element(find.byType(MushafPage)).read<MushafCubit>();
    expect(cubit.state.edition, MushafEdition.standard);
    expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    expect(cubit.state.edition, MushafEdition.tajweed);
    expect(find.byIcon(Icons.palette), findsOneWidget);
  });

  testWidgets('renders the image for the current edition and page',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 3));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      MushafEdition.standard.pageAssetPath(3),
    );
  });

  testWidgets('switching edition requests the other edition assets',
      (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 3));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image).first);
    expect(
      (image.image as AssetImage).assetName,
      MushafEdition.tajweed.pageAssetPath(3),
    );
  });

  testWidgets('the bookmark action toggles a page bookmark', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 7));
    await tester.pumpAndSettle();

    final cubit = tester.element(find.byType(MushafPage)).read<BookmarkCubit>();

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    expect((cubit.state as BookmarkLoaded).mushafBookmark?.pageNumber, 7);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);

    // Tapping again clears it.
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect((cubit.state as BookmarkLoaded).mushafBookmark, isNull);
  });

  testWidgets('tapping the page toggles the chrome', (tester) async {
    await tester.pumpWidget(buildTestWidget(initialPage: 1));
    await tester.pump();

    expect(find.byType(Slider), findsOneWidget);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.byType(PageView));
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
  });
}
