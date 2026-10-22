import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/ayah.dart';

class AyahItem extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;
  final bool isHighlighted;

  const AyahItem({
    super.key,
    required this.ayah,
    required this.fontSize,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final arabicVerseNum = ArabicNumberConverter.convert(ayah.verseNumber);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '${ayah.textUthmani} ',
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['Amiri', 'Arial', 'sans-serif'],
                    fontSize: fontSize,
                    height: 2.1,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                TextSpan(
                  text: '﴿$arabicVerseNum﴾',
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['Amiri', 'Arial', 'sans-serif'],
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
    );
  }
}
