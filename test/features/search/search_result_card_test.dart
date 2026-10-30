import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayan_quran/core/constants/app_colors.dart';
import 'package:bayan_quran/features/quran_reader/domain/entities/ayah.dart';
import 'package:bayan_quran/features/search/domain/entities/search_result.dart';
import 'package:bayan_quran/features/search/presentation/widgets/search_result_card.dart';
import 'package:bayan_quran/features/surah_index/domain/entities/surah.dart';

const _surah = Surah(
  id: 1,
  nameAr: 'الفاتحة',
  nameEn: 'Al-Fatihah',
  type: 'مكية',
  totalVerses: 7,
  pageNumber: 1,
);

SearchResult _result(String text, {int page = 1, int juz = 1}) => SearchResult(
      ayah: Ayah(
        id: 1,
        surahId: 1,
        verseNumber: 1,
        textUthmani: text,
        textSearchNormalised: text,
        pageNumber: page,
        juz: juz,
        hizb: 1,
      ),
      surah: _surah,
    );

List<TextSpan> _spansOf(WidgetTester tester) {
  final richText =
      tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
            (w) => w.text is TextSpan && (w.text as TextSpan).children != null,
          );
  return (richText.text as TextSpan).children!.cast<TextSpan>();
}

void main() {
  testWidgets('SearchResultCard highlights the matched substring only',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'),
            searchQuery: 'الرحمن',
            onTap: () {},
          ),
        ),
      ),
    );

    final spans = _spansOf(tester);
    final highlighted = spans
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text)
        .toList();
    expect(highlighted, hasLength(1));
    // The highlight keeps the original diacritised spelling.
    expect(highlighted.single, equals('ٱلرَّحْمَٰنِ'));
    expect(spans.map((s) => s.text).join(),
        equals('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'));
  });

  testWidgets('SearchResultCard highlights a mid-word match without diacritics',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result('ذَٰلِكَ ٱلْكِتَـٰبُ لَا رَيْبَ ۛ فِيهِ'),
            searchQuery: 'كت',
            onTap: () {},
          ),
        ),
      ),
    );

    final spans = _spansOf(tester);
    final highlighted = spans
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text)
        .toList();
    expect(highlighted, isNotEmpty);
    expect(
      highlighted.every((t) => t!.contains('ك') && t.contains('ت')),
      isTrue,
    );
  });

  testWidgets('SearchResultCard renders plain text when the query is empty',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result('الٓمٓ'),
            searchQuery: '   ',
            onTap: () {},
          ),
        ),
      ),
    );

    final spans = _spansOf(tester);
    expect(spans, hasLength(1));
    expect(spans.single.text, equals('الٓمٓ'));
    expect(spans.single.style?.backgroundColor, isNull);
  });

  testWidgets('SearchResultCard uses the emerald/gold palette', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result('بِسْمِ ٱللَّهِ'),
            searchQuery: 'الله',
            onTap: () {},
          ),
        ),
      ),
    );

    final highlighted =
        _spansOf(tester).firstWhere((s) => s.style?.backgroundColor != null);
    expect(highlighted.style?.color, equals(AppColors.primaryEmerald));
  });

  testWidgets('SearchResultCard highlights correctly after glyph sanitisation',
      (tester) async {
    // U+06DF (the oversized black-dot mark) sits just before the match; the
    // highlight offsets must stay aligned once it is mapped to U+06E0.
    const text = 'أُو\u06dfلَـٰٓئِكَ عَلَىٰ هُدًى';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result(text),
            searchQuery: 'هدى',
            onTap: () {},
          ),
        ),
      ),
    );

    final spans = _spansOf(tester);
    final highlighted = spans
        .where((s) => s.style?.backgroundColor != null)
        .map((s) => s.text)
        .toList();
    expect(highlighted, hasLength(1));
    // The slice is taken from the sanitised text, so it carries U+06E0, not U+06DF.
    expect(highlighted.single, contains('هُدًى'));
    final joined = spans.map((s) => s.text).join();
    expect(joined.contains('\u06df'), isFalse);
    expect(joined.contains('\u06e0'), isTrue);
  });

  testWidgets('SearchResultCard offers a Mushaf jump when a callback is given',
      (tester) async {
    int? openedPage;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result('بِسْمِ ٱللَّهِ', page: 42, juz: 3),
            searchQuery: '',
            onTap: () {},
            onOpenMushaf: () => openedPage = 42,
          ),
        ),
      ),
    );

    expect(find.textContaining('صفحة ٤٢'), findsOneWidget);
    expect(find.text('افتح في المصحف'), findsOneWidget);
    await tester.tap(find.text('افتح في المصحف'));
    expect(openedPage, 42);
  });

  testWidgets('SearchResultCard hides the Mushaf action without a callback',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchResultCard(
            result: _result('بِسْمِ ٱللَّهِ', page: 42),
            searchQuery: '',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('صفحة ٤٢'), findsNothing);
    expect(find.text('افتح في المصحف'), findsNothing);
  });
}
