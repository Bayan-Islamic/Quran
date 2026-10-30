import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../bookmarks/presentation/cubit/bookmark_cubit.dart';
import '../../../bookmarks/presentation/cubit/bookmark_state.dart';
import '../../../bookmarks/presentation/widgets/continue_reading_banner.dart';
import '../../../quran_reader/presentation/pages/quran_reader_page.dart';
import '../../../search/presentation/pages/ayah_search_page.dart';
import '../../domain/entities/surah.dart';
import '../cubit/surah_index_cubit.dart';
import '../cubit/surah_index_state.dart';
import '../widgets/surah_card.dart';

class SurahIndexPage extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const SurahIndexPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<SurahIndexPage> createState() => _SurahIndexPageState();
}

class _SurahIndexPageState extends State<SurahIndexPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SurahIndexCubit>().loadSurahs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateToSurah(Surah surah, {int? initialVerseNumber}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => QuranReaderPage(
          surah: surah,
          initialVerseNumber: initialVerseNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'بيان القرآن (Bayan Quran)',
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.manage_search),
            tooltip: 'البحث في الآيات',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (routeContext) => const AyahSearchPage(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<SurahIndexCubit>().searchSurahs(query);
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن سورة (Search Surah by name/number)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryEmerald),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SurahIndexCubit>().loadSurahs();
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryEmerald),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryEmerald, width: 2),
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SurahIndexCubit, SurahIndexState>(
              builder: (context, indexState) {
                if (indexState is SurahIndexLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryEmerald),
                  );
                } else if (indexState is SurahIndexError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(indexState.message),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SurahIndexCubit>().loadSurahs();
                          },
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  );
                } else if (indexState is SurahIndexLoaded) {
                  final surahs = indexState.surahs;

                  return BlocBuilder<BookmarkCubit, BookmarkState>(
                    builder: (context, bookmarkState) {
                      final bookmark = (bookmarkState is BookmarkLoaded) ? bookmarkState.bookmark : null;
                      final showBanner = bookmark != null && _searchController.text.isEmpty;

                      if (surahs.isEmpty && !showBanner) {
                        return const Center(
                          child: Text('لا توجد نتائج متطابقة (No Surahs found)'),
                        );
                      }

                      return ListView.builder(
                        itemCount: surahs.length + (showBanner ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (showBanner && index == 0) {
                            return ContinueReadingBanner(
                              bookmark: bookmark,
                              onTap: () {
                                try {
                                  final targetSurah = surahs.firstWhere(
                                    (s) => s.id == bookmark.surahId,
                                  );
                                  _navigateToSurah(
                                    targetSurah,
                                    initialVerseNumber: bookmark.verseNumber,
                                  );
                                } catch (_) {}
                              },
                            );
                          }

                          final surahIndex = showBanner ? index - 1 : index;
                          final surah = surahs[surahIndex];
                          return SurahCard(
                            surah: surah,
                            onTap: () => _navigateToSurah(surah),
                          );
                        },
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
