import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/database/database_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/quran_reader/data/datasources/quran_reader_local_data_source.dart';
import 'features/quran_reader/data/repositories/quran_reader_repository_impl.dart';
import 'features/quran_reader/presentation/cubit/quran_reader_cubit.dart';
import 'features/surah_index/data/datasources/surah_local_data_source.dart';
import 'features/surah_index/data/repositories/surah_repository_impl.dart';
import 'features/surah_index/presentation/cubit/surah_index_cubit.dart';
import 'features/surah_index/presentation/pages/surah_index_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BayanQuranApp());
}

class BayanQuranApp extends StatefulWidget {
  const BayanQuranApp({super.key});

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

    return MultiBlocProvider(
      providers: [
        BlocProvider<SurahIndexCubit>(
          create: (context) => SurahIndexCubit(surahRepository: surahRepository),
        ),
        BlocProvider<QuranReaderCubit>(
          create: (context) => QuranReaderCubit(quranReaderRepository: quranReaderRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Bayan Quran',
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
