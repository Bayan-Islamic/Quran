import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../../surah_index/domain/entities/surah.dart';
import '../../domain/entities/juz_info.dart';
import '../cubit/mushaf_navigation_cubit.dart';
import '../cubit/mushaf_navigation_state.dart';

/// Bottom sheet that jumps the page-by-page Mushaf to a surah or a juz'.
class MushafNavigationSheet extends StatefulWidget {
  final ValueChanged<int> onPageSelected;

  const MushafNavigationSheet({super.key, required this.onPageSelected});

  /// Shows the sheet with a [MushafNavigationCubit] provided by the caller.
  static Future<void> show(
    BuildContext context, {
    required MushafNavigationCubit cubit,
    required ValueChanged<int> onPageSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => BlocProvider<MushafNavigationCubit>.value(
        value: cubit,
        child: MushafNavigationSheet(onPageSelected: onPageSelected),
      ),
    );
  }

  @override
  State<MushafNavigationSheet> createState() => _MushafNavigationSheetState();
}

class _MushafNavigationSheetState extends State<MushafNavigationSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<MushafNavigationCubit>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _select(int pageNumber) {
    widget.onPageSelected(pageNumber);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
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
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryEmerald,
                unselectedLabelColor: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                indicatorColor: AppColors.accentGold,
                tabs: const [
                  Tab(text: 'السور'),
                  Tab(text: 'الأجزاء'),
                ],
              ),
              Expanded(
                child:
                    BlocBuilder<MushafNavigationCubit, MushafNavigationState>(
                  builder: (context, state) {
                    if (state is MushafNavigationLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primaryEmerald,
                        ),
                      );
                    }
                    if (state is MushafNavigationError) {
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

                    final surahs = state is MushafNavigationLoaded
                        ? state.surahs
                        : const <Surah>[];
                    final juzList = state is MushafNavigationLoaded
                        ? state.juzList
                        : const <JuzInfo>[];

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _SurahList(
                          surahs: surahs,
                          scrollController: scrollController,
                          onSelect: (surah) => _select(surah.pageNumber),
                        ),
                        _JuzList(
                          juzList: juzList,
                          scrollController: scrollController,
                          onSelect: (juz) => _select(juz.startPage),
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

class _SurahList extends StatelessWidget {
  final List<Surah> surahs;
  final ScrollController scrollController;
  final ValueChanged<Surah> onSelect;

  const _SurahList({
    required this.surahs,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: surahs.length,
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.primaryEmerald.withValues(alpha: 0.12),
            child: Text(
              ArabicNumberConverter.convert(surah.id),
              style: const TextStyle(
                color: AppColors.primaryEmerald,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            surah.nameAr,
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            '${surah.nameEn} · صفحة ${ArabicNumberConverter.convert(surah.pageNumber)}',
          ),
          trailing: const Icon(Icons.chevron_left, size: 20),
          onTap: () => onSelect(surah),
        );
      },
    );
  }
}

class _JuzList extends StatelessWidget {
  final List<JuzInfo> juzList;
  final ScrollController scrollController;
  final ValueChanged<JuzInfo> onSelect;

  const _JuzList({
    required this.juzList,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: juzList.length,
      itemBuilder: (context, index) {
        final juz = juzList[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: AppColors.accentGold.withValues(alpha: 0.15),
            child: Text(
              ArabicNumberConverter.convert(juz.number),
              style: const TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            'الجزء ${ArabicNumberConverter.convert(juz.number)}',
            style: const TextStyle(
              fontFamily: 'UthmanicHafs',
              fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
              'يبدأ من صفحة ${ArabicNumberConverter.convert(juz.startPage)}'),
          trailing: const Icon(Icons.chevron_left, size: 20),
          onTap: () => onSelect(juz),
        );
      },
    );
  }
}
