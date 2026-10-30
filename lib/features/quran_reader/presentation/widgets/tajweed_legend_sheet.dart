import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'tajweed_text_span.dart';

/// Bottom sheet explaining what each Tajweed colour represents.
class TajweedLegendSheet extends StatelessWidget {
  const TajweedLegendSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const TajweedLegendSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'دليل ألوان التجويد',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: TajweedTextSpan.fontFamily,
                fontFamilyFallback: TajweedTextSpan.fontFamilyFallback,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryEmerald,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tajweed Color Guide',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            for (final entry in TajweedColors.legend)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: entry.color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.labelAr,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontFamily: TajweedTextSpan.fontFamily,
                              fontFamilyFallback:
                                  TajweedTextSpan.fontFamilyFallback,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            entry.labelEn,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
