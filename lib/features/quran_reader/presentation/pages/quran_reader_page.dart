import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../bookmarks/presentation/cubit/bookmark_cubit.dart';
import '../../../surah_index/domain/entities/surah.dart';
import '../cubit/quran_reader_cubit.dart';
import '../cubit/quran_reader_state.dart';
import '../widgets/ayah_item.dart';
import '../widgets/basmala_header.dart';
import '../widgets/tajweed_legend_sheet.dart';

class QuranReaderPage extends StatefulWidget {
  final Surah surah;
  final int? initialVerseNumber;

  const QuranReaderPage({
    super.key,
    required this.surah,
    this.initialVerseNumber,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  late ScrollController _scrollController;
  bool _hasScrolledToInitialVerse = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<QuranReaderCubit>().loadSurahVerses(widget.surah.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _saveBookmark(int verseNumber) {
    context.read<BookmarkCubit>().saveLastRead(
          surahId: widget.surah.id,
          surahNameAr: widget.surah.nameAr,
          verseNumber: verseNumber,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الآية $verseNumber في القراءة الأخيرة'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToInitialVerse(int itemCount, bool showBasmala) {
    if (_hasScrolledToInitialVerse || widget.initialVerseNumber == null) return;
    _hasScrolledToInitialVerse = true;

    final targetVerse = widget.initialVerseNumber!;
    final targetIndex = (targetVerse - 1) + (showBasmala ? 1 : 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final offset = (targetIndex * 140.0).clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showFontSizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return BlocBuilder<QuranReaderCubit, QuranReaderState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'حجم الخط (Font Size)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('أ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Slider(
                          value: state.fontSize,
                          min: 16.0,
                          max: 42.0,
                          divisions: 13,
                          activeColor: AppColors.primaryEmerald,
                          label: state.fontSize.round().toString(),
                          onChanged: (value) {
                            BlocProvider.of<QuranReaderCubit>(context)
                                .updateFontSize(value);
                          },
                        ),
                      ),
                      const Text('أ', style: TextStyle(fontSize: 32)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showBasmala = widget.surah.id != 9 && widget.surah.id != 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.surah.nameAr,
              style: const TextStyle(
                fontFamily: 'UthmanicHafs',
                fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.surah.nameEn,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<QuranReaderCubit, QuranReaderState>(
            builder: (context, state) {
              final enabled = state.tajweedMode;
              return IconButton(
                icon: Icon(enabled
                    ? Icons.palette
                    : Icons.palette_outlined),
                color: enabled ? AppColors.accentGoldLight : null,
                tooltip: 'وضع التجويد الملون',
                onPressed: () =>
                    context.read<QuranReaderCubit>().toggleTajweedMode(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'دليل ألوان التجويد',
            onPressed: () => TajweedLegendSheet.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.format_size),
            tooltip: 'حجم الخط',
            onPressed: () => _showFontSizeDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<QuranReaderCubit, QuranReaderState>(
        builder: (context, state) {
          if (state is QuranReaderLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryEmerald),
            );
          } else if (state is QuranReaderError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<QuranReaderCubit>()
                          .loadSurahVerses(widget.surah.id);
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          } else if (state is QuranReaderLoaded) {
            final ayahs = state.ayahs;
            final totalItems = ayahs.length + (showBasmala ? 1 : 0);

            if (widget.initialVerseNumber != null) {
              _scrollToInitialVerse(totalItems, showBasmala);
            }

            return ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                if (showBasmala && index == 0) {
                  return const BasmalaHeader();
                }
                final ayahIndex = showBasmala ? index - 1 : index;
                final ayah = ayahs[ayahIndex];
                final isInitialVerse = widget.initialVerseNumber != null &&
                    ayah.verseNumber == widget.initialVerseNumber;

                return InkWell(
                  onLongPress: () => _saveBookmark(ayah.verseNumber),
                  child: AyahItem(
                    ayah: ayah,
                    fontSize: state.fontSize,
                    isHighlighted: isInitialVerse,
                    tajweedMode: state.tajweedMode,
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
