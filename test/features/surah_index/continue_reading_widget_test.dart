import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/features/bookmarks/domain/entities/bookmark.dart';
import 'package:bayan_quran/features/bookmarks/domain/entities/mushaf_bookmark.dart';
import 'package:bayan_quran/features/bookmarks/presentation/widgets/continue_reading_banner.dart';

void main() {
  testWidgets(
      'ContinueReadingBanner displays bookmark info and responds to tap',
      (WidgetTester tester) async {
    bool tapped = false;
    const bookmark = Bookmark(
      surahId: 1,
      surahNameAr: 'الفاتحة',
      verseNumber: 5,
      updatedAt: '2026-10-22T00:00:00Z',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContinueReadingBanner(
            bookmark: bookmark,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.textContaining('سورة الفاتحة'), findsOneWidget);
    expect(find.text('متابعة'), findsOneWidget);

    await tester.tap(find.text('متابعة'));
    expect(tapped, isTrue);
  });

  testWidgets('ContinueReadingBanner shows a Mushaf page when only that exists',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ContinueReadingBanner(
            mushafBookmark: const MushafBookmark(
              pageNumber: 42,
              updatedAt: '2026-10-22T00:00:00Z',
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('صفحة ٤٢'), findsOneWidget);
    expect(find.textContaining('سورة'), findsNothing);
  });
}
