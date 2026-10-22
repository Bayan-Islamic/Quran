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

  List<InlineSpan> _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final defaultStyle = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: 20,
      height: 2.0,
      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
    );
    final highlightStyle = TextStyle(
      fontFamily: 'UthmanicHafs',
      fontSize: 20,
      height: 2.0,
      fontWeight: FontWeight.bold,
      color: AppColors.primaryEmerald,
      backgroundColor: AppColors.accentGold.withValues(alpha: 0.35),
    );

    final normQuery = ArabicNormalizer.normalize(query);
    if (normQuery.isEmpty) {
      return [TextSpan(text: text, style: defaultStyle)];
    }

    final words = text.split(' ');
    final spans = <InlineSpan>[];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final normWord = ArabicNormalizer.normalize(word);

      if (normWord.contains(normQuery)) {
        spans.add(TextSpan(text: word, style: highlightStyle));
      } else {
        spans.add(TextSpan(text: word, style: defaultStyle));
      }

      if (i < words.length - 1) {
        spans.add(TextSpan(text: ' ', style: defaultStyle));
      }
    }

    return spans;
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
