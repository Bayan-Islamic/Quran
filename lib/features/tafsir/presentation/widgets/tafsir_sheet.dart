import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../../quran_reader/domain/entities/ayah.dart';
import '../../../surah_index/domain/entities/surah.dart';
import '../cubit/tafsir_cubit.dart';
import '../cubit/tafsir_state.dart';

/// Offline study sheet for a single ayah: the Arabic Tafsir Al-Muyassar and the
/// Saheeh International English translation, both read from the bundled
/// database with no network access.
class TafsirSheet extends StatefulWidget {
  final Ayah ayah;
  final Surah surah;

  const TafsirSheet({super.key, required this.ayah, required this.surah});

  /// Shows the sheet, providing a fresh [TafsirCubit] for its lifetime.
  static Future<void> show(
    BuildContext context, {
    required TafsirCubit cubit,
    required Ayah ayah,
    required Surah surah,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider<TafsirCubit>.value(
        value: cubit,
        child: TafsirSheet(ayah: ayah, surah: surah),
      ),
    );
  }

  @override
  State<TafsirSheet> createState() => _TafsirSheetState();
}

class _TafsirSheetState extends State<TafsirSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TafsirCubit>().loadAyahContent(widget.ayah.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ayah = widget.ayah;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryEmerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'سورة ${widget.surah.nameAr} · آية ${ArabicNumberConverter.convert(ayah.verseNumber)}',
                        style: const TextStyle(
                          fontFamily: 'UthmanicHafs',
                          fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryEmerald,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'إغلاق',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primaryEmeraldDark.withValues(alpha: 0.35)
                      : AppColors.primaryEmerald.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  ayah.textUthmani,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'UthmanicHafs',
                    fontFamilyFallback: const ['Amiri', 'Arial', 'sans-serif'],
                    fontSize: 22,
                    height: 2.1,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryEmerald,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: AppColors.accentGold,
                tabs: const [
                  Tab(text: 'التفسير الميسّر'),
                  Tab(text: 'English Translation'),
                ],
              ),
              Expanded(
                child: BlocBuilder<TafsirCubit, TafsirState>(
                  builder: (context, state) {
                    if (state is TafsirLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryEmerald,
                        ),
                      );
                    }
                    if (state is TafsirError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    final content =
                        state is TafsirLoaded ? state.content : null;
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _ContentPane(
                          scrollController: scrollController,
                          text: content?.hasTafsir == true
                              ? content!.tafsirMuyassar
                              : 'لا يتوفّر تفسير لهذه الآية في النسخة المضمّنة.',
                          isArabic: true,
                        ),
                        _ContentPane(
                          scrollController: scrollController,
                          text: content?.hasTranslation == true
                              ? content!.translationEn
                              : 'No translation is bundled for this ayah.',
                          isArabic: false,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContentPane extends StatelessWidget {
  final ScrollController scrollController;
  final String text;
  final bool isArabic;

  const _ContentPane({
    required this.scrollController,
    required this.text,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: SelectableText(
        text,
        textAlign: isArabic ? TextAlign.right : TextAlign.left,
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        style: TextStyle(
          fontFamily:
              isArabic ? 'UthmanicHafs' : theme.textTheme.bodyLarge?.fontFamily,
          fontFamilyFallback:
              isArabic ? const ['Amiri', 'Arial', 'sans-serif'] : null,
          fontSize: isArabic ? 19 : 16,
          height: isArabic ? 2.0 : 1.6,
          color:
              isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
        ),
      ),
    );
  }
}
