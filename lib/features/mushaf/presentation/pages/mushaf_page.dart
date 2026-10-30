import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../../bookmarks/presentation/cubit/bookmark_cubit.dart';
import '../../../bookmarks/presentation/cubit/bookmark_state.dart';
import '../../../duaa_khatm/presentation/pages/duaa_khatm_page.dart';
import '../../../surah_index/data/datasources/surah_local_data_source.dart';
import '../../../surah_index/data/repositories/surah_repository_impl.dart';
import '../../data/datasources/mushaf_navigation_data_source.dart';
import '../../domain/entities/mushaf_edition.dart';
import '../cubit/mushaf_cubit.dart';
import '../cubit/mushaf_navigation_cubit.dart';
import '../cubit/mushaf_state.dart';
import '../widgets/mushaf_navigation_sheet.dart';

/// Full-screen, page-by-page Mushaf reader backed by the bundled WebP pages.
///
/// The pages are swiped horizontally; both editions share the same page
/// numbering, so switching edition keeps the reader on the same Qur'an page.
/// Swiping past the last page opens the Du'aa Khatm al-Qur'an.
class MushafPage extends StatefulWidget {
  /// 1-based Qur'an page to open at (defaults to Al-Fatihah).
  final int initialPage;

  const MushafPage({super.key, this.initialPage = 1});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late final PageController _pageController;

  /// Whether the top/bottom chrome (edition switcher, counter, slider) is
  /// shown. Tapping the page toggles it so the Mushaf can be read full-bleed.
  bool _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    final page = widget.initialPage.clamp(1, MushafEdition.pageCount);
    _pageController = PageController(initialPage: page - 1);
    context.read<MushafCubit>().goToPage(page);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleControls() =>
      setState(() => _controlsVisible = !_controlsVisible);

  void _openNavigationSheet() {
    final cubit = MushafNavigationCubit(
      surahRepository: SurahRepositoryImpl(
        localDataSource: SurahLocalDataSourceImpl(
          databaseHelper: DatabaseHelper.instance,
        ),
      ),
      navigationDataSource: MushafNavigationDataSourceImpl(
        databaseHelper: DatabaseHelper.instance,
      ),
    );
    MushafNavigationSheet.show(
      context,
      cubit: cubit,
      onPageSelected: (page) {
        _pageController.jumpToPage(page - 1);
        context.read<MushafCubit>().goToPage(page);
      },
    ).whenComplete(cubit.close);
  }

  /// Handles the extra trailing page: swiping onto it opens the Du'aa Khatm.
  void _onPageChanged(int index) {
    if (index >= MushafEdition.pageCount) {
      _pageController.jumpToPage(MushafEdition.pageCount - 1);
      DuaaKhatmPage.show(context);
      return;
    }
    context.read<MushafCubit>().goToPage(index + 1);
  }

  void _toggleBookmark(int pageNumber) {
    final cubit = context.read<BookmarkCubit>();
    final state = cubit.state;
    final current =
        state is BookmarkLoaded ? state.mushafBookmark?.pageNumber : null;
    final isSame = current == pageNumber;
    cubit.saveMushafPage(isSame ? null : pageNumber);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSame
              ? 'تمت إزالة علامة الصفحة ${ArabicNumberConverter.convert(pageNumber)}'
              : 'تم حفظ علامة على الصفحة ${ArabicNumberConverter.convert(pageNumber)}',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryEmeraldDark,
      appBar: _controlsVisible ? _buildAppBar() : null,
      body: BlocConsumer<MushafCubit, MushafState>(
        listener: (context, state) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != state.pageNumber - 1) {
            _pageController.jumpToPage(state.pageNumber - 1);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControls,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: MushafEdition.pageCount + 1,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    if (index >= MushafEdition.pageCount) {
                      return const _KhatmPrompt();
                    }
                    return _MushafPageImage(
                      edition: state.edition,
                      pageNumber: index + 1,
                    );
                  },
                ),
              ),
              if (_controlsVisible)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MushafControlsBar(
                    pageNumber: state.pageNumber,
                    onPageChanged: (page) =>
                        context.read<MushafCubit>().goToPage(page),
                    onOpenNavigation: _openNavigationSheet,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: BlocBuilder<MushafCubit, MushafState>(
        builder: (context, state) => Text(
          'صفحة ${ArabicNumberConverter.convert(state.pageNumber)}'
          ' / ${ArabicNumberConverter.convert(MushafEdition.pageCount)}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      actions: [
        BlocBuilder<BookmarkCubit, BookmarkState>(
          builder: (context, bookmarkState) {
            final page = (bookmarkState is BookmarkLoaded)
                ? bookmarkState.mushafBookmark?.pageNumber
                : null;
            return BlocBuilder<MushafCubit, MushafState>(
              builder: (context, state) {
                final isBookmarked = page == state.pageNumber;
                return IconButton(
                  tooltip: 'علامة الصفحة',
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color:
                        isBookmarked ? AppColors.accentGoldLight : Colors.white,
                  ),
                  onPressed: () => _toggleBookmark(state.pageNumber),
                );
              },
            );
          },
        ),
        BlocBuilder<MushafCubit, MushafState>(
          builder: (context, state) {
            final isTajweed = state.edition == MushafEdition.tajweed;
            return TextButton.icon(
              onPressed: () => context.read<MushafCubit>().toggleEdition(),
              icon: Icon(
                isTajweed ? Icons.palette : Icons.palette_outlined,
                color: isTajweed ? AppColors.accentGoldLight : Colors.white,
              ),
              label: Text(
                isTajweed
                    ? MushafEdition.tajweed.labelAr
                    : MushafEdition.standard.labelAr,
                style: TextStyle(
                  color: isTajweed ? AppColors.accentGoldLight : Colors.white,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Bottom overlay: a page slider plus the Arabic page counter and a button that
/// opens the surah/juz' jump sheet.
class _MushafControlsBar extends StatelessWidget {
  final int pageNumber;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onOpenNavigation;

  const _MushafControlsBar({
    required this.pageNumber,
    required this.onPageChanged,
    required this.onOpenNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 4, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.primaryEmeraldDark.withValues(alpha: 0.92),
        border: const Border(
          top: BorderSide(color: AppColors.accentGold, width: 0.6),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'الفهرس',
              icon:
                  const Icon(Icons.list_alt, color: AppColors.accentGoldLight),
              onPressed: onOpenNavigation,
            ),
            Text(
              ArabicNumberConverter.convert(pageNumber),
              style: const TextStyle(
                color: AppColors.accentGoldLight,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accentGoldLight,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accentGoldLight,
                  overlayColor:
                      AppColors.accentGoldLight.withValues(alpha: 0.2),
                  trackHeight: 3,
                ),
                child: Slider(
                  min: 1,
                  max: MushafEdition.pageCount.toDouble(),
                  value: pageNumber.toDouble(),
                  label: ArabicNumberConverter.convert(pageNumber),
                  onChanged: (value) => onPageChanged(value.round()),
                ),
              ),
            ),
            Text(
              ArabicNumberConverter.convert(MushafEdition.pageCount),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _MushafPageImage extends StatelessWidget {
  final MushafEdition edition;
  final int pageNumber;

  const _MushafPageImage({required this.edition, required this.pageNumber});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 4.0,
      child: Center(
        child: Image.asset(
          edition.pageAssetPath(pageNumber),
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const _MissingPage(),
        ),
      ),
    );
  }
}

class _MissingPage extends StatelessWidget {
  const _MissingPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'صفحات المصحف غير مضمّنة.\n'
          'شغّل: python3 tools/process_mushaf_pdf.py',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}

/// The extra trailing page: a full-bleed card that invites the reader to the
/// Du'aa Khatm al-Qur'an once the last Mushaf page has been reached.
class _KhatmPrompt extends StatelessWidget {
  const _KhatmPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome,
                color: AppColors.accentGoldLight, size: 56),
            const SizedBox(height: 16),
            const Text(
              'بلغتَ ختمَ القرآن الكريم',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'UthmanicHafs',
                fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'اقرأ دعاء ختم القرآن',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => DuaaKhatmPage.show(context),
              icon: const Icon(Icons.menu_book),
              label: const Text('دعاء ختم القرآن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGoldLight,
                foregroundColor: AppColors.primaryEmeraldDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
