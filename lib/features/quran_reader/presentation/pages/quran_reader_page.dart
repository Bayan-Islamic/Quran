import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../surah_index/domain/entities/surah.dart';
import '../cubit/quran_reader_cubit.dart';
import '../cubit/quran_reader_state.dart';
import '../widgets/ayah_item.dart';
import '../widgets/basmala_header.dart';

class QuranReaderPage extends StatefulWidget {
  final Surah surah;

  const QuranReaderPage({
    super.key,
    required this.surah,
  });

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  @override
  void initState() {
    super.initState();
    context.read<QuranReaderCubit>().loadSurahVerses(widget.surah.id);
  }

  void _showFontSizeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return BlocBuilder<QuranReaderCubit, QuranReaderState>(
          bloc: BlocProvider.of<QuranReaderCubit>(context),
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
    // Show Basmala header for all Surahs except Surah At-Tawbah (Surah ID 9)
    // and Surah Al-Fatihah (Surah ID 1, where Basmala is verse 1)
    final showBasmala = widget.surah.id != 9 && widget.surah.id != 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.surah.nameAr,
              style: const TextStyle(
                fontFamily: 'Amiri',
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
            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: ayahs.length + (showBasmala ? 1 : 0),
              itemBuilder: (context, index) {
                if (showBasmala && index == 0) {
                  return const BasmalaHeader();
                }
                final ayahIndex = showBasmala ? index - 1 : index;
                final ayah = ayahs[ayahIndex];
                return AyahItem(
                  ayah: ayah,
                  fontSize: state.fontSize,
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
