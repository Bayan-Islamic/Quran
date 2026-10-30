import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/arabic_number_converter.dart';
import '../../domain/entities/mushaf_edition.dart';
import '../cubit/mushaf_cubit.dart';
import '../cubit/mushaf_state.dart';

/// Full-screen, page-by-page Mushaf reader backed by the bundled WebP pages.
///
/// The pages are swiped horizontally; both editions share the same page
/// numbering, so switching edition keeps the reader on the same Qur'an page.
class MushafPage extends StatefulWidget {
  /// 1-based Qur'an page to open at (defaults to Al-Fatihah).
  final int initialPage;

  const MushafPage({super.key, this.initialPage = 1});

  @override
  State<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<MushafPage> {
  late final PageController _pageController;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryEmeraldDark,
      appBar: AppBar(
        title: BlocBuilder<MushafCubit, MushafState>(
          builder: (context, state) => Text(
            'صفحة ${ArabicNumberConverter.convert(state.pageNumber)}'
            ' / ${ArabicNumberConverter.convert(MushafEdition.pageCount)}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        actions: [
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
      ),
      body: BlocConsumer<MushafCubit, MushafState>(
        listener: (context, state) {
          if (_pageController.hasClients &&
              _pageController.page?.round() != state.pageNumber - 1) {
            _pageController.jumpToPage(state.pageNumber - 1);
          }
        },
        builder: (context, state) {
          return PageView.builder(
            controller: _pageController,
            itemCount: MushafEdition.pageCount,
            onPageChanged: (index) =>
                context.read<MushafCubit>().goToPage(index + 1),
            itemBuilder: (context, index) {
              return _MushafPageImage(
                edition: state.edition,
                pageNumber: index + 1,
              );
            },
          );
        },
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
