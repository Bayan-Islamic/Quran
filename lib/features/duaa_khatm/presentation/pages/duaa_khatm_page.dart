import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/duaa_khatm_content.dart';
import '../../domain/entities/duaa_section.dart';

/// The Du'aa Khatm al-Qur'an page, shown when the reader reaches the end of the
/// Mushaf. Entirely offline.
class DuaaKhatmPage extends StatelessWidget {
  const DuaaKhatmPage({super.key});

  /// Pushes the page, using [rootNavigator] so it covers the whole app when
  /// invoked from inside a nested navigator.
  static Future<void> show(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const DuaaKhatmPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دعاء ختم القرآن',
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryEmerald,
                  AppColors.primaryEmeraldDark,
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Column(
              children: [
                Icon(Icons.auto_awesome,
                    color: AppColors.accentGoldLight, size: 32),
                SizedBox(height: 8),
                Text(
                  'بلغتَ ختمَ القرآن الكريم',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'تقبّل الله منك، وجعل القرآن ربيع قلبك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ...DuaaKhatmContent.sections.map(
            (section) => _DuaaCard(section: section, isDark: isDark),
          ),
        ],
      ),
    );
  }
}

class _DuaaCard extends StatelessWidget {
  final DuaaSection section;
  final bool isDark;

  const _DuaaCard({required this.section, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark_border,
                  size: 18, color: AppColors.accentGold),
              const SizedBox(width: 6),
              Text(
                section.titleAr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryEmerald,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            section.textAr,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'UthmanicHafs',
              fontFamilyFallback: const ['Amiri', 'Arial', 'sans-serif'],
              fontSize: 19,
              height: 2.1,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          if ((section.sourceAr)?.isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              section.sourceAr!,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
