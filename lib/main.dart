import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/bookmarks/data/datasources/bookmark_local_data_source.dart';
import 'features/bookmarks/data/repositories/bookmark_repository_impl.dart';
import 'features/bookmarks/presentation/cubit/bookmark_cubit.dart';
import 'features/quran_reader/data/datasources/quran_reader_local_data_source.dart';
import 'features/quran_reader/data/repositories/quran_reader_repository_impl.dart';
import 'features/quran_reader/presentation/cubit/quran_reader_cubit.dart';
import 'features/search/data/datasources/search_local_data_source.dart';
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/presentation/cubit/search_cubit.dart';
import 'features/surah_index/data/datasources/surah_local_data_source.dart';
import 'features/surah_index/data/repositories/surah_repository_impl.dart';
import 'features/surah_index/presentation/cubit/surah_index_cubit.dart';
import 'features/surah_index/presentation/pages/surah_index_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(BayanQuranApp(sharedPreferences: prefs));
}

class BayanQuranApp extends StatefulWidget {
  final SharedPreferences? sharedPreferences;

  const BayanQuranApp({super.key, this.sharedPreferences});

  @override
  State<BayanQuranApp> createState() => _BayanQuranAppState();
}

class _BayanQuranAppState extends State<BayanQuranApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;

    final surahLocalDataSource = SurahLocalDataSourceImpl(databaseHelper: dbHelper);
    final surahRepository = SurahRepositoryImpl(localDataSource: surahLocalDataSource);

    final quranReaderLocalDataSource = QuranReaderLocalDataSourceImpl(databaseHelper: dbHelper);
    final quranReaderRepository = QuranReaderRepositoryImpl(localDataSource: quranReaderLocalDataSource);

    final searchLocalDataSource = SearchLocalDataSourceImpl(databaseHelper: dbHelper);
    final searchRepository = SearchRepositoryImpl(localDataSource: searchLocalDataSource);

    return MultiBlocProvider(
      providers: [
        BlocProvider<SurahIndexCubit>(
          create: (context) => SurahIndexCubit(surahRepository: surahRepository),
        ),
        BlocProvider<QuranReaderCubit>(
          create: (context) => QuranReaderCubit(quranReaderRepository: quranReaderRepository),
        ),
        BlocProvider<SearchCubit>(
          create: (context) => SearchCubit(searchRepository: searchRepository),
        ),
        if (widget.sharedPreferences != null)
          BlocProvider<BookmarkCubit>(
            create: (context) => BookmarkCubit(
              bookmarkRepository: BookmarkRepositoryImpl(
                localDataSource: BookmarkLocalDataSourceImpl(
                  sharedPreferences: widget.sharedPreferences!,
                ),
              ),
            )..loadLastRead(),
          ),
      ],
      child: MaterialApp(
        title: 'بيان القرآن',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _themeMode,
        locale: const Locale('ar'),
        supportedLocales: const [
          Locale('ar'),
          Locale('en'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: SurahIndexPage(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
      ),
    );
  }
}
