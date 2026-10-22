import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class BasmalaHeader extends StatelessWidget {
  const BasmalaHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.primaryEmeraldDark.withValues(alpha: 0.4)
            : AppColors.primaryEmerald.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: const Center(
        child: Text(
          'بِسْمِ ٱللَّهِ ٱلرَّحْمَـٰنِ ٱلرَّحِيمِ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryEmerald,
            height: 2.1,
          ),
        ),
      ),
    );
  }
}
