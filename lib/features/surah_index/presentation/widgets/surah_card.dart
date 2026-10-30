import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/surah.dart';

class SurahCard extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;
  final VoidCallback? onMushafTap;

  const SurahCard({
    super.key,
    required this.surah,
    required this.onTap,
    this.onMushafTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // The database stores the Arabic label directly ("مكية" / "مدنية").
    final isMeccan = surah.isMeccan;
    final typeTextAr = isMeccan ? 'مكية' : 'مدنية';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        trailing: onMushafTap == null
            ? null
            : IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                color: AppColors.primaryEmerald,
                tooltip: 'افتح في المصحف',
                onPressed: onMushafTap,
              ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryEmerald.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primaryEmerald.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              surah.id.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primaryEmerald,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              surah.nameEn,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Text(
              surah.nameAr,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.primaryEmerald,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${surah.totalVerses} Verses',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isMeccan
                          ? Colors.amber.withValues(alpha: 0.15)
                          : Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      typeTextAr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isMeccan ? AppColors.accentGold : AppColors.primaryEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'آياتها ${ArabicNumberConverter.convert(surah.totalVerses)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
