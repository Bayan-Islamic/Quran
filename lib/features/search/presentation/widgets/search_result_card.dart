import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_normalizer.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/search_result.dart';

class SearchResultCard extends StatelessWidget {
  final SearchResult result;
  final String searchQuery;
  final VoidCallback onTap;

  const SearchResultCard({
    super.key,
    required this.result,
    required this.searchQuery,
    required this.onTap,
  });

  /// Highlights every occurrence of [query] inside the diacritised [text].
  ///
  /// The match is located in the normalised form and then mapped back to the
  /// source offsets so the highlight covers the original, still-diacritised
  /// characters.
  List<InlineSpan> _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontFamilyFallback: const ['Amiri', 'Arial', 'sans-serif'],
      fontSize: 20,
      height: 2.1,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
    final highlightStyle = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontFamilyFallback: const ['Amiri', 'Arial', 'sans-serif'],
      fontSize: 20,
      height: 2.1,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryEmerald,
      backgroundColor: AppColors.accentGold.withValues(alpha: 0.35),
    );

    final normQuery = ArabicNormalizer.normalize(query);
    final displayText = ArabicNormalizer.sanitizeForDisplay(text);
    if (normQuery.isEmpty) {
      return [TextSpan(text: displayText, style: defaultStyle)];
    }

    final normalized = ArabicNormalizer.normalizeWithOffsets(displayText);
    final spans = <InlineSpan>[];
    int cursor = 0;

    for (int match = normalized.text.indexOf(normQuery);
        match != -1;
        match = normalized.text.indexOf(normQuery, match + normQuery.length)) {
      final start = normalized.offsets[match];
      int end = normalized.offsets[match + normQuery.length - 1] + 1;
      while (end < displayText.length && ArabicNormalizer.isDiacritic(displayText[end])) {
        end++;
      }
      if (start > cursor) {
        spans.add(TextSpan(text: displayText.substring(cursor, start), style: defaultStyle));
      }
      spans.add(TextSpan(text: displayText.substring(start, end), style: highlightStyle));
      cursor = end;
    }

    if (cursor < displayText.length) {
      spans.add(TextSpan(text: displayText.substring(cursor), style: defaultStyle));
    }
    return spans.isEmpty ? [TextSpan(text: displayText, style: defaultStyle)] : spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ayah = result.ayah;
    final surah = result.surah;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'سورة ${surah.nameAr}',
                          style: const TextStyle(
                            fontFamily: 'UthmanicHafs',
      fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryEmerald,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'آية ${ArabicNumberConverter.convert(ayah.verseNumber)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentGold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'الجزء ${ArabicNumberConverter.convert(ayah.juz)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              RichText(
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                text: TextSpan(
                  children: _buildHighlightedText(context, ayah.textUthmani, searchQuery),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
