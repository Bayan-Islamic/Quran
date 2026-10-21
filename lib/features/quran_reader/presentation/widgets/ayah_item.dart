import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/ayah.dart';

class AyahItem extends StatelessWidget {
  final Ayah ayah;
  final double fontSize;

  const AyahItem({
    super.key,
    required this.ayah,
    required this.fontSize,
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
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
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
                    fontFamily: 'Amiri',
                    fontSize: fontSize,
                    height: 2.0,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accentGold,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      arabicVerseNum,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: fontSize * 0.55,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentGold,
                      ),
                    ),
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
