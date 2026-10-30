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

SearchResult _result(String text) => SearchResult(
      ayah: Ayah(
        id: 1,
        surahId: 1,
        verseNumber: 1,
        textUthmani: text,
        textSearchNormalised: text,
        pageNumber: 1,
        juz: 1,
        hizb: 1,
      ),
      surah: _surah,
    );

List<TextSpan> _spansOf(WidgetTester tester) {
  final richText = tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
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
    expect(spans.map((s) => s.text).join(), equals('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'));
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
}
