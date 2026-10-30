import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/ayah.dart';
import 'tajweed_text_span.dart';

class AyahItem extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final bool isHighlighted;

  /// When true, the verse is rendered with the colour-coded Tajweed palette
  /// (falling back to the plain Uthmani text when the edition is unavailable).
  final bool tajweedMode;

  /// Invoked when the verse is tapped, e.g. to open the Tafsir sheet.
  final VoidCallback? onTap;

  /// Invoked when the verse is long-pressed, e.g. to save it as the bookmark.
  final VoidCallback? onLongPress;

  /// Whether this verse carries the reader's bookmark ribbon.
  final bool isBookmarked;

  const AyahItem({
    super.key,
    required this.ayah,
    required this.fontSize,
    this.isHighlighted = false,
    this.tajweedMode = false,
    this.onTap,
    this.onLongPress,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final arabicVerseNum = ArabicNumberConverter.convert(ayah.verseNumber);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;

    final useTajweed = tajweedMode && ayah.textTajweed.isNotEmpty;
    final matnSpan = useTajweed
        ? TajweedTextSpan.build(
            ayah.textTajweed,
            fontSize: fontSize,
            defaultColor: textColor,
          )
        : TextSpan(
            text: '${ayah.textUthmani} ',
            style: TextStyle(
              fontFamily: TajweedTextSpan.fontFamily,
              fontFamilyFallback: TajweedTextSpan.fontFamilyFallback,
              fontSize: fontSize,
              height: TajweedTextSpan.lineHeight,
              color: textColor,
            ),
          );

    return Stack(
      children: [
        InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.accentGold.withValues(alpha: 0.2)
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted
                    ? AppColors.accentGold
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isHighlighted ? 1.5 : 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'آية ${ayah.verseNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryEmerald,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      'الجزء ${ArabicNumberConverter.convert(ayah.juz)} | صفحة ${ArabicNumberConverter.convert(ayah.pageNumber)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SelectableText.rich(
                  TextSpan(
                    children: [
                      matnSpan,
                      TextSpan(
                        text: ' ﴿$arabicVerseNum﴾',
                        style: TextStyle(
                          fontFamily: TajweedTextSpan.fontFamily,
                          fontFamilyFallback:
                              TajweedTextSpan.fontFamilyFallback,
                          fontSize: fontSize * 0.85,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
        ),
        if (isBookmarked)
          const Positioned(
            top: 0,
            left: 20,
            child: _BookmarkRibbon(),
          ),
      ],
    );
  }
}

/// The gold ribbon that marks the reader's current bookmark in the surah list.
class _BookmarkRibbon extends StatelessWidget {
  const _BookmarkRibbon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 30,
      decoration: const BoxDecoration(
        color: AppColors.accentGold,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
      ),
      child: const Icon(
        Icons.bookmark,
        size: 15,
        color: Colors.white,
      ),
    );
  }
}
