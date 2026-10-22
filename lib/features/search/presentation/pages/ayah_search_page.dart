import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../../quran_reader/presentation/pages/quran_reader_page.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../widgets/search_result_card.dart';

class AyahSearchPage extends StatefulWidget {
  const AyahSearchPage({super.key});

  @override
  State<AyahSearchPage> createState() => _AyahSearchPageState();
}

class _AyahSearchPageState extends State<AyahSearchPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'البحث في القرآن الكريم',
          style: TextStyle(
            fontFamily: 'UthmanicHafs',
            fontFamilyFallback: ['Amiri', 'Arial', 'sans-serif'],
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (query) {
                context.read<SearchCubit>().search(query);
              },
              decoration: InputDecoration(
                hintText: 'ابحث في آيات القرآن الكريم (مثال: الرحمن)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryEmerald),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<SearchCubit>().clearSearch();
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
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state is SearchLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primaryEmerald),
                  );
                } else if (state is SearchError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (state is SearchLoaded) {
                  final results = state.results;
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد آيات متطابقة مع كلمة البحث',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'عدد النتائج: ${ArabicNumberConverter.convert(results.length)} آية',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final item = results[index];
                            return SearchResultCard(
                              result: item,
                              searchQuery: state.query,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (routeContext) => QuranReaderPage(
                                      surah: item.surah,
                                      initialVerseNumber: item.ayah.verseNumber,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                }

                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.manage_search, size: 64, color: AppColors.primaryEmerald),
                      SizedBox(height: 12),
                      Text(
                        'اكتب كلمة أو عبارة للبحث في كامل القرآن',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
